function data_out = filter_mat_like_getCALIPSO_L2(mat_data, lat_lim, profile_start_and_length)
% FILTER_MAT_LIKE_GETCALIPSO_L2 (v2, fixed 2026-07-28)
%   将 MAT 数据库数据转换为与 Fun_getCALIPSO_L2 输出一致的结构。
%
% 修复要点（对比 v1 旧版）:
%   1. convert_single_hdf 的 sd.getInfo 参数顺序错误导致转置从未生效，
%      MAT 存储为 HDF 原始方向 [特征 x 廓线]。本适配器先对所有 2D
%      数值字段转置（等价 readHDF 行为），统一为 [廓线 x 特征]。
%   2. ALay 分支：复刻 Fun_getCALIPSO_L2 的纬度搜索 + Fun_Change_num
%      裁剪；APro/VFM 分支：使用传入的 profile_start_and_length
%      （indA=psl(1)-1, indB=psl(2)），与主函数调用约定一致。
%   3. 转置后字段方向为 [廓线 x 特征]，裁剪段不再二次转置。

    if nargin < 3
        profile_start_and_length = [nan, nan];
    end
    if nargin < 2
        error('至少需要 mat_data 与 lat_lim 两个参数');
    end

    % === 1. 模拟 readHDF：所有 2D 数值字段转置为 [廓线 x 特征] ===
    m = struct();
    fn_all = fieldnames(mat_data);
    for fi = 1:numel(fn_all)
        fld = fn_all{fi};
        val = mat_data.(fld);
        if isnumeric(val) && ndims(val) == 2 && ~isscalar(val)
            m.(fld) = val';
        else
            m.(fld) = val;
        end
    end

    % === 2. 例外字段（不参与截取）===
    skip_fields = {
        'Properties'
        'Day_Night_Flag'
        'Lidar_Data_Altitudes'
        'lidar_Data_Altitude'
    };

    % === 3. 确定廓线范围（start_idx/end_idx, 1-based）===
    if any(isnan(profile_start_and_length))
        % ---- ALay 分支：纬度搜索 + Fun_Change_num 裁剪 ----
        if ~isfield(m, 'Latitude')
            error('MAT 数据中缺少 Latitude 字段');
        end
        lat_full = m.Latitude;               % [N x 3]
        if size(lat_full, 2) >= 3
            lat_center = lat_full(:, 1);     % 中心纬度
            lat_right  = lat_full(:, 3);     % 右边界
        else
            lat_center = lat_full(:, 1);
            lat_right  = lat_full(:, 1);
        end
        if lat_center(1) < lat_center(end)
            start_profile = find(round(lat_right, 4) > round(lat_lim(1), 4), 1, 'first');
            end_profile   = find(round(lat_center, 4) < round(lat_lim(2), 4), 1, 'last');
        else
            start_profile = find(round(lat_center, 4) < round(lat_lim(2), 4), 1, 'first');
            end_profile   = find(round(lat_right, 4) > round(lat_lim(1), 4), 1, 'last');
        end
        if isempty(start_profile) || isempty(end_profile)
            error('在纬度范围 [%.1f, %.1f] 内未找到数据', lat_lim(1), lat_lim(2));
        end
        indA = start_profile - 1;
        indB = end_profile - start_profile + 1;

        % Fun_Change_num 裁剪（复刻 Fun L49-66；先按纬度范围截取 HA/LTA）
        if isfield(m, 'Horizontal_Averaging') && isfield(m, 'Layer_Top_Altitude')
            ha  = m.Horizontal_Averaging;   % [N x 层]
            lta = m.Layer_Top_Altitude;     % [N x 层]
            % 与 Fun 一致：start=[indA 0], edges=[indB -9]，只取纬度范围内廓线
            if size(ha, 1) >= end_profile
                ha_sel = ha(start_profile:end_profile, :);
                lta_sel = lta(start_profile:end_profile, :);
            else
                ha_sel = ha; lta_sel = lta;
            end
            top_right_80km = nan(size(lta_sel));
            for i = 1:size(ha_sel, 1)
                for j = 1:size(ha_sel, 2)
                    if ha_sel(i, j) == 80
                        top_right_80km(i, j) = lta_sel(i, j);
                    end
                end
            end
            try
                change_num = Fun_Change_num(top_right_80km);
                indA = indA + change_num(1);
                indB = indB - change_num(1) - change_num(2);
            catch ME
                fprintf('  [调试] Fun_Change_num 调用失败: %s (跳过裁剪)\n', ME.message);
            end
        end
        start_idx = indA + 1;
        end_idx   = indA + indB;
    else
        % ---- APro/VFM 分支：使用传入的廓线范围（复刻 Fun else 分支）----
        indA = profile_start_and_length(1) - 1;
        indB = profile_start_and_length(2);
        start_idx = indA + 1;
        end_idx   = indA + indB;
    end

    % === 4. 截取所有字段（廓线维）===
    data_out = struct();
    n_profiles_total = size(m.Latitude, 1);
    for fi = 1:numel(fn_all)
        fld = fn_all{fi};
        val = m.(fld);
        if ~isnumeric(val)
            data_out.(fld) = val;
            continue;
        end
        if ismember(fld, skip_fields)
            data_out.(fld) = val;
            continue;
        end
        % ss 前缀字段：亚采样（每廓线 15 点），按 15 x 廓线范围截取
        if numel(fld) > 2 && strcmp(fld(1:2), 'ss')
            sz = size(val);
            n_ss = 15 * n_profiles_total;
            pdim = find(sz == n_ss, 1);
            if ~isempty(pdim)
                subs = repmat({':'}, 1, ndims(val));
                subs{pdim} = (start_idx-1)*15+1 : end_idx*15;
                data_out.(fld) = val(subs{:});
            else
                data_out.(fld) = val;
            end
            continue;
        end
        sz = size(val);
        pdim = find(sz == n_profiles_total, 1);
        if isempty(pdim)
            data_out.(fld) = val;
            continue;
        end
        subs = repmat({':'}, 1, ndims(val));
        subs{pdim} = start_idx:end_idx;
        data_out.(fld) = val(subs{:});
    end
    data_out.profile_start_end = [start_idx, end_idx];
    data_out.profile_number    = end_idx - start_idx + 1;

    % === 5. Day_Night_Flag（与旧版一致）===
    if isfield(mat_data, 'Profile_Time') && isvector(mat_data.Profile_Time)
        pt = mat_data.Profile_Time(:);
        end_pt = min(end_idx, length(pt));
        data_out.Day_Night_Flag = compute_daynight(pt(start_idx:end_pt));
    end

    % === 6. 字段名重命名（与旧版一致）===
    rename_map = {
        'Latitude',                     'Lat'
        'Longitude',                    'Lon'
        'Column_Optical_Depth_Aerosols_532',  'Column_AOD_532'
        'Column_Optical_Depth_Aerosols_1064', 'Column_AOD_1064'
        'Column_Optical_Depth_Stratospheric_532',  'Column_SOD_532'
        'Column_Optical_Depth_Stratospheric_1064', 'Column_SOD_1064'
        'Lidar_Data_Altitudes',         'lidar_Data_Altitude'
    };
    for ri = 1:size(rename_map, 1)
        old_n = rename_map{ri, 1};
        new_n = rename_map{ri, 2};
        if isfield(data_out, old_n)
            data_out.(new_n) = data_out.(old_n);
            data_out = rmfield(data_out, old_n);
        end
    end
    % lidar_Data_Altitude 强制列向量（Fun 用 hdfread 读 metadata 得 [n x 1]）
    if isfield(data_out, 'lidar_Data_Altitude') && isvector(data_out.lidar_Data_Altitude)
        data_out.lidar_Data_Altitude = data_out.lidar_Data_Altitude(:);
    end

    % === 8. 派生短名（Fun 将 HDF 长名重命名输出）===
    short_map = {
        'Column_Optical_Depth_Tropospheric_Aerosols_532',    'Column_TAOD_532'
        'Column_Optical_Depth_Tropospheric_Aerosols_1064',   'Column_TAOD_1064'
        'Column_Optical_Depth_Stratospheric_Aerosols_532',   'Column_SAOD_532'
        'Column_Optical_Depth_Stratospheric_Aerosols_1064',  'Column_SAOD_1064'
        'Column_Optical_Depth_Cloud_532',                    'Column_COD'
    };
    for ri = 1:size(short_map, 1)
        old_n = short_map{ri, 1};
        new_n = short_map{ri, 2};
        if isfield(data_out, old_n)
            data_out.(new_n) = data_out.(old_n);
        end
    end
    % APro 需要 Column_COD_532（Fun 分支特有命名）
    if isfield(data_out, 'Column_Optical_Depth_Cloud_532') && ~isfield(data_out, 'Column_COD_532')
        data_out.Column_COD_532 = data_out.Column_Optical_Depth_Cloud_532;
    end
    % fileName = 完整路径（与 Fun 一致；MAT 中只有 filename 基名）
    if isfield(data_out, 'filename') && ~isfield(data_out, 'fileName')
        data_out.fileName = data_out.filename;
    end
    % Altitudes_Profile：APro 高度轴（Fun 从 metadata 读；MAT 用 lidar_Data_Altitude 替代）
    % 注意 rename_map 已把 Lidar_Data_Altitudes -> lidar_Data_Altitude
    if ~isfield(data_out, 'Altitudes_Profile')
        if isfield(data_out, 'lidar_Data_Altitude')
            data_out.Altitudes_Profile = data_out.lidar_Data_Altitude(:);
        elseif isfield(data_out, 'Lidar_Data_Altitudes')
            data_out.Altitudes_Profile = data_out.Lidar_Data_Altitudes(:);
        end
    end
end

function flag = compute_daynight(profile_time)
    hours = mod(profile_time / 3600, 24);
    flag = zeros(size(hours));
    flag(hours >= 6 & hours < 18) = 1;
    flag(hours < 6 | hours >= 18) = 0;
    flag = flag';
end
