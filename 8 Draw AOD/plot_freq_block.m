function plot_freq_block(freq_block, cnt_block, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, category)
    % 功能：绘制气溶胶频次分布图
    % 输入：
    %   freq_block - 频次累积 (nlat x nlon x 3) [Total, Anthropogenic, Natural]
    %   cnt_block - 总廓线数 (nlat x nlon)
    %   category - 'Total', 'Anthropogenic', 'Natural'

    % 计算频次（避免除零）
    freq = freq_block(:, :, 1);  % Total
    if strcmpi(category, 'Anthropogenic')
        freq = freq_block(:, :, 2);
        title_name = '中国境内 1°×1° 人为源气溶胶频次分布图';
    elseif strcmpi(category, 'Natural')
        freq = freq_block(:, :, 3);
        title_name = '中国境内 1°×1° 自然源气溶胶频次分布图';
    else
        title_name = '中国境内 1°×1° 气溶胶总频次分布图';
    end

    % 频次 = 某类气溶胶廓线数 / 有效廓线数
    freq_ratio = zeros(size(freq));
    valid = cnt_block > 0;
    freq_ratio(valid) = freq(valid) ./ cnt_block(valid);

    % 调用通用绘图函数
    plot_grid_block(freq_ratio, lon_centers, lat_centers, lon_edges, lat_edges, china_shp, ...
        title_name, 'Frequency', [0, 1]);
end
