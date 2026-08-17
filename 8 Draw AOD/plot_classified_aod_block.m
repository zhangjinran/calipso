function plot_classified_aod_block(aod_classified_block, cnt_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, category)
    % 功能：绘制分类AOD分布图
    % 输入：
    %   aod_classified_block - 分类AOD累积 (nlat x nlon x 3) [Total, Anthropogenic, Natural]
    %   cnt_block - 总廓线数 (nlat x nlon)
    %   category - 'Total', 'Anthropogenic', 'Natural'

    if strcmpi(category, 'Anthropogenic')
        aod_data = aod_classified_block(:, :, 2);
        title_name = '中国境内 1°×1° 人为源AOD分布图';
        colorbar_label = 'Anthropogenic AOD';
    elseif strcmpi(category, 'Natural')
        aod_data = aod_classified_block(:, :, 3);
        title_name = '中国境内 1°×1° 自然源AOD分布图';
        colorbar_label = 'Natural AOD';
    else
        aod_data = aod_classified_block(:, :, 1);
        title_name = '中国境内 1°×1° AOD分布图';
        colorbar_label = 'AOD (532 nm)';
    end

    plot_grid_block(aod_data, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, ...
        title_name, colorbar_label, [0, 0.8]);
end
