function Fun_Layer_Plot(Lat,Lidar_Data_Altitudes,TAB_532,topbin_under80km,basebin_under80km,title_name)

%% ================== 1. 数据预处理（统一处理，给两张图用）==================
% 获取颜色表
[rgb colors_532 color_bar, color_bar_labels] = kathys_lidar_colors('useGrayScale');
data = TAB_532;

lat = Lat;

% 把 NaN 替换成 -9999
for i = 1:size(data,1)
    for j = 1:size(data,2)
        if isnan(data(i,j)) 
            data(i,j) = -9999;
        end 
    end
end

% 尺寸信息
nAlt = size(data,1);
nProf = size(data,2);
profile_num = 1:nProf;
alt_bin_num = 1:nAlt;
out_img = zeros(nAlt,nProf,3,'uint16');

% 生成 TAB 伪彩色图（两张图都用这张图）
for ic=1:nProf
    tmp = floor(data(:,ic) / 1.0e-4);
    neg_mask = (data(:,ic) > 1.0e-4);
    tmp = neg_mask .* tmp + (~neg_mask) * 1;
    over_mask = (data(:,ic) < 0.1);
    tmp = over_mask .* tmp + (~over_mask) * 1001;

    tmp = colors_532(tmp);
    out_img(:,ic,1) = uint16(rgb(tmp,1)/255*65535);
    out_img(:,ic,2) = uint16(rgb(tmp,2)/255*65535);
    out_img(:,ic,3) = uint16(rgb(tmp,3)/255*65535);
end

%% ================== 2. 画图参数设置 ==================
myfontsize = 16;
hori = 0.08;
verti = 0.08;
clim = ([-5e-3,1e-1]/3);

% 创建画布
figure('color','w','unit','normalized','position',[0.1,0.1,0.63,0.45]);
clf;

%% ================== 3. 绘制第一张图：伪彩图（左图）==================
posi = [0.06, 0.14, 0.8, 0.78];  % 左图位置
ax1 = subplot('position', posi);

% 画伪彩图
imagesc(profile_num, alt_bin_num, out_img);
hold on;

% 设置 X 轴（纬度）
set(gca,'xtick',[1:(size(lat,1))/5:size(lat,1), size(lat,1)-1]);
xx = get(gca,'XTick');
cc = char(sprintf('%5.2f',lat(round(xx(1)))));
for j=2:length(xx)
    cc = char(cc, sprintf('%5.2f', lat(round(xx(j)))));
end
set(gca,'XTickLabel', cc);

% 设置 Y 轴（高度）
set(gca,'ytick',[1:(size(Lidar_Data_Altitudes,1))/5:size(Lidar_Data_Altitudes,1), size(Lidar_Data_Altitudes,1)-1]);
yy = get(gca,'YTick');
dd = char(sprintf('%5.2f', Lidar_Data_Altitudes(yy(1))));
for j=2:length(yy)
    dd = char(dd, sprintf('%5.2f', Lidar_Data_Altitudes(round(yy(j)))));
end
set(gca,'YTickLabel', dd);

% 坐标轴与标题
ylabel('Altitude (km)');
xlabel('Latitude (°N)');
set(gca,'FontSize', myfontsize-2, 'FontWeight', 'bold');

title(title_name, 'fontsize', myfontsize, 'FontWeight', 'bold');

% 色标
cb = lidar_colorbar(rgb, color_bar, color_bar_labels, 'vert');
posi_cb = get(cb, 'position');
posi_cb(1) = posi_cb(1)-0.01;
posi_cb(3) = posi_cb(3)*0.4;
set(cb, 'position', posi_cb);

% 左上角 (a) 标记
text('Units','normalized','Position',[0.02,0.96],'String','(a)',...
    'color','w','FontWeight','bold','fontsize',myfontsize+2);

end
