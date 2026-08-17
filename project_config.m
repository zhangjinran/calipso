function cfg = project_config(project_root)
%PROJECT_CONFIG Central configuration for CALIPSO_Code_new.
%   Set CALIPSO_HDF_ROOT to override the default Z:\ data root.
if nargin < 1 || isempty(project_root)
    project_root = fileparts(mfilename('fullpath'));
end
cfg.project_root = project_root;
cfg.hdf_root = getenv('CALIPSO_HDF_ROOT');
if isempty(cfg.hdf_root)
    cfg.hdf_root = 'Z:\';
end
cfg.hdf_root = char(cfg.hdf_root);
if ~endsWith(cfg.hdf_root, filesep)
    cfg.hdf_root = [cfg.hdf_root, filesep];
end
cfg.china_shp = fullfile(project_root, char([20013 21326 20154 27665 20849 21644 22269]), ...
    [char([20013 21326 20154 27665 20849 21644 22269]) '.shp']);
cfg.result_root = fullfile(project_root, 'result');
end
