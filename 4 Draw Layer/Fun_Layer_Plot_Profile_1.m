function Fun_Layer_Plot_Profile(Lat,Lidar_Data_Altitudes,TAB_532,topbin_under80km,basebin_under80km)

%% CALIPSO colorbar的相关信息
[rgb colors_532 color_bar, color_bar_labels] = kathys_lidar_colors('useGrayScale');
data = TAB_532;
lat  = Lat;
for i = 1:size(data,1)
    for j = 1:size(data,2)
        if isnan(data(i,j)) 
        data(i,j) = -9999;
        end 
    end
end

nAlt = size(data,1);
nProf = size(data,2);
profile_num = 1:nProf;
alt_bin_num = 1:nAlt;
out_img = zeros(nAlt,nProf,3,'uint16');

%获取TAB的伪彩图
for ic=1:nProf,
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


%% 图一
myfontsize=16;hori=0.04;verti=0.08;
figure('color','w','unit','normalized','position',[0.1,0.34,0.8,0.43])
clf;
posi=[0.05,0.18,0.28,0.72];
ax1=subplot('position',posi);
%画图
h=imagesc(profile_num,alt_bin_num,out_img);
IH = gca;
% 调整X轴，显示标签
set(gca,'xtick',[1:(size(lat,1))/5:size(lat,1),size(lat,1)-1]); % 设法调整横坐标个数，这里设置为6个坐标。
xx = get(gca,'XTick');
cc = char(sprintf('%5.2f',lat(xx(1))));
for j=2:length(xx)
    cc = char(cc,sprintf('%5.2f',lat(xx(j))));
end
set(gca,'XTickLabel',cc);
% 调整Y轴，这里Y轴的高度是根据bin找到 Lidar_Data_Altitudes 变量中对应位置的数字作为高度标签
% set(gca,'YLim',[92,583],'Ytick',[92,125,158,191,225,258,295,362,429,495,562]);
set(gca,'YLim',[92,583],'Ytick',[92,158,225,295,362,429,495,562]);
yy = get(gca,'YTick');
dd = char(sprintf('%d',round(Lidar_Data_Altitudes(yy(1)))));
for j=2:length(yy)
    dd = char(dd,sprintf('%d',round(Lidar_Data_Altitudes(yy(j)))));
end
set(gca,'YTickLabel',dd);

%设置坐标轴信息
ylabel('Altitude (km)')
xlabel('Latitude (°N)')
set(gca,'FontSize',myfontsize-2,'FontWeight','bold');%
%设置标题
title('TAB','fontsize',myfontsize,'FontWeight','bold');%标题

%调整colorbar的位置、大小
cb=lidar_colorbar(rgb,color_bar,color_bar_labels,'vert');
posi_cb=get(cb,'position');
posi_cb(1)=posi_cb(1)-0.01;
posi_cb(3)=posi_cb(3)*0.4;
set(cb,'position',posi_cb);

text('Units','normalized','Position',[0.02,0.96],'String','(a)',...
    'color','w','FontWeight','bold','fontsize',myfontsize+2)%设置单位为像素
hold on

%% 图二 绘制不同分辨率检测的特征的分布情况
posi(1)=posi(1)+posi(3)+hori;
ax2=subplot('position',posi);
sequs = [15,60,240];% 依次代表5、20、80水平分辨率所需要的平均的廓线条数
hor_resolutions={'5 km','20 km','80 km'};
gradual_change{1} = [244/255 208/255 0/255];    
gradual_change{2} = [0/255,255/255,0/255];  
gradual_change{3} = [255/255,255/255,255/255]; 

h=imagesc(profile_num,alt_bin_num,out_img);hold on
IH = gca;
% 调整X轴
set(gca,'xtick',[1:(size(lat,1))/5:size(lat,1),size(lat,1)-1]); % 设法把调整横坐标个数，这里设置为6个坐标。
xx = get(gca,'XTick');
cc = char(sprintf('%5.2f',lat(xx(1))));
for j=2:length(xx)
    cc = char(cc,sprintf('%5.2f',lat(xx(j))));
end
set(gca,'XTickLabel',cc);

% 调整Y轴，这里Y轴的高度是根据bin找到 Lidar_Data_Altitudes 变量中对应位置的数字作为高度标签
% set(gca,'YLim',[92,583],'Ytick',[92,125,158,191,225,258,295,362,429,495,562]);
set(gca,'YLim',[92,583],'Ytick',[92,158,225,295,362,429,495,562]);
yy = get(gca,'YTick');
dd = char(sprintf('%d',round(Lidar_Data_Altitudes(yy(1)))));
for j=2:length(yy)
    dd = char(dd,sprintf('%d',round(Lidar_Data_Altitudes(yy(j)))));
