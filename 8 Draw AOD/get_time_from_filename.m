function [datetime_val, year, month] = get_time_from_filename(filename)
    % 功能：从CALIPSO文件名中提取时间信息
    % 输入：filename - CALIPSO数据文件名
    % 输出：datetime_val - MATLAB datetime对象
    %       year - 年份（整数）
    %       month - 月份（整数）
    % 文件名格式示例：CAL_LID_L2_05kmALay-Standard-V4-20.2020-06-01T19-01-45ZN_Subset.hdf
    
    % 查找时间戳部分（格式：YYYY-MM-DDTHH-MM-SS）
    % 使用正则表达式匹配日期时间模式
    pattern = '(\d{4})-(\d{2})-(\d{2})T(\d{2})-(\d{2})-(\d{2})';
    matches = regexp(filename, pattern, 'tokens');
    
    if ~isempty(matches) && ~isempty(matches{1})
        % 提取时间分量
        year_str = matches{1}{1};
        month_str = matches{1}{2};
        day_str = matches{1}{3};
        hour_str = matches{1}{4};
        minute_str = matches{1}{5};
        second_str = matches{1}{6};
        
        % 转换为数值
        year = str2double(year_str);
        month = str2double(month_str);
        day = str2double(day_str);
        hour = str2double(hour_str);
        minute = str2double(minute_str);
        second = str2double(second_str);
        
        % 创建datetime对象
        datetime_val = datetime(year, month, day, hour, minute, second);
    else
        % 如果无法解析，返回NaN
        datetime_val = NaT;
        year = NaN;
        month = NaN;
    end
end