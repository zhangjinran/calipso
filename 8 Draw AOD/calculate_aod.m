function [aod_block, cnt_block] = calculate_aod(surface_mask,ALay_05km, aod_block, cnt_block, lon_edges, lat_edges)
    % 功能：每次加入新的 ALay 数据，自动更新为【当前均值】
    % aod_block 永远保持为【均值】，不是总和！

    %% 1. 取出经纬度 & AOD
    lon = ALay_05km.Lon(:, 2);
    lat = ALay_05km.Lat(:, 2);

    % 取出 AOD
    taod = ALay_05km.Column_TAOD_532;
    %fprintf('掩膜过滤前：%d 条数据\n',  sum(~isnan(taod))); % 加这句
    taod(surface_mask == 0) = NaN;

   
    %fprintf('过滤后（有效地表）：%d 条\n', sum(~isnan(taod))); % 加这句



    %% 2. 有效数据筛选
    valid = taod > 0 & ~isnan(taod);
    lon = lon(valid);
    lat = lat(valid);
    taod = taod(valid);

    if isempty(lon)
        return;
    end

    %% 3. 定位网格
    lon_min = lon_edges(1);
    lat_min = lat_edges(1);
    ilon = floor(lon - lon_min) + 1;
    ilat = floor(lat - lat_min) + 1;

    nlat = size(aod_block, 1);
    nlon = size(aod_block, 2);

    %% 4. 逐个点更新【均值】
    for i = 1:length(lon)
        x = ilon(i);
        y = ilat(i);

        if x >= 1 && x <= nlon && y >= 1 && y <= nlat
            old_mean = aod_block(y, x);   % 当前均值
            old_cnt  = cnt_block(y, x);   % 当前点数
            new_val  = taod(i);           % 新来的值
          
            % 核心公式：在线更新均值
            aod_block(y, x) = (old_mean * old_cnt + new_val) / (old_cnt + 1);
            cnt_block(y, x) = old_cnt + 1;  % 点数+1
        end
    end
end
