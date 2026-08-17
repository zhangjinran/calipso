%% init_database.m
% 初始化 CALIPSO_MAT_DB：创建空的 database_index.mat
%
% 用法:
%   run('init_database.m')

fprintf('========================================================\n');
fprintf('  初始化 CALIPSO_MAT_DB\n');
fprintf('========================================================\n');

CFG = config();

% 检查目录结构
required_dirs = {
    fullfile(CFG.MAT_ROOT, 'data', '05kmAP');
    fullfile(CFG.MAT_ROOT, 'data', '05kmAL');
    fullfile(CFG.MAT_ROOT, 'data', 'VFM');
    fullfile(CFG.MAT_ROOT, 'database');
    fullfile(CFG.MAT_ROOT, 'logs', 'convert_log');
    fullfile(CFG.MAT_ROOT, 'logs', 'verify_log');
    fullfile(CFG.MAT_ROOT, 'logs', 'migration_report');
    fullfile(CFG.MAT_ROOT, 'logs', 'error_log');
};

all_ok = true;
for i = 1:length(required_dirs)
    if ~isfolder(required_dirs{i})
        fprintf('  ❌ 缺少目录: %s\n', required_dirs{i});
        all_ok = false;
    end
end

if ~all_ok
    error('请先创建缺失目录');
end
fprintf('  ✅ 目录结构完整\n');

% 创建空的 database_index.mat
idx = struct('entries', struct([]));
save(CFG.DB_PATH, 'idx');
fprintf('  ✅ database_index.mat 已创建: %s\n', CFG.DB_PATH);

% 验证
loaded = load(CFG.DB_PATH);
if isfield(loaded, 'idx') && isempty(loaded.idx.entries)
    fprintf('  ✅ 验证通过: 索引文件为空且可正常加载\n');
end

fprintf('\n========================================================\n');
fprintf('  初始化完成\n');
fprintf('========================================================\n');
