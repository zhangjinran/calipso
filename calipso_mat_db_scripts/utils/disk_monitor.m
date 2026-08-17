function enough = disk_monitor(mode, estimated_bytes)
% DISK_MONITOR  磁盘空间监控
%
% 输入:
%   mode            - 'pre': 转换前检查空间
%                   - 'post': 转换后记录空间
%   estimated_bytes - 预计需要的字节数
%
% 输出:
%   enough          - true/false

    CFG = config();
    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    log_file = fullfile(CFG.LOG_DIR, 'disk_space.log');

    % 获取 Z 盘剩余空间（通过 Java 接口）
    try
        f = java.io.File(CFG.HDF_ROOT);
        free_bytes = f.getFreeSpace();
        total_bytes = f.getTotalSpace();
        free_gb = free_bytes / 1e9;
        total_gb = total_bytes / 1e9;
        have_disk = true;
    catch
        free_gb = NaN;
        total_gb = NaN;
        have_disk = false;
    end

    switch mode
        case 'pre'
            if have_disk && estimated_bytes > 0
                enough = free_bytes > estimated_bytes * 1.2;  % 留 20% 余量
                line = sprintf('%s | PRE  | 剩余 %.1f GB | 需要 %.1f GB | %s', ...
                    timestamp, free_gb, estimated_bytes/1e9, ...
                    ternary(enough, '通过', '空间不足'));
                if ~enough
                    fprintf('  [disk] ⚠ 空间不足: 剩余 %.1f GB\n', free_gb);
                end
            else
                enough = true;
                line = sprintf('%s | PRE  | 跳过检查', timestamp);
            end

        case 'post'
            if have_disk
                line = sprintf('%s | POST | 可用 %.1f / %.1f GB', ...
                    timestamp, free_gb, total_gb);
                fprintf('  [disk] 可用 %.1f / %.1f GB\n', free_gb, total_gb);
            else
                line = sprintf('%s | POST | 无法获取磁盘信息', timestamp);
            end
            enough = true;

        otherwise
            error('未知模式: %s', mode);
    end

    fid = fopen(log_file, 'a');
    if fid > 0
        fprintf(fid, '%s\n', line);
        fclose(fid);
    end
end

function s = ternary(cond, t, f)
    if cond, s = t; else, s = f; end
end
