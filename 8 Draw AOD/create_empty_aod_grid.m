function [aod_block, cnt_block, lon_centers, lat_centers, lon_edges, lat_edges] = create_empty_aod_grid(lon_range, lat_range)
    % 功能：创建 1°×1° 空白网格（仅初始化，不处理数据）
    lon_edges = lon_range(1):1:lon_range(2);
    lat_edges = lat_range(1):1:lat_range(2);

    lon_centers = lon_edges(1:end-1) + 0.5;
    lat_centers = lat_edges(1:end-1) + 0.5;

    nlat = length(lat_centers);
    nlon = length(lon_centers);

    aod_block = zeros(nlat, nlon);   % 累积 AOD 总和
    cnt_block = zeros(nlat, nlon);   % 累积点数
end
