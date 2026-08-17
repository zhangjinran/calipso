function [is_new_interval, interval_key] = check_time_interval(current_date, last_interval, interval_type)
    % 功能：检查是否进入新的时间间隔
    % 输入：
    %   current_date - 当前日期时间 (datetime对象)
    %   last_interval - 上一个记录的时间间隔标识
    %   interval_type - 时间间隔类型 ('month', 'quarter', 'year', 'week', 'day')
    % 输出：
    %   is_new_interval - 是否进入新的时间间隔 (true/false)
    %   interval_key - 当前时间间隔标识
    
    % 根据间隔类型生成标识
    switch lower(interval_type)
        case 'month'
            interval_key = datestr(current_date, 'yyyy-mm');
        case 'quarter'
            q = ceil(month(current_date) / 3);
            interval_key = sprintf('%d-Q%d', year(current_date), q);
        case 'year'
            interval_key = datestr(current_date, 'yyyy');
        case 'week'
            interval_key = datestr(current_date, 'yyyy-ww');
        case 'day'
            interval_key = datestr(current_date, 'yyyy-mm-dd');
        otherwise
            error('不支持的时间间隔类型: %s', interval_type);
    end
    
    % 判断是否为新间隔
    if isempty(last_interval)
        is_new_interval = true;
    else
        is_new_interval = ~strcmp(interval_key, last_interval);
    end
end