function [freq_block, cnt_block, lon_centers, lat_centers, lon_edges, lat_edges] = create_empty_freq_grid(lon_range, lat_range)
    % 功能：创建气溶胶子类型频次网格
    % 气溶胶子类型（从VFM提取）：
    %   1 - Clean Marine
    %   2 - Dust
    %   3 - Polluted Cont/Smoke
    %   4 - Clean Continental
    %   5 - Polluted Dust
    %   6 - Elevated Smoke
    %   7 - Dusty Marine

    lon_edges = lon_range(1):1:lon_range(2);
    lat_edges = lat_range(1):1:lat_range(2);

    lon_centers = lon_edges(1:end-1) + 0.5;
    lat_centers = lat_edges(1:end-1) + 0.5;

    nlat = length(lat_centers);
    nlon = length(lon_centers);

    n_subtype = 3;  % 3类：Total, Anthropogenic, Natural
    freq_block = zeros(nlat, nlon, n_subtype);  % 频次累积
    cnt_block = zeros(nlat, nlon);   % 总廓线数
end
