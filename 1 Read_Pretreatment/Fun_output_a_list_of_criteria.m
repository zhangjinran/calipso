function [File_select,int] = Fun_output_a_list_of_criteria_1(file_year_path,year_select,date_lim,day_night_flag,lon_lim,lat_lim)
% 该函数主要用于输出满足条件的文件列表。
% 输入信息：
% file_year_path：       文件路径各产品数据的上一级
% year_select：     选取哪一年份的数据
% date_lim：        日期限制
% day_night_flag：  昼夜标志限制
% lon_lim：         经度限制
% lat_lim：         纬度限制
% 输出信息：
% File_select：    元胞数组个数代表有几个文件符合要求，元胞数组内的结构体代表每个已选择的文件路径类型等信息
%% START

% ================ 关键修改：定义类型名映射（解决数字开头字段问题） ================
% 原始数据类型+优先级（顺序严格对齐）
% 按优先级1,2,6,7,4,5重新排序后的定义
data_type_priority = {1,2,6,7,4,5};
data_type_original = {'05kmAL','05kmCL','L1','VFM','05kmCP','05kmAP'};
data_type_norm = {'d_05kmAL','d_05kmCL','L1','VFM','d_05kmCP','d_05kmAP'};
% 创建原始名→规范名的映射字典
type_map = containers.Map(data_type_original, data_type_norm);
statistic=struct();%存储各种统计量。
statistic.sum=0;
statistic.select=0;
statistic.removed=0;
int = 0;
File_select = {}; % 初始化输出元胞数组
for(m=1:length(year_select))

% ================ 初始化结构体（拆分路径/文件列表/标志位） ================
data_struct.folder_path = struct(); % 存储各类型文件夹路径
data_struct.file_year_path = struct();   % 存储各类型文件路径
data_struct.file_date_path= struct();
data_struct.file_list = struct();   % 存储各类型dir结果
data_struct.flag = struct();        % 存储各类型匹配标志位
data_struct.filename = struct();    % 存储各类型匹配文件名
data_struct.filepath = struct(); 



% 初始化所有字段
for j = 1:length(data_type_original)
    type_ori = data_type_original{j};
    type_norm = type_map(type_ori);
    data_struct.folder_path.(type_norm) = '';
    data_struct.file_year_path.(type_norm) = '';
    data_struct.file_list.(type_norm) = [];
    data_struct.flag.(type_norm) = 0;
    data_struct.filename.(type_norm) = '';

     data_struct.filepath.(type_norm) = '';
    
end 

% ================ 遍历主文件夹，匹配各类型文件夹路径 ================

folder_info = dir(file_year_path);
for i = 1:length(folder_info)
    % 跳过.和..文件夹
    if folder_info(i).isdir && ~strcmp(folder_info(i).name,'.') && ~strcmp(folder_info(i).name,'..')
        for j = 1:length(data_type_original)
            type_ori = data_type_original{j};
            type_norm = type_map(type_ori);
            if ~isempty(strfind(folder_info(i).name, type_ori))
                data_struct.folder_path.(type_norm) = [file_year_path,folder_info(i).name];
                break;
            end
        end
    end
end

% ================ 确定各类型文件路径（调用Fun_Get_filepath） ================
for j=1:length(data_type_original)
    type_ori = data_type_original{j};
    type_norm = type_map(type_ori);
    data_struct.flag.(type_norm) = 0;
    if ~isempty(data_struct.folder_path.(type_norm))
        data_struct.file_year_path.(type_norm) = Fun_Get_filepath(data_struct.folder_path.(type_norm), year_select(m));
        % 读取各类型HDF文件列表
        data_struct.file_list.(type_norm) = dir([data_struct.file_year_path.(type_norm),'\*.hdf']);
        if isempty(data_struct.file_list.(type_norm))
           
           data_struct.file_date_path.(type_norm)=dir([data_struct.file_year_path.(type_norm),'\*']);
           %disp(dir([data_struct.file_year_path.(type_norm),'\*']));
           %disp(class(data_struct.file_date_path.(type_norm)(1).name));
          % 先用元胞收集所有 dir 结果（不拼接，超快）
            tempCells = {};
            for i=1:size(data_struct.file_date_path.(type_norm))
                if contains(data_struct.file_date_path.(type_norm)(i).name, '.')
                    continue;
                end
                folderFullPath = fullfile(...
                    data_struct.file_year_path.(type_norm),...
                    data_struct.file_date_path.(type_norm)(i).name,...
                    '*.hdf'...
                );
                d = dir(folderFullPath);
                tempCells{end+1} = d;  % 元胞追加，不占内存
            end
            
            % 最后一次性垂直拼接（只做1次，极快）
            data_struct.file_list.(type_norm) = vertcat(tempCells{:});

            
        end
    end

% ================ 转换时间限制为序列号 ================
a         = num2str(date_lim(1));
b         = num2str(date_lim(2));
time_type = {'yyyy','yyyymm','yyyymmdd','yyyymmddHH','yyyymmddHHMM','yyyymmddHHMMSS'};
datelim_start = [];
datelim_end = [];
for ord_num = 1: size(time_type,2)
    if length(time_type{ord_num}) == length(a)
        datelim_start = datenum(a,time_type{ord_num});
        datelim_end   = datenum(b,time_type{ord_num});
        break;
    end
end
% 时间格式匹配失败的容错
if isempty(datelim_start) || isempty(datelim_end)
    error('日期格式不匹配，请检查date_lim的格式');
end

% ================ 遍历05kmAL文件，筛选符合条件的文件 ================
% 获取L1文件列表（规范化字段名L1）
folder_temp = data_struct.file_list.d_05kmAL;


