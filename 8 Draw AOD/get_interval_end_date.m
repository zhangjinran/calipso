function end_date = get_interval_end_date(interval_key, interval_type)
    % 功能：根据间隔标识和类型生成该间隔的最后一天日期
    % 输入：
    %   interval_key - 时间间隔标识
    %   interval_type - 时间间隔类型 ('month', 'quarter', 'year', 'week', 'day')
    % 输出：
    %   end_date - 该间隔的最后一天日期 (datetime对象)
    
    switch lower(interval_type)
        case 'month'
            % 格式: 'yyyy-mm'
            parts = strsplit(interval_key, '-');
            year_val = str2double(parts{1});
            month_val = str2double(parts{2});
            end_date = datetime(year_val, month_val, 1) + calmonths(1) - days(1);
            
        case 'quarter'
            % 格式: 'yyyy-Qn'
            year_val = str2double(interval_key(1:4));
            q = str2double(interval_key(end));
            month_val = q * 3;
            end_date = datetime(year_val, month_val, 1) + calmonths(1) - days(1);
            
        case 'year'
            % 格式: 'yyyy'
            year_val = str2double(interval_key);
            end_date = datetime(year_val, 12, 31);
            
        case 'week'
            % 格式: 'yyyy-ww'
            parts = strsplit(interval_key, '-');
            year_val = str2double(parts{1});
            week_val = str2double(parts{2});
            end_date = datetime(year_val, 1, 1) + weeks(week_val - 1) + days(6);
            
        case 'day'
            % 格式: 'yyyy-mm-dd'
            end_date = datetime(interval_key, 'InputFormat', 'yyyy-MM-dd');
            
        otherwise
            error('不支持的时间间隔类型: %s', interval_type);
    end
end