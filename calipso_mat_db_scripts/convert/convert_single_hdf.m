function data = convert_single_hdf(hdf_path)
% CONVERT_SINGLE_HDF  读取 1 个 HDF4 文件，返回 struct
%
% 输入:
%   hdf_path - HDF4 文件路径
%
% 输出:
%   data - struct，含 .filename, .Ext, .Back, .Depol, .AVD,
%                 .Lon, .Lat, .Time, .Alt 等全部 SDS 字段
%
% 核心逻辑从 hdf2mat_full.m（评估版）提取

    import matlab.io.hdf4.*

    [~, fname, ~] = fileparts(hdf_path);

    % 初始化输出
    data = struct();
    data.filename = [fname, '.hdf'];

    % 打开 HDF4 文件
    sdID = sd.start(hdf_path, 'DFACC_RDONLY');
    [ndatasets, ~] = sd.fileInfo(sdID);

    for i = 0:ndatasets-1
        sdsID = sd.select(sdID, i);
        [sds_name, ~, ds_dims, ~] = sd.getInfo(sdsID);
        varname = matlab.lang.makeValidName(sds_name);

        try
            raw = sd.readData(sdsID);
            % 与 readHDF 保持一致：二维数据转置
            if length(ds_dims) == 2
                data.(varname) = raw';
            else
                data.(varname) = raw;
            end
        catch
            % sd.readData 失败时用 hdfread 兜底
            try
                raw2 = hdfread(hdf_path, sds_name);
                if ~isempty(raw2)
                    data.(varname) = raw2;
                end
            catch
                % 跳过无法读取的字段
            end
        end
        sd.endAccess(sdsID);
    end
    sd.close(sdID);
end
