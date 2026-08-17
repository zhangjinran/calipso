function pass = test_main_day(date_str)
% TEST_MAIN_DAY  主程序兼容性测试（v2, fixed 2026-07-28）
%
% 测试方法:
%   1. 用 Fun_getCALIPSO_L2 读取原始 HDF，导出 mycell 作为参照
%   2. 从 MAT 数据库加载，生成相同格式的 mycell
%   3. 逐字段对比关键数据结构（ALay_05km, L2_APro, VFM）
%   4. 截取主程序的计算管道，用两种数据源分别跑，对比输出
%
% v2 修复:
%   - 完整 87 文件逐文件对拍（原版只测每类第一个文件）
%   - 适配器 filter_mat_like_getCALIPSO_L2 v2（方向/裁剪/字段映射修复）
%
% 用法:
%   pass = test_main_day('2007-01-01');

    CFG = config();
    yr = date_str(1:4);
    day_folder = strrep(date_str, '-', '_');
    pass = true;

    fprintf('\n========================================================\n');
    fprintf('  主程序兼容性测试: %s\n', date_str);
    fprintf('========================================================\n');

    % ===== 1. 检查 MAT 文件 =====
    for pi = 1:length(CFG.PRODUCTS)
        p = CFG.PRODUCTS{pi};
        mp = CFG.MAT_PATH_FMT(p, str2double(yr), day_folder);
        if ~isfile(mp)
            fprintf('  ❌ MAT 不存在: %s\n', mp);
            pass = false; return;
        end
    end

    % 确保主程序函数在路径中
    addpath(genpath('F:\CALIPSO_Code_new'));

    % ===== 2. 完整 87 文件逐文件对拍（数据层）=====
    products = {'05kmAL', '05kmAP', 'VFM'};
    indices  = [1, 5, 7];
    names    = {'ALay_05km', 'L2_APro', 'VFM'};
    total_files = 0; total_pass = 0; total_fail = 0;
    fail_list = {};

    % ALay 首文件 psl（APro/VFM 沿用，与主函数一致）
    psl_alay = [nan, nan];

    for pi = 1:3
        p = products{pi};
        hdf_dir = fullfile(CFG.HDF_ROOT, p, yr, day_folder);
        hdf_files = dir(fullfile(hdf_dir, '*.hdf'));
        if isempty(hdf_files)
            fprintf('  [%s] 无 HDF 文件\n', p); continue;
        end
        d = load(CFG.MAT_PATH_FMT(p, str2double(yr), day_folder));
        d = d.day;
        fprintf('\n  --- [%s] 逐文件对拍 %d 个文件 ---\n', p, numel(hdf_files));

        for i = 1:numel(hdf_files)
            hdf_path = fullfile(hdf_dir, hdf_files(i).name);
            total_files = total_files + 1;

            % 找 MAT 中对应文件
            mat_idx = [];
            for j = 1:numel(d.files)
                if isfield(d.files{j}, 'filename') && strcmp(d.files{j}.filename, hdf_files(i).name)
                    mat_idx = j; break;
                end
            end
            if isempty(mat_idx)
                fprintf('  ❌ %s: MAT 无对应文件\n', hdf_files(i).name);
                pass = false; total_fail = total_fail + 1;
                fail_list{end+1} = sprintf('%s: MAT无对应', hdf_files(i).name);
                continue;
            end

            % HDF 参照（ALay 自算 psl；APro/VFM 用 ALay 首文件 psl）
            if pi == 1
                psl_use = [nan, nan];
            else
                psl_use = psl_alay;
            end
            try
                ref = Fun_getCALIPSO_L2(hdf_path, [15, 55], psl_use);
            catch ME
                fprintf('  ❌ %s: HDF 读取失败 %s\n', hdf_files(i).name, ME.message);
                pass = false; total_fail = total_fail + 1;
                fail_list{end+1} = sprintf('%s: HDF读取失败', hdf_files(i).name);
                continue;
            end
            if pi == 1
                psl_alay = [ref.profile_start_end(1), ref.profile_number];
            end

            % MAT 适配
            try
                matf = filter_mat_like_getCALIPSO_L2(d.files{mat_idx}, [15, 55], psl_use);
            catch ME
                fprintf('  ❌ %s: MAT 适配失败 %s\n', hdf_files(i).name, ME.message);
                pass = false; total_fail = total_fail + 1;
                fail_list{end+1} = sprintf('%s: MAT适配失败', hdf_files(i).name);
                continue;
            end

            % 逐字段对比（fileName 用完整路径对齐 Fun 输出）
            if isfield(matf, 'fileName')
                matf.fileName = hdf_path;
            end
            ok = compare_single(ref, matf, sprintf('%s[%d]', names{pi}, i));
            if ok
                total_pass = total_pass + 1;
            else
                pass = false; total_fail = total_fail + 1;
                fail_list{end+1} = sprintf('%s(%d)', names{pi}, i);
            end
        end
    end
    fprintf('\n  --- 数据层汇总: %d/%d 文件通过, %d 失败 ---\n', ...
        total_pass, total_files, total_fail);

    % ===== 3. 计算管道对比（首文件，AOD/FREQ/Classified AOD）=====
    fprintf('\n  --- 计算管道对比 ---\n');
    [pipe_match, pipe_detail] = run_pipe_full(date_str);
    if ~pipe_match
        pass = false;
        fprintf('  ❌ 计算管道对比失败\n');
    else
        fprintf('  ✅ 计算管道对比通过\n');
    end

    % ===== 结果 =====
    records = db_query('date', date_str);
    for i = 1:length(records)
        db_update(records(i).filename, 'main_test_status', ...
            iif(pass, 'pass', 'fail'));
    end

    if pass
        fprintf('\n✅ 主程序兼容性测试通过 (87文件数据层 + 计算管道)\n');
    else
        fprintf('\n❌ 主程序兼容性测试失败 (%d 文件失败)\n', total_fail);
    end
    logger('test', date_str, 'ALL', iif(pass, 'PASS', 'FAIL'));
