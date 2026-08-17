function db_update(filename, field, value)
% DB_UPDATE  更新某条记录的某个字段
%
% 用法:
%   db_update('CAL...hdf', 'verify_status', 'pass');
%   db_update('CAL...hdf', 'delete_status', 'deleted');

    idx = db_load();
    for i = 1:length(idx.entries)
        if strcmp(idx.entries(i).filename, filename)
            idx.entries(i).(field) = value;
            break;
        end
    end
    db_save(idx);
end
