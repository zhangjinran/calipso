function [aod_classified_block, cnt_classified_block] = calculate_classified_aod(...
    VFM, L2_APro, ALay_05km, surface_mask, ...
    aod_classified_block, cnt_classified_block, ...
    lon_edges, lat_edges)
    % 功能：计算分类气溶胶AOD
    % 输入：
    %   VFM - VFM数据结构
    %   L2_APro - APro数据结构
    %   ALay_05km - ALay数据结构（用于经纬度）
    %   surface_mask - 地表掩膜
    %   aod_classified_block - 分类AOD Block
    %   cnt_classified_block - 计数Block
    %   lon_edges, lat_edges - 经纬度边界
    %
    % 输出：
    %   aod_classified_block - 更新后的分类AOD
    %   cnt_classified_block - 更新后的计数

    %% 1. 初始化和获取数据
    lon = ALay_05km.Lon(:, 2);
    lat = ALay_05km.Lat(:, 2);

    vfm_altitudes = get_vfm_altitudes();
    n_vfm_alt = length(vfm_altitudes);

    apro_altitudes = L2_APro.Altitudes_Profile;
    extinction_data = L2_APro.Extinction_Coefficient_532;

    nlat = size(aod_classified_block, 1);
    nlon = size(aod_classified_block, 2);
    n_apro_alt = length(apro_altitudes);

    % 调试：写入前 N 条含type5廓线的逐层计算链到日志文件，用于验证公式正确性
    DBG_PRINT_PROFILES = 2;
    dbg_printed = 0;
    dbg_log_file = 'classified_aod_debug.log';
    dbg_fid = fopen(dbg_log_file, 'a');
    if dbg_fid > 0
        fprintf(dbg_fid, '\n========== %s ==========\n', datestr(now));
    end

    % 一次性积分验证标志（在函数级声明，不要放在循环内）
    persistent DBG_INTEG_VERIFIED

    %% 2. 定位网格
    lon_min = lon_edges(1);
    lat_min = lat_edges(1);
    ilon = floor(lon - lon_min) + 1;
    ilat = floor(lat - lat_min) + 1;

    valid_pos = ilon >= 1 & ilon <= nlon & ilat >= 1 & ilat <= nlat;

    %% 3. 计算层高
    dz = zeros(1, n_apro_alt);
    for k = 1:n_apro_alt-1
        dz(k) = apro_altitudes(k) - apro_altitudes(k+1);
    end
    dz(end) = dz(end-1);

    %% 4. 对每条廓线处理
    n_profiles = size(VFM.Feature_Classification_Flags, 1);

    for i = 1:n_profiles
        if ~valid_pos(i), continue; end
        if surface_mask(i) == 0, continue; end

        x = ilon(i);
        y = ilat(i);

        %% 步骤1：VFM处理 - 获取子类型
        vfm_row = VFM.Feature_Classification_Flags(i, :);
        [block, ~] = vfm_row2block(vfm_row, 'tropospheric aerosol');

        %% 步骤2：每个高度层找第一个有效类型
        type_for_height = zeros(n_vfm_alt, 1);
        for h = 1:n_vfm_alt
            valid_col = find(block(h, :) >= 1 & block(h, :) <= 7, 1, 'first');
            if ~isempty(valid_col)
                type_for_height(h) = block(h, valid_col);
            end
        end

        %% 步骤3：APro高度与VFM高度匹配
        apro_layer_type = zeros(1, n_apro_alt);
        for k = 1:n_apro_alt
            apro_alt = apro_altitudes(k);
            [~, idx] = min(abs(vfm_altitudes - apro_alt));
            apro_layer_type(k) = type_for_height(idx);
        end

            %% 步骤4：逐高度层分类积分（对type=5用退偏振比拆分Polluted Dust）
        % 读取后向散射数据用于退偏振比计算
        beta_total = L2_APro.Total_Backscatter_Coefficient_532;            % (n_profiles × n_alt)
        beta_perp  = L2_APro.Perpendicular_Backscatter_Coefficient_532;   % (n_profiles × n_alt)

        % 沙尘拆分常数 — Mamouri & Ansmann (2015, 2016); Kim et al. (2018)
        LR_DUST      = 44;    % 沙尘激光雷达比
        LR_POLLUTED  = 70;    % 污染大陆型（用于Polluted Dust中的非沙尘部分）
        DELTA1       = 0.31;  % 纯沙尘退偏振比
        DELTA2       = 0.05;  % 纯非沙尘退偏振比

        % 调试计数器
        n_type5 = 0;          % 该廓线中type=5的层数
        sum_dust_frac = 0;    % 各层的β沙尘分数之和（用于调试）

        extinction = extinction_data(i, :);
        aod_total = 0;
        aod_anthropogenic = 0;
        aod_natural = 0;

        for k = 1:n_apro_alt
            t = apro_layer_type(k);
            if t <= 0, continue; end
            if ~isfinite(extinction(k)) || extinction(k) <= 0, continue; end

            ext = extinction(k);
            aod_layer = ext * dz(k);
            aod_total = aod_total + aod_layer;

            switch t
                case {1, 2, 4, 7}  % 纯自然源
                    aod_natural = aod_natural + aod_layer;

                case {3, 6}        % 纯人为源
                    aod_anthropogenic = aod_anthropogenic + aod_layer;

                case 5             % Polluted Dust — 用退偏振比拆分沙尘/非沙尘
                    btotal = beta_total(i, k);
                    bperp  = beta_perp(i, k);
                    % Keep diagnostics defined for layers without valid beta_total.
                    depol = NaN;
                    dust_frac = NaN;

                    if ~isfinite(btotal) || btotal <= 0
                        % 无后向散射 → 等分
                        dust_aod  = aod_layer * 0.5;
                        nd_aod    = aod_layer - dust_aod;
                    else
                        depol = bperp / btotal;
                        depol = max(0, min(1, depol));

                        if depol >= DELTA1
                            dust_frac = 1;
                        elseif depol <= DELTA2
                            dust_frac = 0;
                        else
                            % Eq.(8): β_d / β_p
                            dust_frac = (depol - DELTA2) * (1 + DELTA1) / ...
                                        ((DELTA1 - DELTA2) * (1 + depol));
                        end

                        % 用后向散射 × LR 直接算消光（不用测量的 ext）
                        beta_dust     = btotal * dust_frac;
                        beta_nd       = btotal * (1 - dust_frac);
                        alpha_dust    = beta_dust * LR_DUST;
                        alpha_nd      = beta_nd * LR_POLLUTED;
                        dust_aod      = alpha_dust * dz(k);
                        nd_aod        = alpha_nd * dz(k);
                    end

                    % 更新 aod_layer（用拆分后的和替代原始测量值）
                    aod_layer = dust_aod + nd_aod;

                    aod_natural       = aod_natural + dust_aod;
                    aod_anthropogenic = aod_anthropogenic + nd_aod;

                    % 调试：写入前DBG_PRINT_PROFILES条廓线的逐层计算链到日志文件
                    if dbg_printed < DBG_PRINT_PROFILES && dbg_fid > 0

                        if isfinite(aod_layer) && aod_layer ~= 0
                            dust_aod_frac = dust_aod / aod_layer;
                        else
                            dust_aod_frac = NaN;
                        end
                        if n_type5 == 0
                            fprintf(dbg_fid, '  廓线%d — type=5 Polluted Dust 逐层拆分:\n', i);
                            fprintf(dbg_fid, '  %6s | %8s | %8s | %10s | %10s | %10s | %10s | %10s | %10s\n', ...
                                '层号k', 'ext', 'dz', 'depol', 'β_d/β_p', 'AOD_frac', ...
                                'AOD_layer', '→dust', '→nd');
                        end
                        if isnan(depol)
                            fprintf(dbg_fid, '  %6d | %8.5f | %8.5f |      NaN | %10.4f | %10.4f | %10.6f | %10.6f | %10.6f\n', ...
                                k, ext, dz(k), dust_frac, dust_aod_frac, ...
                                aod_layer, dust_aod, nd_aod);
                        else
                            fprintf(dbg_fid, '  %6d | %8.5f | %8.5f | %10.4f | %10.4f | %10.4f | %10.6f | %10.6f | %10.6f\n', ...
                                k, ext, dz(k), depol, dust_frac, dust_aod_frac, ...
                                aod_layer, dust_aod, nd_aod);
                        end
                    end

                    n_type5 = n_type5 + 1;
                otherwise
            end
        end

        % 一次性积分验证：首次探测到气溶胶的廓线，逐层打印 ext × dz
        if isempty(DBG_INTEG_VERIFIED) && aod_total > 0
            DBG_INTEG_VERIFIED = true;
            fprintf('\n========== 积分验证（首条含气溶胶廓线#%d）==========\n', i);
            fprintf('APro高度: 首=%.2f, 末=%.2f, 层数=%d\n', ...
                apro_altitudes(1), apro_altitudes(end), n_apro_alt);
            fprintf('VFM高度: 首=%.2f, 末=%.2f, 层数=%d\n', ...
                vfm_altitudes(1), vfm_altitudes(end), n_vfm_alt);
            fprintf('dz(前5):');
            for kk = 1:min(5, n_apro_alt)
                fprintf(' %.4f', dz(kk));
            end
            fprintf('\n');
            fprintf(' %6s | %8s | %8s | %10s | %10s\n', ...
                '层号k', 'ext', 'dz', 'ext×dz', '累积AOD');
            dbg_sum = 0;
            for kk = 1:n_apro_alt
                tt = apro_layer_type(kk);
                if tt <= 0 || ~isfinite(extinction(kk)) || extinction(kk) <= 0
                    continue;
                end
                aod_k = extinction(kk) * dz(kk);
                dbg_sum = dbg_sum + aod_k;
                fprintf(' %6d | %8.5f | %8.5f | %10.6f | %10.6f\n', ...
                    kk, extinction(kk), dz(kk), aod_k, dbg_sum);
            end
            fprintf('  => 该廓线积分总和=%.6f\n', dbg_sum);
            fprintf('===============================================\n\n');
        end

        % 调试：写完整条廓线的汇总到日志文件
        if n_type5 > 0 && dbg_printed < DBG_PRINT_PROFILES && dbg_fid > 0
            fprintf(dbg_fid, '  ── 该廓线合计: AOD_total=%.6f | natural(含dust)=%.6f | anthro(含nd)=%.6f\n\n', ...
                aod_total, aod_natural, aod_anthropogenic);
            dbg_printed = dbg_printed + 1;
        end

        if aod_total == 0
            continue;
        end

        %% 步骤5：在线更新均值
        % Total AOD
        old_mean = aod_classified_block(y, x, 1);
        old_cnt = cnt_classified_block(y, x, 1);
        aod_classified_block(y, x, 1) = (old_mean * old_cnt + aod_total) / (old_cnt + 1);
        cnt_classified_block(y, x, 1) = old_cnt + 1;

        % Anthropogenic AOD
        old_mean = aod_classified_block(y, x, 2);
        old_cnt = cnt_classified_block(y, x, 2);
        aod_classified_block(y, x, 2) = (old_mean * old_cnt + aod_anthropogenic) / (old_cnt + 1);
        cnt_classified_block(y, x, 2) = old_cnt + 1;

        % Natural AOD
        old_mean = aod_classified_block(y, x, 3);
        old_cnt = cnt_classified_block(y, x, 3);
        aod_classified_block(y, x, 3) = (old_mean * old_cnt + aod_natural) / (old_cnt + 1);
        cnt_classified_block(y, x, 3) = old_cnt + 1;
    end

    if dbg_fid > 0
        fclose(dbg_fid);
    end
end
