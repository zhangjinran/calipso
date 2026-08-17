%% run_month_test.m
% HDF → MAT 评估：1 月数据验证
%
% 将 2007 年 1 月 1 日 ~ 31 日的全部文件转为 MAT，
% 验证在大批量下的转换效率、体积压缩和完整性。

% ====== 配置 ======
test_year   = 2007;
test_month  = 1;
data_types  = {'05kmAP', '05kmAL', 'VFM'};
data_root   = 'Z:\';
output_dir  = fullfile('hdf2mat', 'data', 'month_test');
addpath('hdf2mat/scripts/utils');
% ==================

mkdir(output_dir);

% 生成该月所有日期
n_days = eomday(test_year, test_month);
dates_str = arrayfun(@(d) sprintf('%04d-%02d-%02d', test_year, test_month, d), ...
    1:n_days, 'UniformOutput', false);

fprintf('========================================================\n');
fprintf('  HDF → MAT 评估: %d 月验证\n', test_year);
fprintf('  %s ~ %s, %d 天\n', dates_str{1}, dates_str{end}, n_days);
fprintf('========================================================\n');

overall = table();

for ti = 1:length(data_types)
    dtype = data_types{ti};
    fprintf('\n========== %s ==========\n', dtype);

    import matlab.io.hdf4.*

    total_hdf = 0; total_mat = 0;
    total_conv = 0; total_hdf_read = 0; total_mat_load = 0;
    n_file = 0; n_fail = 0;
    all_pass = true;

    for di = 1:n_days
        yr = dates_str{di}(1:4);
        day_f = strrep(dates_str{di}, '-', '_');

        search_path = fullfile(data_root, dtype, yr, day_f, '*.hdf');
        files = dir(search_path);
        if isempty(files), continue; end

        for fi = 1:length(files)
            hdf_path = fullfile(files(fi).folder, files(fi).name);
            mat_name = sprintf('%s_%s_full.mat', dtype, dates_str{di});
            mat_path = fullfile(output_dir, mat_name);

            if fi > 1
                mat_name = sprintf('%s_%s_%02d_full.mat', dtype, dates_str{di}, fi);
                mat_path = fullfile(output_dir, mat_name);
            end

            try
                % 转换
                info = hdf2mat_full(hdf_path, mat_path);
                total_conv = total_conv + info.read_time;

                % hdfread 全部 SDS（计时）
                sdID = sd.start(hdf_path, 'DFACC_RDONLY');
                [n_sds, ~] = sd.fileInfo(sdID);
                tic;
                for si = 0:n_sds-1
                    s2 = sd.select(sdID, si);
                    [nm,~,~,~] = sd.getInfo(s2);
                    try hdfread(hdf_path, nm); catch, end
                    sd.endAccess(s2);
                end
                sd.close(sdID);
                total_hdf_read = total_hdf_read + toc;

                % load MAT（计时）
                tic; load(mat_path); total_mat_load = total_mat_load + toc;

                % 验证
                vresult = verify_full(hdf_path, mat_path);

                total_hdf = total_hdf + info.hdf_size;
                total_mat = total_mat + info.mat_size;
                n_file = n_file + 1;
                if ~vresult.all_pass
                    all_pass = false; n_fail = n_fail + 1;
                end

                if mod(n_file, 10) == 0
                    fprintf('  已处理 %d 个文件...\n', n_file);
                end
            catch ME
                fprintf('  [失败] %s: %s\n', files(fi).name, ME.message);
                n_fail = n_fail + 1;
            end
        end
    end

    overall = [overall; table(...
        {dtype}, n_file, n_fail, ...
        total_hdf, total_mat, total_mat/total_hdf*100, ...
        total_conv, total_hdf_read, total_mat_load, all_pass, ...
        'VariableNames', ...
        {'Type', 'Files', 'Fails', 'HDF_MB', 'MAT_MB', 'Ratio_Pct', ...
         'Conv_Time', 'HDF_Read_S', 'MAT_Load_S', 'All_Pass'})]; %#ok<AGROW>
end

% ====== 报告 ======
fprintf('\n\n========================================================\n');
fprintf('  1 月验证完成\n');
fprintf('========================================================\n');
disp(overall);

% 写入结果文件
res_path = fullfile('hdf2mat', 'result', 'results_month1.txt');
fid = fopen(res_path, 'w');
fprintf(fid, 'HDF → MAT 评估: %d 月验证\n', test_year);
fprintf(fid, '文件 %d 个\n\n', sum(overall.Files));
for ti = 1:height(overall)
    r = overall(ti, :);
    fprintf(fid, '--- %s ---\n', r.Type{1});
    fprintf(fid, '  文件数: %d, 失败: %d\n', r.Files, r.Fails);
    fprintf(fid, '  原始 HDF:  %.0f MB\n', r.HDF_MB / 1e6);
    fprintf(fid, '  全量 MAT:  %.0f MB (%.1f%%)\n', r.MAT_MB / 1e6, r.Ratio_Pct);
    fprintf(fid, '  转换耗时:  %.1f sec\n', r.Conv_Time);
    fprintf(fid, '  hdfread 全部: %.2f sec\n', r.HDF_Read_S);
    fprintf(fid, '  load 全量MAT: %.4f sec (%.1f%%)\n', ...
        r.MAT_Load_S, r.MAT_Load_S / r.HDF_Read_S * 100);
    fprintf(fid, '\n');
end
fclose(fid);
fprintf('结果已写入: %s\n', res_path);
