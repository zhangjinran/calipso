function [success, fail] = hdf2mat_day(date_str, product)
% HDF2MAT_DAY  转换一天数据：读取当天所有 HDF，合并为 1 个日 MAT
%
% 输入:
%   date_str - 日期，如 '2007-01-01'
%   product  - 产品，如 '05kmAP'
%
% 输出:
%   success  - 成功转换的文件数
%   fail     - 失败的文件数
%
% 用法:
%   [s, f] = hdf2mat_day('2007-01-01', '05kmAP');
%
% 生成:
%   Z:\CALIPSO_MAT_DB\data\05kmAP\2007\2007_01_01.mat

    CFG = config();
    yr = date_str(1:4);
    day_folder = strrep(date_str, '-', '_');
    product_dir = fullfile(CFG.HDF_ROOT, product, yr, day_folder);

    % 1. 扫描当天该产品的所有 HDF 文件
    hdf_files = dir(fullfile(product_dir, '*.hdf'));
    if isempty(hdf_files)
        fprintf('  [%s] 未找到 HDF 文件: %s\n', product, product_dir);
        success = 0; fail = 0;
        return;
    end
    n_total = length(hdf_files);
    fprintf('  [%s] 发现 %d 个 HDF 文件\n', product, n_total);

    % 2. 初始化 day 结构
    day = struct();
    day.meta.source_date   = date_str;
    day.meta.source_number = n_total;
    day.meta.converted     = 0;
    day.meta.status        = 'converting';
    day.meta.hdf_size_bytes = 0;
    day.files = cell(n_total, 1);

    success = 0; fail = 0;
    t_start = tic;

    % 3. 逐个读取 HDF
    for i = 1:n_total
        hdf_path = fullfile(hdf_files(i).folder, hdf_files(i).name);
        try
            day.files{i} = convert_single_hdf(hdf_path);
            day.meta.hdf_size_bytes = day.meta.hdf_size_bytes + hdf_files(i).bytes;
            success = success + 1;

            % 写入 database_index 记录
            record = struct();
            record.filename   = hdf_files(i).name;
            record.date       = date_str;
            record.product    = product;
            record.mat_path   = fullfile('data', product, yr, [day_folder, '.mat']);
            record.file_index = i;
            record.convert_status = 'complete';
            record.verify_status  = 'none';
            record.main_test_status = 'none';
            record.delete_status  = 'keep';
            record.hdf_size   = hdf_files(i).bytes;
            record.mat_size   = 0;
            record.convert_time = 0;
            record.error_message = '';
            % 去重：同一 filename 已存在则更新，不追加新记录
            existing = db_query('filename', record.filename);
            if isempty(existing)
                db_add(record);
            else
                db_update(record.filename, 'convert_status', 'complete');
                db_update(record.filename, 'error_message', '');
                db_update(record.filename, 'hdf_size', record.hdf_size);
                db_update(record.filename, 'file_index', i);
            end

        catch ME
            fail = fail + 1;
            % 失败文件保留槽位，记录错误信息（不丢文件、不错位）
            day.files{i} = struct('filename', hdf_files(i).name, 'convert_error', ME.message);
            record = struct();
            record.filename   = hdf_files(i).name;
            record.date       = date_str;
            record.product    = product;
            record.mat_path   = fullfile('data', product, yr, [day_folder, '.mat']);
            record.file_index = i;
            record.convert_status = 'failed';
            record.verify_status  = 'none';
            record.main_test_status = 'none';
            record.delete_status  = 'keep';
            record.hdf_size   = hdf_files(i).bytes;
            record.mat_size   = 0;
            record.convert_time = 0;
            record.error_message = ME.message;
            % 去重：已存在则更新为 failed
            existing = db_query('filename', record.filename);
            if isempty(existing)
                db_add(record);
            else
                db_update(record.filename, 'convert_status', 'failed');
                db_update(record.filename, 'error_message', ME.message);
                db_update(record.filename, 'file_index', i);
            end

            fprintf('    [失败] %s: %s\n', hdf_files(i).name, ME.message);
        end
    end

    % 4. 计算 MAT 大小（取第一个成功文件的路径估算目录）
    mat_path = CFG.MAT_PATH_FMT(product, str2double(yr), day_folder);
    out_dir = fileparts(mat_path);
    if ~isfolder(out_dir)
        mkdir(out_dir);
    end

    % 保留全部文件槽位（失败项含 convert_error 信息），状态真实反映
    day.meta.converted = success;
    if success == n_total
        day.meta.status = 'complete';
    elseif success > 0
        day.meta.status = 'partial';
    else
        day.meta.status = 'failed';
    end

    % 5. 保存 MAT（含真实 status）
    save(mat_path, 'day', '-v7.3');

    % 6. 更新 MAT 大小（仅成功文件，遍历全部槽位）
    mat_info = dir(mat_path);
    for i = 1:n_total
        if isfield(day.files{i}, 'filename') && ~isfield(day.files{i}, 'convert_error')
            fname = day.files{i}.filename;
            nrec = length(db_query('filename', fname));
            if nrec > 0
                db_update(fname, 'mat_size', mat_info.bytes);
            end
        end
    end

    % 7. 日志
    elapsed = toc(t_start);
    logger('convert', date_str, product, ...
        sprintf('%d/%d 成功, %.1f sec', success, n_total, elapsed));

    fprintf('  [%s] 转换完成: %d/%d 成功 (%.1f sec), status=%s\n', ...
        product, success, n_total, elapsed, day.meta.status);
    fprintf('        输出: %s (%.1f MB)\n', mat_path, mat_info.bytes / 1e6);
end