for iii = 1:size(folder_temp,1)
    %判断一下输出的文件次数
    statistic.sum=1+statistic.sum;
    % 重置所有类型的匹配标志位
    for j=1:length(data_type_original)
        type_norm = type_map(data_type_original{j});
        data_struct.flag.(type_norm) = 0;
        data_struct.filename.(type_norm) = '';
    end

    % 提取L1文件名和时间信息
    fileName1 = folder_temp(iii).name;
    indTime = strfind(fileName1,'.');
    if length(indTime) < 2 % 时间片段不完整，跳过
        %判断一下输出的文件次数
        statistic.removed=1+statistic.removed;
        continue;
    end
    fileTime1 = fileName1(indTime(1):indTime(2));
    
    % 提取昼夜标志（防索引越界）
    if length(fileTime1) < 22
        statistic.removed=1+statistic.removed;
        continue;
    end
    DayOrNight = fileTime1(22);
    
    % 转换时间为序列号
    digit_indices = regexp(fileTime1,'\d');
    if isempty(digit_indices) % 无数字时间，跳过
        statistic.removed=1+statistic.removed;
        continue;
    end
    %disp(fileTime1);
    
    timeNum = datenum(fileTime1(digit_indices),'yyyymmddHHMMSS');
    dayNum=datestr(timeNum,'yyyy_mm_dd');
    %disp(dayNum);
    Lon=[]; 
    Lat=[];
   
    %disp(timeNum)
    % 时间筛选：超过结束时间则跳过（修正break→continue）
    if timeNum > datelim_end
        statistic.removed=1+statistic.removed;
        continue;
    end
    %筛选合适的年份路径。
    
   
    for j=1:length(data_struct.file_date_path.d_05kmAL)
        if length(data_struct.file_date_path.d_05kmAL(j).name)<3
            continue;
        end
        %disp(data_struct.file_date_path.d_05kmAL(j).name);
        if dayNum==data_struct.file_date_path.d_05kmAL(j).name
            file_date_path=dayNum;
            break;
        else
            continue;
        end
    end
    if length(file_date_path)<3
        statistic.removed=1+statistic.removed;
        continue;
    end
        
        filepath_temp=folder_temp(iii).folder;
       

    % 读取经纬度数据（容错）
        try
           
            Lon = [Lon;double(hdfread(fullfile(filepath_temp,fileName1),'/Longitude'))];
           
            Lat = [Lat;double(hdfread(fullfile(filepath_temp,fileName1),'/Latitude'))];
           
        catch
            statistic.removed=1+statistic.removed;
            continue;
        end
    
    Lon = Lon(:,1) ;
    Lat = Lat(:,1) ;
    
    % 重排经纬度（自上至下递增）
    if Lon(1) > Lon(end)
        Lon = flipud(Lon);
    end
    if Lat(1) > Lat(end)
        Lat = flipud(Lat);
    end
   
    % 经纬度区间交集判断
    A = ceil(Lon(1)):floor(Lon(end));
    B = ceil(lon_lim(1)):ceil(lon_lim(2));
    C = ceil(Lat(1)):floor(Lat(end));
    D = ceil(lat_lim(1)):ceil(lat_lim(2));
    lon_intersect = intersect(A, B);
    lat_intersect = intersect(C, D);
    
    
    % 核心筛选条件：时间+昼夜+经纬度
    
    if (timeNum>=datelim_start && timeNum<=datelim_end) && ...
       (strcmpi(day_night_flag,'all') || strncmpi(day_night_flag,DayOrNight,1)) && ...
       ~isempty(lon_intersect) && ~isempty(lat_intersect)
       
        %disp('successfully select a file')
        statistic.select=1+statistic.select;
        % 匹配同时间戳的其他产品文件
        for j=1:length(data_type_original)
            type_ori = data_type_original{j};
            type_norm = type_map(type_ori);
            if ~isempty(data_struct.file_list.(type_norm))
                folder_info = data_struct.file_list.(type_norm);
                for ii = 1:size(folder_info,1)
                    fileName = folder_info(ii).name;
                    indTime2 = strfind(fileName,'.');
                    if length(indTime2) < 2
                        continue;
                    end
                    fileTime2 = fileName(indTime2(1):indTime2(2));
                    if strcmp(fileTime1,fileTime2)
                        data_struct.flag.(type_norm) = 1;
                        data_struct.filename.(type_norm) = fileName;
                        data_struct.filepath.(type_norm)=folder_info(ii).folder;
                        break;
                    end
                end
            end
        end
        
        % 组装输出结果（仅当有匹配类型时递增int）
        has_match = false;
        for j=1:length(data_type_original)
            if data_struct.flag.(type_map(data_type_original{j})) == 1
                has_match = true;
                break;
            end
        end
        
        if has_match
            int = int + 1;
            idx = 1;
            for j=1:length(data_type_original)
                type_ori = data_type_original{j};
                type_norm = type_map(type_ori);
                if data_struct.flag.(type_norm) == 1        
                    File_select{int}(idx).name = data_struct.filename.(type_norm);
                    File_select{int}(idx).filePath =data_struct.filepath.(type_norm);
                    disp(data_struct.filepath.(type_norm));
                    disp(folder_temp(iii).folder);
                    File_select{int}(idx).type = type_ori;
                    File_select{int}(idx).Field_priority = data_type_priority{j};
                    idx = idx + 1;
                end
            end
        end
    
    else
        %disp("Warning:this file can't be select.")
        statistic.removed=1+statistic.removed;
    end


end

end
end

%输出统计量。

    fprintf("The sum of the file:%g\n",statistic.sum);
    fprintf("The select of the file:%g\n",statistic.select);
    fprintf("The removed of the file:%g\n",statistic.removed);
