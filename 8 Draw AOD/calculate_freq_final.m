function freq_result = calculate_freq_final(freq_block, cnt_block)

    if ndims(freq_block) ~= 3 || size(freq_block, 3) ~= 3
        error('calculate_freq_final:InvalidNumeratorSize', ...
            'freq_block must be nlat x nlon x 3; got %s.', mat2str(size(freq_block)));
    end
    if ndims(cnt_block) ~= 2 || size(cnt_block, 1) ~= size(freq_block, 1) || ...
            size(cnt_block, 2) ~= size(freq_block, 2)
        error('calculate_freq_final:SizeMismatch', ...
            'freq_block size=%s, cnt_block size=%s.', ...
            mat2str(size(freq_block)), mat2str(size(cnt_block)));
    end
    % 功能：计算最终的气溶胶频次（分子/分母）
    % 输入：
    %   freq_block - 累积的分子（探测到各类气溶胶的廓线数）
    %   cnt_block - 累积的分母（有效廓线数）
    % 输出：
    %   freq_result - 频次结果 (nlat x nlon x 3)
    
    nlat = size(freq_block, 1);
    nlon = size(freq_block, 2);
    freq_result = zeros(nlat, nlon, 3);
    fprintf('[freq_final] nlat=%d nlon=%d input=%s cnt=%s result=%s\n', ...
        nlat, nlon, mat2str(size(freq_block)), mat2str(size(cnt_block)), mat2str(size(freq_result)));
    
    for t = 1:3
        freq_result(:,:,t) = freq_block(:,:,t) ./ cnt_block;
        page = freq_result(:, :, t);
        page(cnt_block == 0) = NaN;
        freq_result(:, :, t) = page;
    end
end