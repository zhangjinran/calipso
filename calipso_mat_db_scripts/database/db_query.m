function results = db_query(varargin)
% DB_QUERY  条件查询 database_index
%
% 用法:
%   results = db_query();                              % 返回全部
%   results = db_query('date', '2007-01-01');          % 按日期筛选
%   results = db_query('product', '05kmAP');           % 按产品筛选
%   results = db_query('verify_status', 'fail');        % 按状态筛选
%   results = db_query('date', '2007-01-01', 'product', '05kmAP');  % 多条件

    idx = db_load();
    results = idx.entries;

    if nargin == 0
        return;
    end

    % 按 (field, value) 对筛选
    for k = 1:2:nargin
        field = varargin{k};
        value = varargin{k+1};
        mask = false(length(results), 1);
        for i = 1:length(results)
            if isfield(results(i), field) && ...
               strcmp(results(i).(field), value)
                mask(i) = true;
            end
        end
        results = results(mask);
    end
end
