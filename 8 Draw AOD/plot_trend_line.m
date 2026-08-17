function plot_trend_line(data_3d, dates, lon_centers, lat_centers, china_shp, title_name, ylabel_name)
    if ndims(data_3d) ~= 3
        error('data_3d must be a 3D array (lat x lon x time).');
    end

    [~, ~, ntimes] = size(data_3d);
    if length(dates) ~= ntimes
        error('dates length must match the time dimension of data_3d.');
    end

    [LON, LAT] = meshgrid(lon_centers, lat_centers);
    in_china = false(size(LON));
    for k = 1:length(china_shp)
        xv = china_shp(k).X;
        yv = china_shp(k).Y;
        valid_poly = ~(isnan(xv) | isnan(yv));
        xv = xv(valid_poly);
        yv = yv(valid_poly);
        if numel(xv) >= 3
            in_china = in_china | inpolygon(LON, LAT, xv, yv);
        end
    end

    mean_vals = NaN(ntimes, 1);
    max_vals = NaN(ntimes, 1);
    over_one_counts = zeros(ntimes, 1);
    valid_counts = zeros(ntimes, 1);
    for t = 1:ntimes
        slice = data_3d(:, :, t);
        values = slice(in_china);
        values = values(~isnan(values));
        valid_counts(t) = numel(values);
        if ~isempty(values)
            mean_vals(t) = mean(values);
            max_vals(t) = max(values);
            over_one_counts(t) = sum(values > 1);
        end
    end

    if contains(ylabel_name, 'Frequency', 'IgnoreCase', true)
        fprintf('\n[trend:%s] China-mask time-point diagnostics\n', ylabel_name);
        fprintf('[trend:%s] date, mean, max, mean_gt_1, over_one_cells, valid_cells\n', ylabel_name);
        for t = 1:ntimes
            fprintf('[trend:%s] %s, %.12g, %.12g, %d, %d, %d\n', ...
                ylabel_name, datestr(dates(t), 'yyyy-mm-dd'), mean_vals(t), max_vals(t), ...
                mean_vals(t) > 1, over_one_counts(t), valid_counts(t));
        end
        if any(mean_vals > 1)
            first_bad = find(mean_vals > 1, 1, 'first');
            fprintf(2, '[trend:%s] WARNING: region mean frequency exceeds 1. First date=%s mean=%.12g max=%.12g\n', ...
                ylabel_name, datestr(dates(first_bad), 'yyyy-mm-dd'), mean_vals(first_bad), max_vals(first_bad));
        end
    end

    t_years = year(dates) + (month(dates) - 1) / 12;
    valid_idx = ~isnan(mean_vals);

    slope = NaN;
    if sum(valid_idx) >= 2
        p = polyfit(t_years(valid_idx), mean_vals(valid_idx), 1);
        slope = p(1);
    end

    window_size = 5;
    valid_y = mean_vals(valid_idx);
    smoothed = movmean(valid_y, window_size);

    figure('Position', [100 100 900 500]);
    plot(dates, mean_vals, 'bo', 'MarkerSize', 5, 'DisplayName', 'Region mean');
    hold on;

    if any(valid_idx)
        plot(dates(valid_idx), smoothed, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Moving average');
    end

    xlabel('Time', 'FontSize', 13, 'FontName', 'Microsoft YaHei');
    ylabel(ylabel_name, 'FontSize', 13, 'FontName', 'Microsoft YaHei');
    title(title_name, 'FontSize', 14, 'FontName', 'Microsoft YaHei');
    legend('Location', 'best', 'FontName', 'Microsoft YaHei');
    grid on; box on;

    if ~isnan(slope)
        annotation('textbox', [0.7, 0.8, 0.25, 0.15], ...
            'String', {['Trend slope: ', sprintf('%.4f', slope), ' /year']}, ...
            'FontSize', 11, 'FontName', 'Microsoft YaHei', 'EdgeColor', 'none');
    end

    global SAVE_PATH
    if ~isempty(SAVE_PATH)
        fname = strrep(ylabel_name, ' ', '_');
        save_figure_png(gcf, ['Trend_', fname, '.png']);
    end
end
