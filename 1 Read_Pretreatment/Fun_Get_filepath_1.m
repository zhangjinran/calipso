function [Path] = Fun_Get_filepath(main_path,year_select)
% 此函数仅适用于在服务器上从相应类型的文件夹中提取相应年份的数据
% 输入信息：
% main_path:    主路径
% year_select:    需要读取的文件类型
% 输出信息：

%% START        
folder_1_content = dir(main_path);
for i = 1:length(folder_1_content)
    if str2num(folder_1_content(i).name) == year_select
        Path = strcat([main_path,'/',folder_1_content(i).name]);
    end 
end
end

