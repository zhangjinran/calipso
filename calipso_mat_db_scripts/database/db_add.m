function db_add(record)
% DB_ADD  添加一条新记录到 database_index
%   record 包含: filename, date, product, mat_path, file_index,
%                convert_status, verify_status, main_test_status, delete_status
%
% 用法:
%   record.filename = 'CAL...hdf';
%   record.date = '2007-01-01';
%   db_add(record);

    idx = db_load();
    n = length(idx.entries);
    if n == 0
        idx.entries = record;
    else
        idx.entries(n+1) = record;
    end
    db_save(idx);
end
