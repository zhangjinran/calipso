function all_pass = verify_day(date_str, product)
% VERIFY_DAY  日验证：对比日 MAT 与原始 HDF 的字段一致性
%
% 输入:
%   date_str - 日期，如 '2007-01-01'
%   product  - 产品，如 '05kmAP'
%
% 输出:
%   all_pass - true/false
%
% 用法:
%   all_pass = verify_day('2007-01-01', '05kmAP');

    CFG = config();
    yr = date_str(1:4);
    day_folder = strrep(date_str, '-', '_');

    % 1. 加载日 MAT
    mat_path = CFG.MAT_PATH_FMT(product, str2double(yr), day_folder);
    if ~isfile(mat_path)
        error('MAT 文件不存在: %s', mat_path);
    end
    day = load(mat_path);
    day = day.day;

    fprintf('  [验证] %s %s: %d 个文件\n', product, date_str, length(day.files));

    % 2. 检查文件数量
    hdf_dir = fullfile(CFG.HDF_ROOT, product, yr, day_folder);
    hdf_files = dir(fullfile(hdf_dir, '*.hdf'));
    n_hdf = length(hdf_files);

    if n_hdf ~= length(day.files)
        fprintf('  ❌ 文件数量不匹配: HDF %d, MAT %d\n', n_hdf, length(day.files));
        all_pass = false;
        return;
    end

    % 3. 逐个文件验证
    all_pass = true;
    pass_count = 0;
    fail_count = 0;

    for i = 1:length(day.files)
        hdf_path = fullfile(hdf_dir, hdf_files(i).name);

        [file_pass, details] = verify_single_hdf(hdf_path, day.files{i});

        if file_pass
            pass_count = pass_count + 1;
            db_update(day.files{i}.filename, 'verify_status', 'pass');
        else
            fail_count = fail_count + 1;
            all_pass = false;
            db_update(day.files{i}.filename, 'verify_status', 'fail');

            % 输出前 3 个失败详情
            if fail_count <= 3
                failed_fields = details(find(~strcmp({details.status}, '通过') & ...
                    ~strcmp({details.status}, '跳过')));
                for k = 1:min(3, length(failed_fields))
                    fprintf('    ❌ %s: %s\n', ...
                        failed_fields(k).field, failed_fields(k).status);
                end
            end
        end
    end

    % 4. 汇总
    fprintf('  [验证] %s %s: %d 通过, %d 失败 / %d\n', ...
        product, date_str, pass_count, fail_count, length(day.files));
    logger('verify', date_str, product, ...
        sprintf('%d/%d 通过', pass_count, length(day.files)));

    if all_pass
        fprintf('  ✅ 验证通过\n');
    else
        fprintf('  ❌ 验证失败\n');
    end
end
