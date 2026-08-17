function report_path = generate_day_report(date_str)
% GENERATE_DAY_REPORT  生成单日迁移报告
%
% 输入:
%   date_str - 日期，如 '2007-01-01'
%
% 输出:
%   report_path - 报告文件路径
%
% 逻辑:
%   在 convert + verify + main_test 全部完成后调用

    CFG = config();
    yr = date_str(1:4);
    day_folder = strrep(date_str, '-', '_');

    % 从 database_index 查询该天所有记录
    records = db_query('date', date_str);
    if isempty(records)
        error('database_index 中无 %s 的记录', date_str);
    end

    % 按产品分组统计
    products = CFG.PRODUCTS;
    product_stats = containers.Map();
    total_hdf = 0;
    total_convert_ok = 0;
    total_verify_ok = 0;
    total_main_ok = 0;
    total_mat_bytes = 0;
    total_hdf_bytes = 0;
    all_pass = true;

    for pi = 1:length(products)
        p = products{pi};
        p_records = records(strcmp({records.product}, p));

        n_total  = length(p_records);
        n_conv   = sum(strcmp({p_records.convert_status}, 'complete'));
        n_verif  = sum(strcmp({p_records.verify_status}, 'pass'));
        n_main   = sum(strcmp({p_records.main_test_status}, 'pass'));

        mat_path = CFG.MAT_PATH_FMT(p, str2double(yr), day_folder);
        if isfile(mat_path)
            mat_bytes = dir(mat_path).bytes;
        else
            mat_bytes = 0;
        end

        hdf_bytes = sum([p_records.hdf_size]);

        p_pass = (n_conv == n_total) && (n_verif == n_total) && (n_main == n_total) && (mat_bytes > 0);

        product_stats(p) = struct( ...
            'total', n_total, 'converted', n_conv, ...
            'verified', n_verif, 'main_tested', n_main, ...
            'mat_bytes', mat_bytes, 'hdf_bytes', hdf_bytes, 'pass', p_pass);

        total_hdf = total_hdf + n_total;
        total_convert_ok = total_convert_ok + n_conv;
        total_verify_ok  = total_verify_ok + n_verif;
        total_main_ok    = total_main_ok + n_main;
        total_mat_bytes  = total_mat_bytes + mat_bytes;
        total_hdf_bytes  = total_hdf_bytes + hdf_bytes;
        if ~p_pass; all_pass = false; end
    end

    % 生成报告文件
    report_dir = fullfile(CFG.LOG_DIR, 'migration_report');
    if ~isfolder(report_dir); mkdir(report_dir); end
    report_path = fullfile(report_dir, [date_str, '_report.txt']);

    fid = fopen(report_path, 'w');
    fprintf(fid, 'CALIPSO MAT Database — 日迁移报告\n');
    fprintf(fid, '日期: %s\n', date_str);
    fprintf(fid, '生成时间: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid, '================================\n\n');

    for pi = 1:length(products)
        p = products{pi};
        s = product_stats(p);
        fprintf(fid, '--- %s ---\n', p);
        fprintf(fid, '  HDF 文件:     %d / %d  %s\n', s.total, s.total, '✓');
        fprintf(fid, '  转换成功:     %d / %d  %s\n', s.converted, s.total, ...
            ternary(s.converted == s.total, '✓', '✗'));
        fprintf(fid, '  验证通过:     %d / %d  %s\n', s.verified, s.total, ...
            ternary(s.verified == s.total, '✓', '✗'));
        fprintf(fid, '  主程序测试:   %d / %d  %s\n', s.main_tested, s.total, ...
            ternary(s.main_tested == s.total, '✓', '✗'));
        fprintf(fid, '  MAT 文件:     %.1f MB  %s\n', s.mat_bytes / 1e6, ...
            ternary(s.mat_bytes > 0, '✓', '✗'));
        fprintf(fid, '\n');
    end

    fprintf(fid, '汇总:\n');
    fprintf(fid, '  HDF 总数:     %d\n', total_hdf);
    fprintf(fid, '  转换成功率:   %.1f%%\n', total_convert_ok / total_hdf * 100);
    fprintf(fid, '  验证通过率:   %.1f%%\n', total_verify_ok / total_hdf * 100);
    fprintf(fid, '  主程序通过率: %.1f%%\n', total_main_ok / total_hdf * 100);
    fprintf(fid, '  MAT 总大小:   %.1f MB\n', total_mat_bytes / 1e6);
    fprintf(fid, '  HDF 总大小:   %.1f MB\n', total_hdf_bytes / 1e6);
    fprintf(fid, '\n');
    fprintf(fid, '删除 HDF: %s\n', ternary(all_pass, '允许（全部条件满足）', '阻止（存在失败项）'));
    fprintf(fid, '================================\n');

    fclose(fid);
    fprintf('  [报告] 已生成: %s\n', report_path);
end

function s = ternary(cond, t, f)
    if cond, s = t; else, s = f; end
end
