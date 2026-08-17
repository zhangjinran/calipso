function plot_spatial_trend(data_3d, dates, lon_centers, lat_centers, ...
    lon_edges, lat_edges, china_shp, data_name)
    % 功能：分季节绘制空间趋势图（2×2子图）
    %
    % 方法（双模式）：
    %   ≥5年 → 按年求季度均值 + fitlm（有p值，叠显著性黑点）
    %   <5年 → 逐月值 + polyfit（无p值，小样本也能看到趋势方向）
    %   1. 按月拆分为 Q1(1-3月) Q2(4-6月) Q3(7-9月) Q4(10-12月)
    %   2. 每个格点回归 → slope
    %   3. p<0.05 的格点叠黑色显著性点（仅方法A）
    %
    % 输入：
    %   data_3d    - 3D数据 (lat x lon x time)
    %   dates      - 时间向量 (datetime)
    %   lon_centers, lat_centers - 网格中心
    %   lon_edges, lat_edges     - 网格边界
    %   china_shp  - 中国边界 shapefile
    %   data_name  - 数据名称（未使用，保留接口兼容）

    % ==================== 检查输入 ====================
    if ndims(data_3d) ~= 3
        error('data_3d 必须是3维数组 (lat x lon x time)');
    end
    [nlat, nlon, ntimes] = size(data_3d);
    if length(dates) ~= ntimes
        error('dates长度与data_3d时间维度不匹配');
    end

    % ==================== 中国区域 mask ====================
    [LON, LAT] = meshgrid(lon_centers, lat_centers);
    in_china = false(size(LON));
    for k = 1:length(china_shp)
        xv = china_shp(k).X;
        yv = china_shp(k).Y;
        valid_poly = ~(isnan(xv) | isnan(yv));
        xv = xv(valid_poly);
        yv = yv(valid_poly);
        if numel(xv) >= 3
            in_china = in_china | inpolygon(LON, LAT, xv, yv);
        end
    end

    % ==================== 月份 → 季度 ====================
    month_idx = month(dates);
    Q_RANGES = {1:3, 4:6, 7:9, 10:12};
    Q_NAMES  = {'Q1 (1-3月)', 'Q2 (4-6月)', 'Q3 (7-9月)', 'Q4 (10-12月)'};
    NQ = 4;
    MIN_YEARS_FOR_FITLM = 5;  % ≥5年用逐年平均+fitlm（有p值）
    MIN_PTS_POLYFIT = 3;      % <5年用逐月polyfit（无p值，但能看到趋势方向）

    % ==================== 第一遍：计算 slope + p ====================
    slope_maps = NaN(nlat, nlon, NQ);
    p_maps     = NaN(nlat, nlon, NQ);

    for s = 1:NQ
        idx_q = ismember(month_idx, Q_RANGES{s});
        if sum(idx_q) < 2
            continue;
        end
        season_data = data_3d(:, :, idx_q);
        season_years = year(dates(idx_q));
        unique_years = unique(season_years);
        ny = length(unique_years);

        % 逐月连续时间（用于小样本退路）
        season_months = month(dates(idx_q));
        t_continuous = season_years + (season_months - 1) / 12;

        for i = 1:nlat
            for j = 1:nlon
                if ny >= MIN_YEARS_FOR_FITLM
                    % ===== 方法A：按年求季度均值 + fitlm（含p值） =====
                    q_mean = NaN(ny, 1);
                    for y = 1:ny
                        yr_idx = (season_years == unique_years(y));
                        v = squeeze(season_data(i, j, yr_idx));
                        v = v(~isnan(v));
                        if ~isempty(v)
                            q_mean(y) = mean(v);
                        end
                    end
                    valid = ~isnan(q_mean);
                    if sum(valid) >= MIN_YEARS_FOR_FITLM
                        mdl = fitlm(unique_years(valid), q_mean(valid));
                        slope_maps(i, j, s) = mdl.Coefficients.Estimate(2);
                        p_maps(i, j, s)     = mdl.Coefficients.pValue(2);
                    end
                else
                    % ===== 方法B：逐月值 + polyfit（无p值，小样本保底） =====
                    vals = squeeze(season_data(i, j, :));
                    valid = isfinite(vals);
                    if sum(valid) >= MIN_PTS_POLYFIT
                        p = polyfit(t_continuous(valid), vals(valid), 1);
                        slope_maps(i, j, s) = p(1);
                        % p_maps 保持 NaN → 不会画显著性点
                    end
                end
            end
        end
    end

    % ==================== 全局色标范围 ====================
    max_abs = max(abs(slope_maps(:)));
    if isnan(max_abs) || max_abs == 0
        max_abs = 0.01;
    end
    clim_limits = [-max_abs, max_abs];

    % ==================== 第二遍：绘图 ====================
    figure('Position', [100 100 1200 900]);

    for s = 1:NQ
        subplot(2, 2, s);

        trend_s = slope_maps(:, :, s);
        trend_s(~in_china) = NaN;

        pcolor(lon_edges, lat_edges, padarray(trend_s, [1 1], NaN, 'post'));
        shading flat;
        hold on;

        % 中国国界
        for k = 1:length(china_shp)
            plot(china_shp(k).X, china_shp(k).Y, 'k-', 'LineWidth', 1.2);
        end

        % p<0.05 显著性点（scatter 避免 find 返回行列索引的错误）
        sig_mask = p_maps(:, :, s) < 0.05 & ~isnan(trend_s);
        if any(sig_mask(:))
            scatter(LON(sig_mask), LAT(sig_mask), 5, 'k', 'filled');
        end

        clim(clim_limits);
        xlim([70 136]);
        ylim([0 56]);
        title(Q_NAMES{s}, 'FontSize', 14, 'FontName', 'Microsoft YaHei');
        xlabel('经度 (°E)', 'FontSize', 11);
        ylabel('纬度 (°N)', 'FontSize', 11);
        set(gca, 'FontName', 'Microsoft YaHei');
        grid off;
        box on;
    end

    % 全局 colorbar（跨四个子图）
    colormap(flipud(jet));
    cb = colorbar('Position', [0.92 0.12 0.02 0.76]);
    cb.Label.String = '趋势斜率 (/year)';
    cb.Label.FontSize = 12;

    % 保存图片
    global SAVE_PATH
    if ~isempty(SAVE_PATH)
        fname = strrep(data_name, ' ', '_');
        save_figure_png(gcf, ['SpatialTrend_', fname, '.png']);
    end
end
