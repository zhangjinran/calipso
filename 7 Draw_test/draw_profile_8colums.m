function draw_profile_8colums(data_struct, Profile_Data, titlename)

%% 1. 读数据（Profile 专用）
Lat         = data_struct.Lat;                % 纬度 (1104条廓线)
Alt         =data_struct.Altitudes_Profile;    % 高度数组 (339层)
data        = Profile_Data;       % Profile 数据矩阵：339(高度) × 1104(廓线)

nProf = length(Lat);      % 廓线数量：1104
nAlt  = length(Alt);      % 高度层数：339
img   = permute(data,[2,1]);             % 直接使用原始 Profile 矩阵，不需要填充

%% 2. 数据预处理（和你风格一致）
img(img<-999) = NaN;        % 0 值转 NaN
min_val  = min(img(:),[],'omitnan');
img_data = img(~isnan(img));

if isempty(img_data)
    disp(titlename);
    disp('All data is NaN!!!!');
    return;
end

p95 = prctile(img_data,95);   % 颜色上限
p5  = prctile(img_data,5);    % 颜色下限

%% 避免所有值相同
if min_val == p95
    disp(titlename);
    disp('All values are the same!!!!');
    return;
end

%% ==============================================
%% 【第一步：完全用索引画图！】Profile 标准绘图
%% ==============================================
f = figure;
set(f,'Units','centimeters');
set(f,'Position',[5,5,90,10]);  % 保持和你一样的图大小

% 直接画 Profile 矩阵：高度 × 廓线
h = imagesc(1:nProf, 1:nAlt, img);  

%% ==============================================
%% 【第二步：画完再映射坐标！】和你风格一致
%% ==============================================
set(gca,'Position',[0.08,0.15,0.75,0.75]);
set(gca, 'XTickLabelMode','manual');
set(gca, 'YTickLabelMode','manual');
set(gca,'FontName','Arial','FontSize',20,'FontWeight','bold');

% 映射 X 轴 → 纬度
xt = get(gca,'XTick');
xt(xt < 1 | xt > nProf) = [];
xlbl = arrayfun(@(x) sprintf('%.2f', Lat(round(x))), xt, 'UniformOutput',false);
set(gca, 'XTick', xt, 'XTickLabel', xlbl);

% 映射 Y 轴 → 真实高度
yt = get(gca,'YTick');
yt(yt < 1 | yt > nAlt) = [];
ylbl = arrayfun(@(y) sprintf('%.0f', Alt(round(y))), yt, 'UniformOutput',false);
set(gca, 'YTick', yt, 'YTickLabel', ylbl);

% 高度轴方向：从上到下高度增加（CALIPSO 标准方向）
set(gca, 'YDir', 'reverse');  

%% 颜色（和你保持一样）
colormap jet;
img(img < 0) = NaN;
clim([p5, p95]);  

%% 标签、标题、色标（完全和你一致）
titleText = replace(titlename,'_',' ');

xlabel('Latitude','FontName','Arial','FontSize',20,'FontWeight','bold');
ylabel('Altitude (km)','FontName','Arial','FontSize',20,'FontWeight','bold');
cb = colorbar;
set(cb,'FontName','Arial','FontSize',20,'FontWeight','bold');
title(titleText, 'FontName','Arial','FontSize',20,'FontWeight','bold');

end