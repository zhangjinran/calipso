% 测试绘图功能
clear; clc;

disp('测试绘图功能...');

% 1. 设置参数
lon_range = [70, 140];
lat_range = [15, 55];

% 2. 创建网格
[aod_block, cnt_block, lon_centers, lat_centers, lon_edges, lat_edges] = create_empty_aod_grid(lon_range, lat_range);
nlat = length(lat_centers);
nlon = length(lon_centers);

% 3. 创建时间序列结构
ts = create_ts_struct(lon_centers, lat_centers, lon_edges, lat_edges);

% 4. 生成随机测试数据（12个月）
start_date = datetime(2020, 1, 1);
for m = 1:12
    current_date = start_date + calmonths(m-1);
    
    % 生成模拟AOD数据（中国区域分布）
    aod_data = 0.1 + 0.4 * exp(-((lon_centers - 115).^2)/200 - ((lat_centers' - 35).^2)/100);
    aod_data = aod_data + 0.15 * rand(nlat, nlon);
    
    ts = ts_append_block(ts, current_date, aod_data);
    fprintf('添加第 %d 个月数据\n', m);
end

% 5. 测试时间趋势图
disp('测试时间趋势图...');
plot_trend_line(ts.data, ts.dates, lon_centers, lat_centers, [], 'AOD时间趋势（测试数据）', 'AOD值');

% 6. 测试空间分布图
disp('测试空间分布图...');
mean_data = mean(ts.data, 3);
plot_spatial_dist(mean_data, lon_centers, lat_centers, lon_edges, lat_edges, [], 'AOD平均分布（测试数据）', 'AOD值', [0, 0.8]);

% 7. 测试空间趋势图
disp('测试空间趋势图...');
plot_spatial_trend(ts.data, ts.dates, lon_centers, lat_centers, lon_edges, lat_edges, [], 'AOD空间趋势（测试数据）');

disp('绘图测试完成！');
