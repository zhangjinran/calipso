function output_file = save_figure_png(fig_handle, file_name)
%SAVE_FIGURE_PNG Save a figure under global SAVE_PATH IMAGE_SAVE_PATH and verify it.
global SAVE_PATH IMAGE_SAVE_PATH
if nargin < 1 || isempty(fig_handle) || ~isgraphics(fig_handle, 'figure')
    error('save_figure_png:InvalidFigure', 'The supplied figure handle is invalid.');
end
if nargin < 2 || isempty(file_name)
    error('save_figure_png:InvalidName', 'A non-empty output file name is required.');
end
if isempty(IMAGE_SAVE_PATH), IMAGE_SAVE_PATH = SAVE_PATH; end
if isempty(IMAGE_SAVE_PATH)
    error('save_figure_png:EmptyPath', 'SAVE_PATH is empty. Set it before plotting.');
end
if ~exist(IMAGE_SAVE_PATH, 'dir')
    [ok, msg] = mkdir(IMAGE_SAVE_PATH);
    if ~ok, error('save_figure_png:CreateDirectoryFailed', 'Cannot create output directory "%s": %s', IMAGE_SAVE_PATH, msg); end
end
[~, ~, ext] = fileparts(file_name);
if isempty(ext), file_name = [file_name, '.png']; end
output_file = fullfile(IMAGE_SAVE_PATH, file_name);
drawnow;
try
    if exist('exportgraphics', 'file') == 2
        exportgraphics(fig_handle, output_file, 'Resolution', 150);
    else
        saveas(fig_handle, output_file);
    end
catch ME
    error('save_figure_png:SaveFailed', 'Failed to save figure to "%s": %s', output_file, ME.message);
end
if ~isfile(output_file)
    error('save_figure_png:VerificationFailed', 'Image was not found at "%s" after saving.', output_file);
end
fprintf('[figure] saved: %s\n', output_file);
end

