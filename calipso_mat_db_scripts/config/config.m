function CFG = config()
% CONFIG  CALIPSO_MAT_DB 全局配置
%   所有脚本通过 CFG = config() 获取配置，不硬编码路径。
%
% 用法:
%   CFG = config();
%   hdf_path = fullfile(CFG.HDF_ROOT, '05kmAP', '2007', '2007_01_01');

    CFG = struct();

    % === 数据路径 ===
    CFG.HDF_ROOT     = 'Z:\';
    CFG.MAT_ROOT     = 'Z:\CALIPSO_MAT_DB';

    % === 产品类型 ===
    CFG.PRODUCTS     = {'05kmAP', '05kmAL', 'VFM'};

    % === 数据年份范围 ===
    CFG.YEARS        = 2007:2022;

    % === 日志目录 ===
    CFG.LOG_DIR      = fullfile(CFG.MAT_ROOT, 'logs');

    % === 数据库文件 ===
    CFG.DB_PATH      = fullfile(CFG.MAT_ROOT, 'database', 'database_index.mat');

    % === HDF 目录格式 ===
    CFG.HDF_DIR_FMT  = @(p, y, d) fullfile(CFG.HDF_ROOT, p, num2str(y), d);

    % === MAT 输出路径格式 ===
    CFG.MAT_PATH_FMT = @(p, y, d) fullfile( ...
        CFG.MAT_ROOT, 'data', p, num2str(y), [d, '.mat']);
end
