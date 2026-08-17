% 简单测试脚本
clear; clc;

disp('测试开始...');

% 1. 测试网格创建
lon_range = [70, 140];
lat_range = [15, 55];
[aod_block, cnt_block, lon_centers, lat_centers, lon_edges, lat_edges] = create_empty_aod_grid(lon_range, lat_range);
disp(['网格创建成功: ', num2str(length(lat_centers)), ' x ', num2str(length(lon_centers))]);

% 2. 测试时间序列结构创建
ts = create_ts_struct(lon_centers, lat_centers, lon_edges, lat_edges);
disp('时间序列结构创建成功');

% 3. 测试数据追加
nlat = length(lat_centers);
nlon = length(lon_centers);
test_data = rand(nlat, nlon);
test_date = datetime(2020, 1, 1);
ts = ts_append_block(ts, test_date, test_data);
disp('数据追加成功');

% 4. 检查数据结构
disp(['时间点数量: ', num2str(length(ts.dates))]);
disp(['数据维度: ', num2str(size(ts.data))]);

disp('测试完成！');
