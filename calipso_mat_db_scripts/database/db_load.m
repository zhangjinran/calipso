function idx = db_load()
% DB_LOAD  加载 database_index.mat
%   返回 index 结构体。文件不存在时返回空结构。
%
% 用法:
%   idx = db_load();

    CFG = config();
    if isfile(CFG.DB_PATH)
        loaded = load(CFG.DB_PATH);
        if isfield(loaded, 'idx')
            idx = loaded.idx;
        else
            idx = struct('entries', struct([]));
        end
    else
        idx = struct('entries', struct([]));
        fprintf('  [db] database_index.mat 不存在，返回空索引\n');
    end
end
