%% run_day_test.m
% HDF → MAT 评估：1 天数据测试
%
% 执行流程：
%   1. 对 1 天的 APro / ALay / VFM 数据各选 1 个 HDF 文件
%   2. hdf2mat_full → 全量转换
%   3. verify_full → 逐字段验证
%   4. 报告效率 + 体积结果
%
% 配置区：修改下面两个变量即可切换测试日期和数据类型

% ====== 配置 ======
test_date   = '2007-01-01';          % 测试日期
data_types  = {'05kmAP', '05kmAL', 'VFM'};  % 要测试的数据类型
data_root   = 'Z:\';                  % Z 盘根目录
output_dir  = fullfile('hdf2mat', 'data');  % 输出目录
addpath('hdf2mat/scripts/utils');
% ==================

fprintf('========================================================\n');
fprintf('  HDF → MAT 评估: 1 天数据测试\n');
fprintf('  日期: %s\n', test_date);
fprintf('========================================================\n');

% 构造日期目录路径
yr = test_date(1:4);
day_folder = strrep(test_date, '-', '_');

results = table();
sample_names = {};

for ti = 1:length(data_types)
    dtype = data_types{ti};
    fprintf('\n---------- %s ----------\n', dtype);

    % 找该类型当天的第一个 HDF 文件
    search_path = fullfile(data_root, dtype, yr, day_folder, '*.hdf');
    files = dir(search_path);
    if isempty(files)
        fprintf('  %s: 未找到文件\n', dtype);
        sample_names{ti} = '(无)';
        continue;
    end
    sample_names{ti} = files(1).name;
    hdf_path = fullfile(files(1).folder, files(1).name);
    fprintf('  样本: %s\n', files(1).name);

    % Step 1: 全量转换
    mat_name = sprintf('%s_%s_full.mat', dtype, test_date);
    mat_path = fullfile(output_dir, mat_name);

    fprintf('\n  --- 全量转换 ---\n');
    info = hdf2mat_full(hdf_path, mat_path);

    % Step 2: 完整性验证
    fprintf('\n  --- 完整性验证 ---\n');
    vresult = verify_full(hdf_path, mat_path);

    % Step 3: 读取效率对比
    fprintf('\n  --- 读取效率对比 ---\n');
    % 单字段读取
    tic; hdf_val = hdfread(hdf_path, info.var_names{1}); hdf_time = toc;
    tic; m = matfile(mat_path); mat_val = m.(info.var_names{1}); mat_time = toc;
    % 全量加载
    tic; load(mat_path); mat_full_time = toc;
    % 逐字段 hdfread 全部 SDS（统计总读取时间）
    import matlab.io.hdf4.*
    sdID2 = sd.start(hdf_path, 'DFACC_RDONLY');
    [n2, ~] = sd.fileInfo(sdID2);
    tic;
    for si = 0:n2-1
        s2 = sd.select(sdID2, si);
        [n2_name, ~, ~, ~] = sd.getInfo(s2);
        try hdfread(hdf_path, n2_name); catch, end
        sd.endAccess(s2);
    end
    sd.close(sdID2);
    hdf_all_time = toc;

    fprintf('    hdfread 单字段: %.4f sec\n', hdf_time);
    fprintf('    hdfread 全部SDS: %.2f sec\n', hdf_all_time);
    fprintf('    load MAT 单字段: %.4f sec (%.0f%%)\n', ...
        mat_time, mat_time/hdf_time*100);
    fprintf('    load MAT 全量:   %.4f sec\n', mat_full_time);

    % 收集跳过的字段名
    skipped_names = {};
    for di = 1:length(vresult.details)
        if contains(vresult.details(di).status, '跳过')
            skipped_names{end+1} = vresult.details(di).var;
        end
    end

    % 汇总行
    results = [results; table(...
        {dtype}, ...
        info.hdf_size, info.mat_size, ...
        info.mat_size / info.hdf_size * 100, ...
        info.read_time, hdf_time, hdf_all_time, mat_time, mat_full_time, ...
        vresult.all_pass, ...
        vresult.n_total, vresult.n_fail, vresult.n_skip, ...
        {strjoin(skipped_names, ', ')}, ...
        'VariableNames', ...
        {'DataType', 'HDF_Size', 'MAT_Size', 'Ratio_Pct', ...
         'Conv_Time', 'HDF_Read_S', 'HDF_All_SDS_S', 'MAT_Read_S', 'MAT_Full_Load_S', ...
         'All_Pass', 'N_Fields', 'N_Fail', 'N_Skip', 'Skipped'})]; %#ok<AGROW>
