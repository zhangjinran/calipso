function logger(category, varargin)
% LOGGER  统一日志写入
%
% 输入:
%   category - 'convert' | 'verify' | 'delete' | 'error'
%   varargin - {date_str, product, status, detail}
%
% 用法:
%   logger('convert', '2007-01-01', '05kmAP', 'success', '29/29 files');

    CFG = config();
    log_dir = fullfile(CFG.LOG_DIR, [category, '_log']);

    % 按月分文件
    log_file = fullfile(log_dir, [datestr(now, 'yyyy_mm'), '.log']);

    % 组装日志行
    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    parts = [{timestamp}, varargin];
    line = strjoin(parts, ' | ');

    % 写入文件
    fid = fopen(log_file, 'a');
    if fid > 0
        fprintf(fid, '%s\n', line);
        fclose(fid);
    end

    % 同时输出到命令行
    fprintf('  [%s] %s\n', category, line);
end
