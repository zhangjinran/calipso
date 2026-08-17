function plot_aod_block(aod_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp)
    % 功能：绘制AOD分布图
    plot_grid_block(aod_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, ...
        '中国境内 1°×1° AOD 分布图', 'AOD (532 nm)', [0, 0.8]);
end
