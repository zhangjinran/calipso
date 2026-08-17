function plot_grid_block( ...
    data_block, ...
    lon_centers, lat_centers, ...
    lon_edges, lat_edges, ...
    china_shp, ...
    title_name, ...
    colorbar_label, ...
    clim_limits)

%% 检查维度

if size(data_block,1) ~= length(lat_centers) || ...
   size(data_block,2) ~= length(lon_centers)

    error('data_block 尺寸与经纬度中心点不一致');
end

%% 经纬网格

[LON, LAT] = meshgrid(lon_centers, lat_centers);

%% 中国区域 mask

in_china = false(size(LON));

for k = 1:length(china_shp)

    xv = china_shp(k).X;
    yv = china_shp(k).Y;

    valid_poly = ~(isnan(xv) | isnan(yv));

    xv = xv(valid_poly);
    yv = yv(valid_poly);

    if numel(xv) < 3
        continue
    end

    in = inpolygon(LON, LAT, xv, yv);

    in_china = in_china | in;

end

%% mask 境外区域

plot_block = data_block;
plot_block(~in_china) = NaN;

%% 绘图

figure('Position',[100 100 900 700])

pcolor(lon_edges, lat_edges, ...
    padarray(plot_block,[1 1],NaN,'post'));

shading flat

hold on

%% 国界

for k = 1:length(china_shp)

    plot(china_shp(k).X, china_shp(k).Y, ...
        'k-', 'LineWidth',1.2);

end

%% 美化

colormap(parula)

c = colorbar;
c.Label.String = colorbar_label;
c.Label.FontSize = 12;

clim(clim_limits)

xlim([70 136])
ylim([0 56])

xlabel('经度 (°E)','FontSize',13)
ylabel('纬度 (°N)','FontSize',13)

title(title_name,'FontSize',14)

set(gca,'FontName','Microsoft YaHei')

grid off
box on

% 保存图片
global SAVE_PATH
if ~isempty(SAVE_PATH)
    fname = strrep(title_name, ' ', '_');
    fname = strrep(fname, '°', '');
    save_figure_png(gcf, [fname, '.png']);
end
