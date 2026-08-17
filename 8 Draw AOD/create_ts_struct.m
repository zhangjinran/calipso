function ts = create_ts_struct(lon_centers, lat_centers, lon_edges, lat_edges)
    % 功能：创建通用时间序列结构
    % 输入：经纬度网格信息
    % 输出：时间序列结构
    % 结构字段：
    %   dates - 时间戳向量 (datetime)
    %   data - 数据块 (lat x lon x time)
    %   lon_centers, lat_centers - 网格中心点
    %   lon_edges, lat_edges - 网格边界
    
    ts = struct();
    ts.dates = [];
    ts.data = [];
    ts.lon_centers = lon_centers;
    ts.lat_centers = lat_centers;
    ts.lon_edges = lon_edges;
    ts.lat_edges = lat_edges;
end