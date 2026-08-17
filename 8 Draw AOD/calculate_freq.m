function [freq_block, cnt_block, debug_info] = calculate_freq( ...
        VFM, ALay_05km, surface_mask, freq_block, cnt_block, ...
        lon_edges, lat_edges, debug_opts)
    % Accumulate aerosol occurrence counts on the longitude/latitude grid.
    % freq_block stores numerators; cnt_block stores valid-profile counts.
    % The final frequency is calculated by calculate_freq_final.

    if nargin < 8 || isempty(debug_opts)
        debug_opts = struct();
    end
    if ~isfield(debug_opts, 'enabled'), debug_opts.enabled = false; end
    if ~isfield(debug_opts, 'label'), debug_opts.label = ''; end
    if ~isfield(debug_opts, 'source'), debug_opts.source = ''; end
    debug_info = struct();

    %% Product alignment and grid validation
    lon = ALay_05km.Lon(:, 2);
    lat = ALay_05km.Lat(:, 2);
    surface_mask = surface_mask(:);
    vfm = VFM.Feature_Classification_Flags;

    n_alay = numel(lon);
    n_vfm = size(vfm, 1);
    n_mask = numel(surface_mask);

    if n_alay ~= n_vfm || n_alay ~= n_mask
        error(['calculate_freq:ProfileAlignmentMismatch: ALay=%d, ', ...
            'VFM=%d, surface_mask=%d. Source: %s'], ...
            n_alay, n_vfm, n_mask, char(debug_opts.source));
    end

    nlat = size(freq_block, 1);
    nlon = size(freq_block, 2);
    if ndims(freq_block) ~= 3 || size(freq_block, 3) ~= 3
        error('calculate_freq:InvalidNumeratorSize', ...
            'freq_block must be nlat x nlon x 3.');
    end
    if ~isequal(size(cnt_block), [nlat, nlon])
        error('calculate_freq:InvalidDenominatorSize', ...
            'cnt_block must match the first two dimensions of freq_block.');
    end

    % Existing state must already be counts. This catches accidentally passing
    % a frequency grid into a later accumulation call.
    tol = 1e-12;
    existing_bad = false(nlat, nlon);
    for t = 1:3
        existing_bad = existing_bad | ...
            (freq_block(:, :, t) > cnt_block + tol);
    end
    if any(existing_bad(:))
        error('calculate_freq:InvalidExistingCounts', ...
            'freq_block already contains a numerator greater than cnt_block.');
    end

    %% Map profiles to grid cells
    lon_min = lon_edges(1);
    lat_min = lat_edges(1);
    ilon = floor(lon - lon_min) + 1;
    ilat = floor(lat - lat_min) + 1;
    valid_pos = isfinite(lon) & isfinite(lat) & ...
        ilon >= 1 & ilon <= nlon & ilat >= 1 & ilat <= nlat;

    %% Decode VFM aerosol classes once per profile
    is_total = false(n_vfm, 1);
    is_anthropogenic = false(n_vfm, 1);
    is_natural = false(n_vfm, 1);
    unique_types_by_profile = cell(n_vfm, 1);

    for i = 1:n_vfm
        [vfm_block, ~] = vfm_row2block(vfm(i, :), 'tropospheric aerosol');
        unique_types = unique(vfm_block(vfm_block > 0));
        unique_types_by_profile{i} = unique_types(:).';

        is_total(i) = any(ismember(unique_types, 1:7));
        is_anthropogenic(i) = any(ismember(unique_types, [3, 5, 6]));
        is_natural(i) = any(ismember(unique_types, [1, 2, 4, 5, 7]));
    end

    %% Accumulate counts and retain this-call deltas for diagnosis
    delta_cnt = zeros(nlat, nlon);
    delta_num = zeros(nlat, nlon, 3);
    n_processed = 0;
    n_skipped_pos = 0;
    n_skipped_mask = 0;

    for i = 1:n_alay
        if ~valid_pos(i)
            n_skipped_pos = n_skipped_pos + 1;
            continue;
        end

        % Only an explicit finite nonzero mask value is valid.
        if ~isfinite(surface_mask(i)) || surface_mask(i) == 0
            n_skipped_mask = n_skipped_mask + 1;
            continue;
        end

        x = ilon(i);
        y = ilat(i);

        cnt_block(y, x) = cnt_block(y, x) + 1;
        delta_cnt(y, x) = delta_cnt(y, x) + 1;

        if is_total(i)
            freq_block(y, x, 1) = freq_block(y, x, 1) + 1;
            delta_num(y, x, 1) = delta_num(y, x, 1) + 1;
        end
        if is_anthropogenic(i)
            freq_block(y, x, 2) = freq_block(y, x, 2) + 1;
            delta_num(y, x, 2) = delta_num(y, x, 2) + 1;
        end
        if is_natural(i)
            freq_block(y, x, 3) = freq_block(y, x, 3) + 1;
            delta_num(y, x, 3) = delta_num(y, x, 3) + 1;
        end

        n_processed = n_processed + 1;
    end

    %% Verify the numerator <= denominator invariant
    delta_bad = false(nlat, nlon);
    cumulative_bad = false(nlat, nlon);
    total_bad = false(nlat, nlon);
    for t = 1:3
        delta_bad = delta_bad | (delta_num(:, :, t) > delta_cnt + tol);
        cumulative_bad = cumulative_bad | ...
            (freq_block(:, :, t) > cnt_block + tol);
    end
    total_bad = (delta_num(:, :, 1) > delta_cnt + tol) | ...
        (freq_block(:, :, 1) > cnt_block + tol);

    debug_info.label = debug_opts.label;
    debug_info.source = debug_opts.source;
    debug_info.n_alay = n_alay;
    debug_info.n_vfm = n_vfm;
    debug_info.n_mask = n_mask;
    debug_info.n_processed = n_processed;
    debug_info.n_skipped_pos = n_skipped_pos;
    debug_info.n_skipped_mask = n_skipped_mask;
    debug_info.delta_cnt = delta_cnt;
    debug_info.delta_num = delta_num;
    debug_info.delta_bad = delta_bad;
    debug_info.cumulative_bad = cumulative_bad;
    debug_info.total_bad = total_bad;

    if debug_opts.enabled
        context = debug_opts.label;
        if isempty(context), context = 'calculate_freq'; end

        fprintf('[freq:%s] ALay=%d, VFM=%d, mask=%d, processed=%d, ', ...
            context, n_alay, n_vfm, n_mask, n_processed);
        fprintf('skip_pos=%d, skip_mask=%d\n', ...
            n_skipped_pos, n_skipped_mask);
        fprintf('[freq:%s] delta total=%d, anthro=%d, natural=%d\n', ...
            context, sum(delta_num(:, :, 1), 'all'), ...
            sum(delta_num(:, :, 2), 'all'), ...
            sum(delta_num(:, :, 3), 'all'));

        if any(total_bad(:))
            fprintf(2, '[freq:%s] ERROR: TOTAL frequency exceeds 1.\n', context);
            [bad_y, bad_x] = find(total_bad, 1);
            fprintf(2, ['  [anomaly] grid=(%d,%d) Total: ', ...
                'total_num=%g, total_cnt=%g, delta_num=%g, delta_cnt=%g\n'], ...
                bad_y, bad_x, freq_block(bad_y, bad_x, 1), ...
                cnt_block(bad_y, bad_x), delta_num(bad_y, bad_x, 1), ...
                delta_cnt(bad_y, bad_x));

            printed = 0;
            for i = 1:n_alay
                if ~valid_pos(i) || ~isfinite(surface_mask(i)) || ...
                        surface_mask(i) == 0 || ilon(i) ~= bad_x || ilat(i) ~= bad_y
                    continue;
                end
                fprintf(2, ['    source=%s, profile=%d, lon=%.6f, ', ...
                    'lat=%.6f, types=%s\n'], ...
                    char(debug_opts.source), i, lon(i), lat(i), ...
                    mat2str(unique_types_by_profile{i}));
                printed = printed + 1;
                if printed >= 10, break; end
            end
        elseif any(delta_bad(:)) || any(cumulative_bad(:))
            fprintf(2, '[freq:%s] ERROR: a subtype numerator exceeds denominator.\n', context);
        else
            valid_cnt = cnt_block > 0;
            total_ratio = zeros(nlat, nlon);
            total_num = freq_block(:, :, 1);
            total_ratio(valid_cnt) = total_num(valid_cnt) ./ cnt_block(valid_cnt);
            if any(valid_cnt(:))
                max_total_ratio = max(total_ratio(valid_cnt));
            else
                max_total_ratio = 0;
            end
            fprintf('[freq:%s] max TOTAL cumulative frequency=%.12g\n', ...
                context, max_total_ratio);
        end
    end
end
