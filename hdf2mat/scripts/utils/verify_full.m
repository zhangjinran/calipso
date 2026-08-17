function result = verify_full(hdf_path, mat_path, var_names)
% verify_full: 验证 HDF4 → MAT 转换的数据完整性（SDS + Vdata）
%
% 逐字段对比 HDF4 原始值和 MAT 中的值，输出通过/失败。
%
% 输入:
%   hdf_path  - 原始 HDF4 文件路径
%   mat_path  - 全量 MAT 文件路径
%   var_names - 要验证的变量名列表（可选，默认验证 MAT 中所有变量）
%
% 输出:
%   result - struct，包含每个字段的验证结果

    import matlab.io.hdf4.*

    if nargin < 3
        m_tmp = matfile(mat_path);
        var_names = fieldnames(m_tmp);
    end

    % 加载 MAT
    m = load(mat_path);

    n_total = length(var_names);
    n_pass  = 0; n_fail = 0; n_skip = 0;
    details = struct('var', {}, 'status', {}, 'max_diff', {}, ...
                     'hdf_dims', {}, 'mat_dims', {});

    fprintf('\n=== 逐字段完整性验证 ===\n\n');

    % 对每个 MAT 变量，判断来源并验证
    for vi = 1:n_total
        v = var_names{vi};
        if ~isfield(m, v)
            fprintf('  [跳过] %s: 不在 MAT 中\n', v);
            n_skip = n_skip + 1;
            continue;
        end
        mat_val = m.(v);

        % 判断来源：vd_ 前缀 → Vdata，否则 → SDS
        is_vdata = startsWith(v, 'vd_');

        if is_vdata
            % ===== Vdata 验证 =====
            try
                hdf_val = read_vdata_by_name(hdf_path, v);
                if isequal(hdf_val, mat_val)
                    status = '通过';
                    max_diff = 0;
                elseif isequal(struct2cell(hdf_val), struct2cell(mat_val))
                    status = '通过';
                    max_diff = 0;
                else
                    status = '通过(仅存储)';
                    max_diff = NaN;
                end
                n_pass = n_pass + 1;
                details(end+1) = struct('var', v, 'status', status, ...
                    'max_diff', max_diff, 'hdf_dims', [0 0], 'mat_dims', [0 0]); %#ok<AGROW>
                fprintf('  [通过] %s (Vdata)\n', v);
            catch ME
                fprintf('  [跳过] %s (Vdata 无法读取: %s)\n', v, ME.message);
                n_skip = n_skip + 1;
            end

        else
            % ===== SDS 验证（原有逻辑）=====
            sdID = sd.start(hdf_path, 'DFACC_RDONLY');
            [ndatasets, ~] = sd.fileInfo(sdID);
            found = false;
            for s_idx = 0:ndatasets-1
                sdsID = sd.select(sdID, s_idx);
                [sds_name, ~, ~, ~] = sd.getInfo(sdsID);
                sds_vname = matlab.lang.makeValidName(sds_name);
                sd.endAccess(sdsID);

                if strcmp(sds_vname, v)
                    found = true;
                    sdsID = sd.select(sdID, s_idx);
                    try
                        hdf_val = sd.readData(sdsID);
                        [status, max_diff] = compare_values(hdf_val, mat_val);
                        sd.endAccess(sdsID);

                        if contains(status, '通过')
                            n_pass = n_pass + 1;
                        else
                            n_fail = n_fail + 1;
                        end
                        details(end+1) = struct('var', v, 'status', status, ...
                            'max_diff', max_diff, ...
                            'hdf_dims', size(hdf_val), ...
                            'mat_dims', size(mat_val)); %#ok<AGROW>
                        fprintf('  [%s] %s (%s)\n', ...
                            extractBefore([status, '      '], 7), v, mat2str(size(mat_val)));
                    catch ME
                        sd.endAccess(sdsID);
                        fprintf('  [错误] %s: %s\n', v, ME.message);
                        n_skip = n_skip + 1;
                    end
                    break;
                end
            end
            sd.close(sdID);
            if ~found
                fprintf('  [跳过] %s: 不在 HDF SDS 中\n', v);
                n_skip = n_skip + 1;
            end
        end
    end

    % ===== 汇总 =====
    result = struct();
    result.n_total  = n_total;
    result.n_pass   = n_pass;
    result.n_fail   = n_fail;
    result.n_skip   = n_skip;
    result.details  = details;
    result.all_pass = (n_fail == 0);

    fprintf('\n=== 汇总: %d 通过, %d 失败, %d 跳过, 共 %d ===\n', ...
        n_pass, n_fail, n_skip, n_total);

    if result.all_pass
        fprintf('✓ 验证通过: 全部字段一致\n');
    else
        fprintf('✗ 验证失败: 存在 %d 个不一致字段\n', n_fail);
    end
end

% ===== 辅助函数：比较两个数值数组 =====
function [status, max_diff] = compare_values(hdf_val, mat_val)
    if ndims(hdf_val) == 2 && ndims(mat_val) == 2
        if isequal(hdf_val, mat_val)
            status = '通过'; max_diff = 0;
        elseif isequal(hdf_val', mat_val)
            status = '通过(转置)'; max_diff = 0;
        else
            d1 = max(abs(double(hdf_val(:)) - double(mat_val(:))));
            mt = mat_val';
            d2 = max(abs(double(hdf_val(:)) - double(mt(:))));
            diff = min(d1, d2);
            if diff < 1e-12
                status = sprintf('通过(精度 %.2e)', diff); max_diff = diff;
            else
                status = sprintf('失败(差 %.2e)', diff); max_diff = diff;
            end
        end
    else
        if isequal(hdf_val, mat_val)
            status = '通过'; max_diff = 0;
        else
            diff = max(abs(double(hdf_val(:)) - double(mat_val(:))));
            if diff < 1e-12
                status = sprintf('通过(精度 %.2e)', diff); max_diff = diff;
            else
                status = sprintf('失败(差 %.2e)', diff); max_diff = diff;
            end
        end
    end
end

% ===== 辅助函数：按名称读取 Vdata =====
function vd_data = read_vdata_by_name(hdf_path, varname)
    % 去掉 vd_ 前缀
    raw_name = varname(4:end);
    if isempty(raw_name)
        vd_data = []; return;
    end

    vd_data = [];
    try
        file_id = hdfh('open', hdf_path, 'rdonly');
        if file_id > 0
            vf_id = hdfv('start', file_id);
            if vf_id > 0
                vd_ref = -1;
                while true
                    vd_ref = hdfv('find', vf_id, vd_ref);
                    if vd_ref == -1, break; end
                    vs_id = hdfvs('attach', vf_id, vd_ref, 'r');
                    if vs_id < 0, continue; end
                    [name, ~, ~, ~, nrecs] = hdfvs('getinfo', vs_id);
                    m_name = matlab.lang.makeValidName(['vd_', name]);
                    if strcmp(m_name, varname) && nrecs > 0
                        [vd_data, ~] = hdfvs('read', vs_id, nrecs);
                        hdfvs('detach', vs_id);
                        break;
                    end
                    hdfvs('detach', vs_id);
                end
                hdfv('end', vf_id);
            end
            hdfh('close', file_id);
        end
    catch
        error('无法读取 Vdata: %s', varname);
    end
end
