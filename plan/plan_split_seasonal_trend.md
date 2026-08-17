# 季节空间趋势 + 点击出折线图 修改方案（V3 — 终版）

## 改动范围

只改 **`8 Draw AOD/plot_spatial_trend.m`** 一个文件。
`ts_run_analysis.m` 和函数签名**完全不动**。

---

## 实现流程

### 第一遍：计算全部 slope + p 值

```matlab
slope_maps = NaN(nlat, nlon, 4);
p_maps     = NaN(nlat, nlon, 4);

for s = 1:4
    idx = (月份属于该季度);
    season_data = data_3d(:, :, idx);
    season_years = year(dates(idx));
    unique_years = unique(season_years);

    for 每个格点
        % 按年求季度均值
        for y = 1:length(unique_years)
            yr_idx = (season_years == unique_years(y));
            q_values = season_data(ilat, ilon, yr_idx);
            q_mean(y) = mean(q_values(~isnan(q_values)));
        end

        % 有效样本 ≥ 5 才做回归
        valid = ~isnan(q_mean);
        if sum(valid) >= 5
            mdl = fitlm(unique_years(valid), q_mean(valid));
            slope_maps(ilat, ilon, s) = mdl.Coefficients.Estimate(2);
            p_maps(ilat, ilon, s)     = mdl.Coefficients.pValue(2);
        end
    end
end

% 全局色标范围
max_abs = max(abs(slope_maps(:)));
```

### 第二遍：绘图

```matlab
figure('Position', [100 100 1200 900]);

for s = 1:4
    subplot(2,2,s);

    trend_s = slope_maps(:, :, s);
    trend_s(~in_china) = NaN;

    h = pcolor(lon_edges, lat_edges, padarray(trend_s, [1 1], NaN, 'post'));
    shading flat;  hold on;

    % 中国国界
    for k = 1:length(china_shp)
        plot(china_shp(k).X, china_shp(k).Y, 'k-', 'LineWidth', 1.2);
    end

    % p<0.05 显著性点（用 scatter，不用 find->索引的易错写法）
    sig_mask = p_maps(:, :, s) < 0.05 & ~isnan(trend_s);
    [LonG, LatG] = meshgrid(lon_centers, lat_centers);
    scatter(LonG(sig_mask), LatG(sig_mask), 5, 'k', 'filled');

    clim([-max_abs, max_abs]);
    title(sprintf('Q%d', s), 'FontSize', 14);

    % 存储回调数据 → pcolor Surface 对象的 UserData
    ud.lon_centers  = lon_centers;
    ud.lat_centers  = lat_centers;
    ud.lon_edges    = lon_edges;
    ud.lat_edges    = lat_edges;
    ud.slope_map    = trend_s;
    ud.p_map        = p_maps(:, :, s);
    ud.season_data  = data_3d(:, :, idx);   % 该季度全部数据
    ud.season_dates = dates(idx);           % 该季度时间戳
    ud.quarter      = s;
    ud.china_shp    = china_shp;
    ud.data_name    = data_name;
    set(h, 'ButtonDownFcn', @on_click, 'PickableParts', 'all');
end

% 全局 colorbar
colormap(flipud(jet));
cb = colorbar('Position', [0.92 0.15 0.02 0.7]);
cb.Label.String = '趋势斜率 (/year)';
cb.Label.FontSize = 12;
```

### 点击回调

```matlab
function on_click(src, ~)
    ud = get(src, 'UserData');

    % 获取鼠标点击位置
    pt = get(gca, 'CurrentPoint');
    click_lon = pt(1,1);
    click_lat = pt(1,2);

    % 映射到最近网格
    [~, ilon] = min(abs(ud.lon_centers - click_lon));
    [~, ilat] = min(abs(ud.lat_centers - click_lat));

    % 提取该格点的季度时间序列
    vals = squeeze(ud.season_data(ilat, ilon, :));
    sdates = ud.season_dates;
    years = year(sdates);
    unique_years = unique(years);

    % 按年求季度均值
    q_mean = NaN(length(unique_years), 1);
    for y = 1:length(unique_years)
        yr_idx = (years == unique_years(y));
        v = vals(yr_idx);
        q_mean(y) = mean(v(~isnan(v)));
    end

    valid = ~isnan(q_mean);

    if sum(valid) < 5
        warning('有效年份不足5，无法拟合');
        return;
    end

    mdl = fitlm(unique_years(valid), q_mean(valid));
    slope = mdl.Coefficients.Estimate(2);
    pval  = mdl.Coefficients.pValue(2);

    % 新图窗
    figure('Position', [400 400 700 450]);
    plot(unique_years(valid), q_mean(valid), 'bo', 'MarkerSize', 6);
    hold on;

    % 趋势线
    x_fit = linspace(min(unique_years(valid)), max(unique_years(valid)), 100);
    y_fit = predict(mdl, x_fit');
    plot(x_fit, y_fit, 'r-', 'LineWidth', 2);

    xlabel('年份', 'FontSize', 13, 'FontName', 'Microsoft YaHei');
    ylabel(ud.data_name, 'FontSize', 13, 'FontName', 'Microsoft YaHei');
    title(sprintf('Q%d (%.1f°E, %.1f°N)  Slope=%.4f/yr  p=%.3f  N=%d', ...
        ud.quarter, ud.lon_centers(ilon), ud.lat_centers(ilat), ...
        slope, pval, sum(valid)), ...
        'FontSize', 14, 'FontName', 'Microsoft YaHei');
    grid on; box on;
end
```

---

## 关键陷阱（方案层面已解决）

| 问题 | 解决方案 |
|------|---------|
| 点击 pcolor 无响应 | `ButtonDownFcn` 挂到 **Surface 对象**（不是 axes），加 `PickableParts='all'` |
| `find` 返回行列索引而非经纬度 | 改用 `[LonG, LatG] = meshgrid + scatter(LonG(sig_mask), LatG(sig_mask))` |
| `fitlm` 遇 NaN 报错 | `valid = ~isnan(q_mean)` + `sum(valid) >= 5` 门槛 |
| 各子图色标范围不一致无法比较 | **两遍流程**：先算完所有 slope_maps，统一 `max_abs`，再绘图 |
| 同一年重复采样 | 先按年**求季度均值**，再回归 |
| 点击折线图横坐标重叠 | 画的是 **年度季度均值** 而非月份散点 |

---

## 文件修改清单

| 文件 | 改动 |
|------|------|
| `plot_spatial_trend.m` | 全部重写 |
| `ts_run_analysis.m` | **不改** |
| 其他文件 | **不改** |
