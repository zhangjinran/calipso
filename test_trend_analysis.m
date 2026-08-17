% 测试趋势分析绘图函数
% 使用随机生成的数据测试时间序列结构和绘图函数

clear; clc;

% 1. 设置参数
lon_range = [70, 140];  % 中国经度范围
lat_range = [15, 55];   % 中国纬度范围
interval_type = 'month';

% 2. 创建网格
[aod_block, cnt_block, lon_centers, lat_centers, lon_edges, lat_edges] = create_empty_aod_grid(lon_range, lat_range);
[freq_block, freq_cnt_block, ~, ~, ~, ~] = create_empty_freq_grid(lon_range, lat_range);

nlat = length(lat_centers);
nlon = length(lon_centers);

% 3. 读取中国边界
china_shp = shaperead('E:/CALIPSO Code_new/中华人民共和国/中华人民共和国.shp');

% 4. 创建时间序列结构
ts_aod = create_ts_struct(lon_centers, lat_centers, lon_edges, lat_edges);
ts_freq_total = create_ts_struct(lon_centers, lat_centers, lon_edges, lat_edges);
ts_freq_anthro = create_ts_struct(lon_centers, lat_centers, lon_edges, lat_edges);
ts_freq_natural = create_ts_struct(lon_centers, lat_centers, lon_edges, lat_edges);

% 5. 生成随机测试数据（模拟2010-2020年共132个月）
start_date = datetime(2010, 1, 1);
n_months = 132;

for m = 1:n_months
    % 生成月度日期
    current_date = start_date + calmonths(m-1);
    
    % 生成随机AOD数据（模拟中国区域AOD分布）
    % 华北、华东地区AOD较高，青藏高原较低
    aod_data = 0.1 + 0.4 * exp(-((lon_centers - 115).^2)/200 - ((lat_centers' - 35).^2)/100);
    aod_data = aod_data + 0.2 * rand(nlat, nlon);  % 添加随机噪声
    
    % 添加时间趋势（整体下降趋势）
    trend_factor = 1 - (m-1)/(n_months*2);
    aod_data = aod_data * trend_factor;
    
    % 生成随机频率数据
    freq_total = 0.6 + 0.3 * rand(nlat, nlon);
    freq_anthro = 0.3 + 0.25 * rand(nlat, nlon);
    freq_natural = 0.4 + 0.2 * rand(nlat, nlon);
    
    % 将数据存入时间序列
    ts_aod = ts_append_block(ts_aod, current_date, aod_data);
    ts_freq_total = ts_append_block(ts_freq_total, current_date, freq_total);
    ts_freq_anthro = ts_append_block(ts_freq_anthro, current_date, freq_anthro);
    ts_freq_natural = ts_append_block(ts_freq_natural, current_date, freq_natural);
    
    fprintf('添加第 %d 个月数据: %s\n', m, datestr(current_date, 'yyyy-mm'));
end

% 6. 运行趋势分析并绘图
disp('开始绘制趋势图...');
ts_run_analysis(ts_aod, china_shp, 'AOD (Test Data)');
ts_run_analysis(ts_freq_total, china_shp, 'Total Aerosol Frequency (Test Data)');
ts_run_analysis(ts_freq_anthro, china_shp, 'Anthropogenic Aerosol Frequency (Test Data)');
ts_run_analysis(ts_freq_natural, china_shp, 'Natural Aerosol Frequency (Test Data)');

disp('测试完成！');