end

% ===== 逐字段对比 struct =====
function ok = compare_single(s1, s2, name)
    ok = true;
    fn = intersect(fieldnames(s1), fieldnames(s2));
    diff_list = {};

    for fi = 1:length(fn)
        f = fn{fi};
        v1 = s1.(f); v2 = s2.(f);

        if isnumeric(v1) && isnumeric(v2)
            if isequal(size(v1), size(v2))
                d = max(abs(double(v1(:)) - double(v2(:))));
            elseif ndims(v1) == 2 && ndims(v2) == 2 && isequal(size(v1'), size(v2))
                v2t = v2';
                d = max(abs(double(v1(:)) - double(v2t(:))));
            else
                diff_list{end+1} = sprintf('%s:size[%s]vs[%s]', f, ...
                    mat2str(size(v1)), mat2str(size(v2)));
                ok = false; continue;
            end
            if d > 1e-10
                diff_list{end+1} = sprintf('%s:diff=%.2e', f, d);
                ok = false;
            end
        elseif ~isequal(v1, v2)
            diff_list{end+1} = sprintf('%s:值不匹配', f);
            ok = false;
        end
    end

    if ok
        fprintf('    ✅ %s: %d 个字段一致\n', name, length(fn));
    else
        fprintf('    ❌ %s: %d 个差异\n', name, length(diff_list));
        for i = 1:min(3, length(diff_list))
            fprintf('        %s\n', diff_list{i});
        end
    end
end

% ===== 计算管道对比（完整实现，AOD/FREQ/Classified AOD）=====
function [ok, detail] = run_pipe_full(date_str)
    ok = true; detail = '';
    CFG = config();
    yr = date_str(1:4);
    day_folder = strrep(date_str, '-', '_');
    lat_lim = [15, 55]; lon_lim = [70, 135];
    psl = [nan, nan];

    % 参照：从 HDF 读取三类首文件
    ref = struct();
    prods = {'05kmAL', '05kmAP', 'VFM'};
    idxs  = [1, 5, 7];
    names = {'ALay_05km', 'L2_APro', 'VFM'};
    for pi = 1:3
        p = prods{pi};
        hdf_dir = fullfile(CFG.HDF_ROOT, p, yr, day_folder);
        f = dir(fullfile(hdf_dir, '*.hdf'));
        if isempty(f); continue; end
        ref.(names{pi}) = Fun_getCALIPSO_L2(fullfile(hdf_dir, f(1).name), lat_lim, psl);
        psl = [ref.(names{pi}).profile_start_end(1), ref.(names{pi}).profile_number];
    end

    % 对比：从 MAT 读取三类首文件
    mm = struct();
    psl = [nan, nan];
    for pi = 1:3
        p = prods{pi};
        mp = CFG.MAT_PATH_FMT(p, str2double(yr), day_folder);
        d = load(mp); d = d.day;
        if pi == 1
            psl_use = [nan, nan];
        else
            psl_use = psl;
        end
        mm.(names{pi}) = filter_mat_like_getCALIPSO_L2(d.files{1}, lat_lim, psl_use);
        psl = [mm.(names{pi}).profile_start_end(1), mm.(names{pi}).profile_number];
    end

    % 表面分类
    try
        sr = Select_surface_From_VFM(ref.VFM.Feature_Classification_Flags, [1, length(ref.VFM.Lat)], 'type');
        sm = Select_surface_From_VFM(mm.VFM.Feature_Classification_Flags, [1, length(mm.VFM.Lat)], 'type');
    catch ME
        fprintf('  ⚠ 表面分类失败: %s\n', ME.message);
        ok = false; detail = ME.message; return;
    end

    % AOD（矩阵比较）
    try
        [aod_ref, cnt_ref] = create_empty_aod_grid(lon_lim, lat_lim);
        [aod_mat, cnt_mat] = create_empty_aod_grid(lon_lim, lat_lim);
        [aod_ref, cnt_ref] = calculate_aod(sr, ref.ALay_05km, aod_ref, cnt_ref, [-180:5:180], [-90:5:90]);
        [aod_mat, cnt_mat] = calculate_aod(sm, mm.ALay_05km, aod_mat, cnt_mat, [-180:5:180], [-90:5:90]);
        d_aod = max(abs(aod_ref(:) - aod_mat(:)), [], 'all');
        d_cnt = max(abs(cnt_ref(:) - cnt_mat(:)), [], 'all');
        if d_aod > 1e-10 || d_cnt > 0
            fprintf('  ⚠ AOD: aod diff=%.2e, cnt diff=%d\n', d_aod, d_cnt);
            ok = false;
        else
            fprintf('  ✅ AOD: 输出一致\n');
        end
    catch ME
        fprintf('  ⚠ AOD 对比: %s\n', ME.message);
        ok = false;
    end

    % FREQ（总频率路径，矩阵比较）
    try
        [freq_ref, fcnt_ref] = create_empty_freq_grid(lon_lim, lat_lim);
        [freq_mat, fcnt_mat] = create_empty_freq_grid(lon_lim, lat_lim);
        [freq_ref, fcnt_ref] = calculate_freq(ref.VFM, ref.ALay_05km, sr, freq_ref, fcnt_ref, [-180:5:180], [-90:5:90]);
        [freq_mat, fcnt_mat] = calculate_freq(mm.VFM, mm.ALay_05km, sm, freq_mat, fcnt_mat, [-180:5:180], [-90:5:90]);
        d_freq = max(abs(freq_ref(:) - freq_mat(:)), [], 'all');
        d_fcnt = max(abs(fcnt_ref(:) - fcnt_mat(:)), [], 'all');
        if d_freq > 1e-10 || d_fcnt > 0
            fprintf('  ⚠ FREQ: freq diff=%.2e, cnt diff=%d\n', d_freq, d_fcnt);
            ok = false;
        else
            fprintf('  ✅ FREQ: 输出一致\n');
        end
    catch ME
        fprintf('  ⚠ FREQ 对比: %s\n', ME.message);
        ok = false;
    end

    % Classified AOD（矩阵比较）
    try
        [ca_ref, cc_ref] = create_empty_classified_aod_grid(lon_lim, lat_lim);
        [ca_mat, cc_mat] = create_empty_classified_aod_grid(lon_lim, lat_lim);
        [ca_ref, cc_ref] = calculate_classified_aod(ref.VFM, ref.L2_APro, ref.ALay_05km, sr, ca_ref, cc_ref, [-180:5:180], [-90:5:90]);
        [ca_mat, cc_mat] = calculate_classified_aod(mm.VFM, mm.L2_APro, mm.ALay_05km, sm, ca_mat, cc_mat, [-180:5:180], [-90:5:90]);
        d_ca = max(abs(ca_ref(:) - ca_mat(:)), [], 'all');
        d_cc = max(abs(cc_ref(:) - cc_mat(:)), [], 'all');
        if d_ca > 1e-10 || d_cc > 0
            fprintf('  ⚠ Classified AOD: aod diff=%.2e, cnt diff=%d\n', d_ca, d_cc);
            ok = false;
        else
            fprintf('  ✅ Classified AOD: 输出一致\n');
        end
    catch ME
        fprintf('  ⚠ Classified AOD 对比: %s\n', ME.message);
        ok = false;
    end
end

function s = iif(cond, t, f)
    if cond, s = t; else, s = f; end
end
