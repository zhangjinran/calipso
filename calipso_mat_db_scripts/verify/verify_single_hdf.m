function [pass, details] = verify_single_hdf(hdf_path, mat_data)
% VERIFY_SINGLE_HDF  对比 1 个 HDF 文件与 MAT struct 的字段一致性
%
% 输入:
%   hdf_path - 原始 HDF 文件路径
%   mat_data - day.files{i} 中的对应数据
%
% 输出:
%   pass    - true/false
%   details - struct 数组，每个字段的验证结果

    import matlab.io.hdf4.*

    pass = true;
    details = struct('field', {}, 'status', {}, 'max_diff', {});

    % 打开 HDF 读取原始 SDS
    sdID = sd.start(hdf_path, 'DFACC_RDONLY');
    [ndatasets, ~] = sd.fileInfo(sdID);

    for i = 0:ndatasets-1
        sdsID = sd.select(sdID, i);
        [sds_name, ~, ~, ~] = sd.getInfo(sdsID);
        varname = matlab.lang.makeValidName(sds_name);

        % 检查 MAT 中是否存在该字段
        if ~isfield(mat_data, varname)
            details(end+1) = struct('field', varname, ...
                'status', '跳过', 'max_diff', NaN);
            sd.endAccess(sdsID);
            continue;
        end

        try
            hdf_val = sd.readData(sdsID);
            mat_val = mat_data.(varname);

            % 尺寸检查
            if ~isequal(size(hdf_val), size(mat_val))
                % 可能是转置（readHDF 会对 2D 数据转置）
                if ndims(hdf_val) == 2 && ndims(mat_val) == 2 && ...
                   isequal(size(hdf_val'), size(mat_val))
                    hdf_val = hdf_val';
                else
                    details(end+1) = struct('field', varname, ...
                        'status', '尺寸不匹配', 'max_diff', NaN);
                    pass = false;
                    sd.endAccess(sdsID);
                    continue;
                end
            end

            % 数值比较
            if isnumeric(hdf_val) && isnumeric(mat_val)
                diff = max(abs(double(hdf_val(:)) - double(mat_val(:))));
                if diff < 1e-12
                    details(end+1) = struct('field', varname, ...
                        'status', '通过', 'max_diff', diff);
                else
                    details(end+1) = struct('field', varname, ...
                        'status', sprintf('精度 %.2e', diff), 'max_diff', diff);
                    pass = false;
                end
            else
                % 非数值字段（如字符串），仅检查 isequal
                if isequal(hdf_val, mat_val)
                    details(end+1) = struct('field', varname, ...
                        'status', '通过', 'max_diff', 0);
                else
                    details(end+1) = struct('field', varname, ...
                        'status', '不匹配', 'max_diff', NaN);
                    pass = false;
                end
            end

        catch ME
            details(end+1) = struct('field', varname, ...
                'status', ['错误: ', ME.message], 'max_diff', NaN);
        end
        sd.endAccess(sdsID);
    end
    sd.close(sdID);
end