end

% ====== 最终报告 ======
fprintf('\n\n========================================================\n');
fprintf('  1 天测试结果汇总\n');
fprintf('========================================================\n');
disp(results);

fprintf('\n结论:\n');
if all(results.All_Pass)
    fprintf('  ✓ 所有类型验证通过\n');
else
    fprintf('  ✗ 存在验证失败的字段\n');
end

% 检查体积
all_smaller = all(results.MAT_Size <= results.HDF_Size);
if all_smaller
    fprintf('  ✓ 全量 MAT 体积均 ≤ 原始 HDF\n');
else
    fprintf('  ⚠ 部分类型 MAT 体积大于 HDF\n');
end
fprintf('\n结果保存在: %s\n', output_dir);

% ====== 写入结果文件 ======
res_path = fullfile('hdf2mat', 'data', 'results_day1.txt');
fid = fopen(res_path, 'w');
fprintf(fid, '========================================================\n');
fprintf(fid, '  HDF → MAT 评估结果: 1 天测试\n');
fprintf(fid, '  日期: %s\n', test_date);
fprintf(fid, '========================================================\n\n');

for ti = 1:length(data_types)
    dtype = data_types{ti};
    fprintf(fid, '--- %s ---\n', dtype);
    r = results(ti, :);
    fprintf(fid, '  样本文件: %s\n', sample_names{ti});
    fprintf(fid, '  原始 HDF:  %.2f MB\n', r.HDF_Size / 1e6);
    fprintf(fid, '  全量 MAT:  %.2f MB (%.1f%%)\n', r.MAT_Size / 1e6, r.Ratio_Pct);
    fprintf(fid, '  转换耗时:  %.2f sec (读取全部SDS + 保存到文件)\n', r.Conv_Time);
    fprintf(fid, '  ── 读取速度 ──\n');
    fprintf(fid, '    hdfread 单字段: %.4f sec\n', r.HDF_Read_S);
    fprintf(fid, '    matfile  单字段: %.4f sec (%.0f%%)\n', r.MAT_Read_S, ...
        r.MAT_Read_S / r.HDF_Read_S * 100);
    fprintf(fid, '    load 全量MAT:   %.4f sec\n', r.MAT_Full_Load_S);
    fprintf(fid, '    ─ 总耗时对比 ─\n');
    fprintf(fid, '    hdfread 全部SDS: %.2f sec\n', r.HDF_All_SDS_S);
    fprintf(fid, '    load 全量MAT:    %.4f sec (%.1f%%)\n', ...
        r.MAT_Full_Load_S, r.MAT_Full_Load_S / r.HDF_All_SDS_S * 100);
    fprintf(fid, '  ── 字段验证 ──\n');
    fprintf(fid, '    总 %d, 通过 %d, 失败 %d, 跳过 %d\n', ...
        r.N_Fields, r.N_Fields - r.N_Fail - r.N_Skip, r.N_Fail, r.N_Skip);
    if r.N_Skip > 0 && ~isempty(r.Skipped)
        fprintf(fid, '    跳过字段: %s\n', r.Skipped{1});
    end
    fprintf(fid, '\n');
end

fprintf(fid, '结论:\n');
if all(results.All_Pass)
    fprintf(fid, '  ✓ 所有类型验证通过\n');
else
    fprintf(fid, '  ✗ 存在验证失败的字段\n');
end
if all(results.MAT_Size <= results.HDF_Size)
    fprintf(fid, '  ✓ 全量 MAT ≤ HDF 体积\n');
else
    fprintf(fid, '  ⚠ 部分 MAT > HDF\n');
end
fclose(fid);
fprintf('\n结果已写入: %s\n', res_path);
