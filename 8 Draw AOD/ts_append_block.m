function ts = ts_append_block(ts, datetime_val, data_block)
    % 功能：向时间序列追加一个数据块
    % 输入：
    %   ts - 时间序列结构
    %   datetime_val - 时间戳 (datetime对象)
    %   data_block - 2D数据块 (nlat x nlon)
    % 输出：
    %   ts - 更新后的时间序列结构
    
    % 追加时间戳
    if isempty(ts.dates)
        ts.dates = datetime_val;
    else
        ts.dates = [ts.dates; datetime_val];
    end
    
    % 追加数据块
    if isempty(ts.data)
        ts.data = data_block;
    else
        ts.data = cat(3, ts.data, data_block);
    end
end