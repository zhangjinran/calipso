function [is_new_month, month_key] = check_month_interval(current_date, last_month)
    % 功能：检查是否进入新的月份
    % 输入：
    %   current_date - 当前日期时间 (datetime对象)
    %   last_month - 上一个记录的月份标识 (如 '2020-06')
    % 输出：
    %   is_new_month - 是否是新月份 (true/false)
    %   month_key - 当前月份标识 (如 '2020-06')
    
    % 生成当前月份标识
    month_key = datestr(current_date, 'yyyy-mm');
    
    % 判断是否为新月份
    if isempty(last_month)
        is_new_month = true;
    else
        is_new_month = ~strcmp(month_key, last_month);
    end
end