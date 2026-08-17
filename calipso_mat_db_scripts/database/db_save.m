function db_save(idx)
% DB_SAVE  保存 database_index.mat
%
% 用法:
%   db_save(idx);

    CFG = config();
    save(CFG.DB_PATH, 'idx');
end