end
set(gca,'YTickLabel',dd);

%调整colorbar的大小、位置等
cb=lidar_colorbar(rgb,color_bar,color_bar_labels,'vert');
posi_cb=get(cb,'position');
posi_cb(1)=posi_cb(1)-0.01;
posi_cb(3)=posi_cb(3)*0.4;
set(cb,'position',posi_cb);

% 绘制不同分辨率下检测到的层次
for ii = size(topbin_under80km,2):-1:1
    sequs_temp = sequs(ii);   % 不同分辨率得出的廓线条数
    topbin_temp=topbin_under80km{ii};
    basebin_temp=basebin_under80km{ii};
    color_temp=cell2mat(gradual_change(ii));
    for i = 1:size(topbin_temp,1)
        for j = 1:size(topbin_temp,2)
            if ~isnan(topbin_temp(i,j))
                x = [(sequs_temp*i-(sequs_temp-1)),(sequs_temp*i),...
                    (sequs_temp*i),(sequs_temp*i-(sequs_temp-1))]; % 注意x轴是以廓线为单位的
                y2 = [(topbin_temp(i,j)),(topbin_temp(i,j)),...
                    (basebin_temp(i,j)),(basebin_temp(i,j))];% 注意y轴是以bin为单位的
                h_temp(ii) = fill(x,y2,color_temp);
                set(h_temp(ii),'EdgeColor',color_temp);% 变画的各分辨率的检测出的层次不画边界。    
            end
        end
    end
    legend_name_temp(ii) = hor_resolutions(ii);
end

ylabel('Altitude (km)')
xlabel('Latitude (°N)')
set(gca,'FontSize',myfontsize-2,'FontWeight','bold');%
%设置标题
title('Layer Detection','fontsize',myfontsize,'FontWeight','bold');%标题

h_legend=legend(h_temp,legend_name_temp,'Location','best','Orientation','horizontal',...
    'Color','none','TextColor','w');%标签
legend('boxoff')
text('Units','normalized','Position',[0.02,0.96],'String','(b)',...
    'color','w','FontWeight','bold','fontsize',myfontsize+2)%设置单位为像素


%% 图三 绘制廓线情况
posi(1)=posi(1)+posi(3)+hori;
ax3=subplot('position',posi);
linewidth        = 1;
x_single_profile = zeros(1,100);
y_data           = zeros(1,100);
X                = 1:size(Lat,1);
sequ             = 1;%TAB是333m廓线，故sequ这里用1
mid_profile      = 0;
y_num = 1:size(Lidar_Data_Altitudes,1);
i=1;
while i<2 %这里设置可手动点击廓线的次数
    [x_single_profile(i), y_data(i)] = ginputax(ax1,1);
    if x_single_profile(i) >= min(X) &&  x_single_profile(i) <= max(X)
        select_profi  = find(abs(X-x_single_profile(i))==min(abs(X-x_single_profile(i))));
        x_select_show = select_profi*sequ - mid_profile;
        if exist('h_cursor2')
            delete(h_cursor2); delete(h_cursor3);
        end
        axes(ax1);
        h_cursor1 = plot([x_single_profile(i),x_single_profile(i)],[0,size(TAB_532,1)],'-g','LineWidth',2);% 绿线标注选中的廓线位置
        hold on;
        axes(ax2);
        h_cursor2 = plot([x_single_profile(i),x_single_profile(i)],[0,size(TAB_532,1)],'-g','LineWidth',2);% 绿线标注选中的廓线位置
        axes(ax3);
        h_cursor3 = plot((TAB_532(:,x_select_show)),(alt_bin_num),'color','g','LineWidth',linewidth);% 图二中廓线的TAB信号
        title(['TAB Profile num: ',num2str(x_select_show)],'fontweight','bold');
        %这里Y轴的高度是根据bin找到 Lidar_Data_Altitudes 变量中对应位置的数字作为高度标签
        set(gca,'YLim',[92,583],'Ytick',[92,158,225,295,362,429,495,562]);
        yy = get(gca,'YTick');
        dd = char(sprintf('%d',round(Lidar_Data_Altitudes(yy(1)))));
        for j=2:length(yy)
            dd = char(dd,sprintf('%d',round(Lidar_Data_Altitudes(yy(j)))));
        end
        set(gca,'YTickLabel',dd,'YDir','reverse');
        set(gca,'FontSize',myfontsize,'fontweight','bold')
        set(gca,'XScale','log');
        linkaxes([ax1,ax2,ax3],'y');
        i=i+1;   
    end
end

end