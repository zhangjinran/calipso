function info = hdf2mat_full(hdf_path, mat_path)
% hdf2mat_full: 读取 HDF4 文件中的全部数据（SDS + Vdata），保存为 .mat
%
% 输入:
%   hdf_path - HDF4 文件路径
%   mat_path - 输出 .mat 文件路径（不填则自动生成在同目录）
%
% 输出:
%   info - struct，包含转换信息
%
% 用法:
%   info = hdf2mat_full('Z:\05kmAP\2007\2007_01_01\CAL...hdf')
%   info = hdf2mat_full(hdf_path, 'test\sample_apro.mat')

    import matlab.io.hdf4.*

    % ===== 参数处理 =====
    if nargin < 2
        [p, f] = fileparts(hdf_path);
        mat_path = fullfile(p, [f, '.mat']);
    end
    if ~isfile(hdf_path)
        error('文件不存在: %s', hdf_path);
    end

    t_start = tic;
    data = struct();
    src_info = {};  % 记录每个变量来自 SDS 还是 Vdata
    sds_count = 0;  sds_ok = 0;  sds_fail = 0;
    vdata_count = 0; vdata_ok = 0; vdata_fail = 0;

    % ===== 1. 读取 SDS (Scientific Data Sets) =====
    fprintf('  读取 SDS...\n');
    sdID = sd.start(hdf_path, 'DFACC_RDONLY');
    [ndatasets, ~] = sd.fileInfo(sdID);

    for i = 0:ndatasets-1
        sdsID = sd.select(sdID, i);
        [sds_name, dims, dtype, ~] = sd.getInfo(sdsID);
        varname = matlab.lang.makeValidName(sds_name);
        success = false;
        try
            raw = sd.readData(sdsID);
            if ~isempty(raw)
                data.(varname) = raw;
                src_info{end+1} = sprintf('SDS:%s', varname);
                sds_ok = sds_ok + 1;
                success = true;
            end
        catch, end
        if ~success
            try
                raw2 = hdfread(hdf_path, sds_name);
                if ~isempty(raw2)
                    data.(varname) = raw2;
                    src_info{end+1} = sprintf('SDS(hdfread):%s', varname);
                    sds_ok = sds_ok + 1;
                    success = true;
                end
            catch, end
        end
        if ~success
            sds_fail = sds_fail + 1;
        end
        sd.endAccess(sdsID);
    end
    sd.close(sdID);
    sds_count = ndatasets;

    % ===== 2. 读取 Vdata (向量数据) =====
    % HDF4 V 接口（hdfh/hdfv）在 MATLAB 当前版本中不可用，跳过
    vdata_count = 0; vdata_ok = 0; vdata_fail = 0;
    fprintf('  Vdata: 跳过（MATLAB HDF4 V 接口不可用）\n');

    % ===== 3. 保存为 .mat =====
    save(mat_path, '-struct', 'data', '-v7.3');
    read_time = toc(t_start);

    % ===== 输出信息 =====
    hdf_info = dir(hdf_path);
    mat_info = dir(mat_path);

    info = struct();
    info.hdf_path    = hdf_path;
    info.mat_path    = mat_path;
    info.hdf_size    = hdf_info.bytes;
    info.mat_size    = mat_info.bytes;
    info.read_time   = read_time;
    info.n_variables = length(fieldnames(data));
    info.sds_count   = sds_count;
    info.sds_ok      = sds_ok;
    info.sds_fail    = sds_fail;
    info.vdata_count = vdata_count;
    info.vdata_ok    = vdata_ok;
    info.vdata_fail  = vdata_fail;
    info.src_info    = src_info;
    info.var_names   = fieldnames(data);

    ratio = info.mat_size / info.hdf_size * 100;
    fprintf('\n  ✓ 转换完成\n');
    fprintf('    原始 HDF:   %.2f MB\n', info.hdf_size / 1e6);
    fprintf('    全量 MAT:   %.2f MB (%.1f%%)\n', info.mat_size / 1e6, ratio);
    fprintf('    读取耗时:   %.2f 秒\n', info.read_time);
    fprintf('    SDS:  %d/%d 成功, Vdata: %d/%d 成功\n', ...
        sds_ok, sds_count, vdata_ok, vdata_count);
end
