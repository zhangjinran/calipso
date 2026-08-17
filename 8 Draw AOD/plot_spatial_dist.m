function plot_spatial_dist(data_3d, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, title_name, colorbar_label, clim_limits)
    % 功能：绘制空间分布图（时间平均）
    % 输入：
    %   data_3d - 3D数据数组 (lat x lon x time)
    %   lon_centers - 经度中心点向量
    %   lat_centers - 纬度中心点向量
    %   lon_edges - 经度边界向量
    %   lat_edges - 纬度边界向量
    %   china_shp - 中国边界shapefile
    %   title_name - 图标题
    %   colorbar_label - 颜色条标签
    %   clim_limits - 颜色范围 [min, max]
    
    % 检查输入维度
    if ndims(data_3d) ~= 3
        error('data_3d 必须是3维数组 (lat x lon x time)');
    end
    
    % 对时间求平均
    [nlat, nlon, ntimes] = size(data_3d);
    mean_data = zeros(nlat, nlon);
    for i = 1:nlat
        for j = 1:nlon
            values = data_3d(i, j, :);
            values = values(~isnan(values));
            if ~isempty(values)
                mean_data(i, j) = mean(values);
            else
                mean_data(i, j) = NaN;
            end
        end
    end
    
    % 获取中国区域mask
    [LON, LAT] = meshgrid(lon_centers, lat_centers);
    in_china = false(size(LON));
    for k = 1:length(china_shp)
        xv = china_shp(k).X;
        yv = china_shp(k).Y;
        valid_poly = ~(isnan(xv) | isnan(yv));
        xv = xv(valid_poly);
        yv = yv(valid_poly);
        if numel(xv) >= 3
            in = inpolygon(LON, LAT, xv, yv);
            in_china = in_china | in;
        end
    end
    
    % Mask境外区域
    plot_data = mean_data;
    plot_data(~in_china) = NaN;
    
    % 绘图
    figure('Position', [100 100 900 700]);
    
    pcolor(lon_edges, lat_edges, padarray(plot_data, [1 1], NaN, 'post'));
    shading flat;
    hold on;
    
    % 绘制中国边界
    for k = 1:length(china_shp)
        plot(china_shp(k).X, china_shp(k).Y, 'k-', 'LineWidth', 1.2);
    end
    
    colormap(parula);
    
    c = colorbar;
    c.Label.String = colorbar_label;
    c.Label.FontSize = 12;
    
    clim(clim_limits);
    
    xlim([70 136]);
    ylim([0 56]);
    
    xlabel('经度 (°E)', 'FontSize', 13);
    ylabel('纬度 (°N)', 'FontSize', 13);
    
    title(title_name, 'FontSize', 14);
    
    set(gca, 'FontName', 'Microsoft YaHei');
    
    grid off;
    box on;
end