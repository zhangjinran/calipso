
function Draw_Process(data_struct)
upper_name=inputname(1);
disp(upper_name);
fns=fieldnames(data_struct);
for  k=1:length(fns)
    name=fns{k};
    data=data_struct.(name);
    if ~decide_name(name)
        continue;
    end
   

    if all(isnumeric(data))&&all((size(data))==[1104,8])
        %fprintf('正在处理此字段：%s\n',name);
        %disp('格式为[1104,8]')
        draw_test(data_struct,data,name);
    elseif all(isnumeric(data))&&all((size(data))==[1104,48])
       %fprintf('正在处理此字段：%s\n',name);
        %disp('格式为[1104,48]，将提取为 [1104,8]');
        
        % 先创建一个新的 8 列矩阵，不破坏原始数据
        data_new = zeros(size(data,1), 8);  
        
        for i=1:size(data,1)
            for m=1:8
                % 从 48 列中提取第 3,9,15...45 列 → 放到新矩阵 1~8 列
                data_new(i,m) = data(i, 6*(m-1) + 3);
            end
        end
        
        % 用新的8列数据画图
        draw_test(data_struct, data_new, name);

    end
end








end

function result=decide_name(name)
name_delete={'Horizontal_Averaging','Layer_Base_Altitude','Layer_Top_Altitude','Layer_Base_Extended'};
name_key={'Pressure','Temperature','Method','Flag','Fraction','CAD'};
for i=1:length(name_delete)
    if strcmp(name_delete{i},name)
        result=0;
        return;
    end
end
    
    if  any(contains(name,name_key))
        result=0;
        return;
    end

result=1;
end


function draw_test(ALay,argument,titlename)

%% 1. 读数据
Lat         = ALay.Lat;
LayerBase   = ALay.Layer_Base_Altitude;
LayerTop    = ALay.Layer_Top_Altitude;
IAB         = argument;

nProf = length(Lat);    % 1104
nAlt  = 200;            % 高度索引
alt   = linspace(0,16,nAlt);
img   = zeros(nAlt, nProf);

%% 2. 纯索引填充（只认序号，不处理坐标）
for i = 1:nProf
    for l = 1:size(LayerBase,2)
        zb = LayerBase(i,l);
        zt = LayerTop(i,l);
        v  = IAB(i,l);
        
        if isnan(v) || zb<=0 || zt<=zb
            continue;
        end
        
        idx = alt >= zb & alt <= zt;
        img(idx, i) = v;
    end
end

img(img==0) = NaN;
min_val=min(img(:),[],'omitnan');
img_data=img(~isnan(img));
p95=prctile(img_data,95);
p5=prctile(img_data,5);
%% 避免所有值都是一个值，进行一下处理
if min_val==p95
    disp(titlename);
    disp(' The all num is same!!!!');
    return ;
end
%% ==============================================
%% 【第一步：完全用索引画图！】你要的第一步！
%% ==============================================
f=figure;
set(f,'Units','centimeters');
set(f,'Position',[5,5,90,10]);
h = imagesc(1:nProf, 1:nAlt, img);  % 只画索引！

%% ==============================================
%% 【第二步：画完再映射坐标！】你要的第二步！
%% ==============================================

set(gca,'Position',[0.08,0.15,0.75,0.75])
set(gca, 'XTickLabelMode','manual');
set(gca, 'YTickLabelMode','manual');
set(gca,'FontName','Arial','FontSize',20,'FontWeight','bold');

% 映射 X 轴 → 纬度
xt = get(gca,'XTick');
xt(xt<1 | xt>nProf) = [];
xlbl = arrayfun(@(x) sprintf('%.2f', Lat(round(x))), xt, 'UniformOutput',false);
set(gca, 'XTick', xt, 'XTickLabel', xlbl);


% 映射 Y 轴 → 高度
yt = get(gca,'YTick');
yt(yt<1 | yt>nAlt) = [];
ylbl = arrayfun(@(y) sprintf('%.0f', alt(round(y))), yt, 'UniformOutput',false);

set(gca, 'YTick', yt, 'YTickLabel', ylbl);
set(gca, 'YDir', 'normal');
% Y轴反转


%% 颜色
%根据实际情况灵活调整
colormap jet;
img(img<0)=NaN;

clim([p5, p95]); % 自己调整颜色范围

%% 标签
titleText=replace(titlename,'_',' ');

xlabel('Latitude','FontName','Arial','FontSize',20,'FontWeight','bold');
ylabel('Altitude (km)','FontName','Arial','FontSize',20,'FontWeight','bold');
cb=colorbar;
set(cb,'FontName','Arial','FontSize',20,'FontWeight','bold');


title(titleText...
    ,'FontName','Arial','FontSize',20,'FontWeight','bold');

end


function draw_test_48coloums(ALay, argument, titlename)

%% 1. 读数据
Lat         = ALay.Lat;
IAB         = argument;        % 你的数据：1104 × 48

nProf = length(Lat);           % 1104（不变）
nHgt  = 48;                    % 高度层数 = 48
height_per_bin = 5;            % 每层 5 km
alt_edges = (0:nHgt)*height_per_bin;  % [0,5,10,...,240]
alt_centers = (0.5:nHgt-0.5)*height_per_bin;

%% 2. 构建 img 矩阵（直接用 48 层高度）
img = zeros(nHgt, nProf);

for i = 1:nProf
    for h = 1:nHgt
        v = IAB(i, h);
        if ~isnan(v)
            img(h, i) = v;
        end
    end
end

img(img<-999) = NaN;
min_val=min(img(:),[],'omitnan');
img_data=img(~isnan(img));
p5=prctile(img_data,5);
p95=prctile(img_data,95);

if min_val==p95
    disp(titlename);
    disp('All values are the same!!!!');
    return ;
end

%% ==============================================
%% 画图
%% ==============================================
f=figure;
set(f,'Units','centimeters');
set(f,'Position',[5,5,90,10]);
imagesc(1:nProf, 1:nHgt, img);

set(gca,'Position',[0.08,0.15,0.75,0.75])
set(gca,'FontName','Arial','FontSize',20,'FontWeight','bold');

%% X轴：纬度
xt = get(gca,'XTick');
xt(xt<1 | xt>nProf) = [];
xlbl = arrayfun(@(x) sprintf('%.2f', Lat(round(x))), xt, 'UniformOutput',false);
set(gca, 'XTick', xt, 'XTickLabel', xlbl);

%% Y轴：高度（每层5km）
yt = get(gca,'YTick');
yt(yt<1 | yt>nHgt) = [];
ylbl = arrayfun(@(y) sprintf('%.0f', alt_centers(round(y))), yt, 'UniformOutput',false);
set(gca, 'YTick', yt, 'YTickLabel', ylbl);
set(gca, 'YDir','normal');

%% 颜色
colormap jet;
img(img<0)=NaN;
clim([p5, p95]);

%% 标签
titleText=replace(titlename,'_',' ');
xlabel('Latitude','FontSize',20,'FontWeight','bold');
ylabel('Altitude (km)','FontSize',20,'FontWeight','bold');
cb=colorbar;
set(cb,'FontSize',20,'FontWeight','bold');
title(titleText,'FontSize',20,'FontWeight','bold');

end


