function ts_run_analysis(ts, china_shp, data_name, plot_spatial_enabled)
    if nargin < 4 || isempty(plot_spatial_enabled)
        plot_spatial_enabled = true;
    end

    fprintf('================== Trend analysis: %s ==================\n', data_name);

    if isempty(ts.data) || isempty(ts.dates)
        warning('Time-series data is empty; skip analysis.');
        return;
    end

    if ndims(ts.data) < 3
        ntimes = 1;
    else
        ntimes = size(ts.data, 3);
    end
    fprintf('Data size: lat=%d, lon=%d, time=%d\n', size(ts.data, 1), size(ts.data, 2), ntimes);

    if ntimes < 2
        warning('Not enough time points for trend analysis.');
        return;
    end

    fprintf('Drawing time-series trend plot...\n');
    plot_trend_line(ts.data, ts.dates, ts.lon_centers, ts.lat_centers, china_shp, ...
        [data_name, ' - China region mean time trend'], data_name);

    if plot_spatial_enabled
        fprintf('Drawing spatial trend plot...\n');
        plot_spatial_trend(ts.data, ts.dates, ts.lon_centers, ts.lat_centers, ...
            ts.lon_edges, ts.lat_edges, china_shp, [data_name, ' - Spatial trend plot']);
    else
        fprintf('Skipping spatial trend plot.\n');
    end

    fprintf('================== Trend analysis complete ==================\n');
end