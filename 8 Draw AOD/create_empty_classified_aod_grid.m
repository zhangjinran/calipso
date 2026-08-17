function [aod_classified_block, cnt_classified_block, lon_centers, lat_centers, lon_edges, lat_edges] = create_empty_classified_aod_grid(lon_range, lat_range)
    % 功能：创建分类AOD网格
    % 与create_empty_freq_grid相同结构

    lon_edges = lon_range(1):1:lon_range(2);
    lat_edges = lat_range(1):1:lat_range(2);

    lon_centers = lon_edges(1:end-1) + 0.5;
    lat_centers = lat_edges(1:end-1) + 0.5;

    nlat = length(lat_centers);
    nlon = length(lon_centers);
    nclass = 3;  % Total, Anthropogenic, Natural

    aod_classified_block = zeros(nlat, nlon, nclass);   % 分类AOD累积
    cnt_classified_block = zeros(nlat, nlon, nclass);   % 分类计数（每个类别单独计数）
end
