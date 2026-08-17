function  Cloud_Phase_plot(block,lims,type,lat,figureNum)

global fileTime1
global Str
global Lidar_Data_Altitudes
imgSize = [1024,512];
folder_name=['/',fileTime1(2:end-1),'/',Str];
%figureNum=6;
global Z;
fontsize  = 16;

if strcmp(type,'Cloud')
    r = [192,255,255,0,160]'/255;
    g = [255,0,255,0,169]'/255;
    b = [168,0,255,255,169]'/255;
    TypeText = {'N/A = not applicable  0 = unknown  1 = ice  2 = water  3 = oriented ice'};
    TypeText1 = {'N/A','0','1','2','3'};
    block = block + 2.5;
    
elseif strcmp(type,'Aerosol')
    r = [198,0,255,255,0,153,0,0,255,138,81]'/255;
    g = [198,0,255,179,166,76,0,142,255,138,81]'/255;
    b = [198,255,0,0,0,0,0,194,255,138,81]'/255;
    TypeText = {'    N/A = not applicable  1 = marine  2 = dust  3 = polluated continental/smoke',...
        '4 = clean continental  5 = polluted dust  6 = elevated smoke  7 = dusty marine',...
        '                 8 = PSC aerosol  9 = volcanic ash  10 = sulfate/other'};
    TypeText1 = {'N/A','1','2','3','4',...
        '5','6','7','8','9','10'};
    block = block + 1.5;
    %数据从1开始
elseif strcmp(type,'CAD')
%     r = [0,255,0]'/255;
%     g = [38,160,220]'/255;
%     b = [255,0,255]'/255;
r = [255,27,192]'/255;
g = [255,72,38]'/255;
b = [255,158,47]'/255;
    
    TypeText = {'N/A = not applicable   1= Aerosol   2 = Cloud'};
    TypeText1 = {'N/A','1','2'};
    block(block >= 0) = 3;
    block(block < 0) = 2;
    
    
end



x = zeros((lims(2)-lims(1)+1),1);
ya = [1:1:583]';
TheFig=figure(figureNum);
clf;
set(gcf,'color','w');               % gcf 返回当前Figure 对象的句柄值,地图设置为白色
set(gcf,'unit','centimeters','position',[2 2 20 15]);
temp = get(TheFig,'Position');
set(TheFig,'Position',[temp(1) temp(2)  temp(3) temp(4)]);
axes('Position',[0.10 0.27 0.86 0.67]);


image(x,ya,block);
IH = gca;
len = length(r);
colormap([r g b]);
cb = colorbar;
set(cb,'FontName','Times New Roman','fontsize',fontsize,'FontWeight','bold');
set(cb,'ytick',[1.5:1:1.5+len+1],'yticklabel',TypeText1(1:end));

set(gca,'xtick',[1:round(size(x,1)/8):size(x,1),size(x,1)-1]);
xx = get(gca,'XTick');
cc = cell(size(xx));
cc = char(sprintf('%5.2f',lat(round(xx(1)))));
for j=2:length(xx)
    cc = char(cc,sprintf('%5.2f',lat(round(xx(j)))));
end
set(gca,'XTickLabel',cc);
set(gca,'YLim',[34,583],'Ytick',[34 92,158,225,295,362,429,495,562]);
%set(gca,'YLim',[92,583],'Ytick',[92,158,225,295,362,429,495,562]);

yy = get(gca,'YTick');
dd = cell(size(yy));
dd = char(sprintf('%d',round(Lidar_Data_Altitudes(yy(1)))));
for j=2:length(yy)
    dd = char(dd,sprintf('%d',round(Lidar_Data_Altitudes(yy(j)))));
end
set(gca,'YTickLabel',dd);
set(gca,'FontSize',fontsize,'fontweight','bold')

xlabel('Latitude (°)','FontName','Times New Roman','fontsize',fontsize,'FontWeight','bold');
ylabel('Altitude (km)','FontName','Times New Roman','fontsize',fontsize,'FontWeight','bold');

if strcmp(type,'Cloud')
    title('Cloud Phase Assignment','FontSize',fontsize,'fontweight','bold')
    text('Units','normalized','Position',[-0.01,-0.22],'String',TypeText,...
        'color','k','FontWeight','bold','fontsize',fontsize-2,'EdgeColor','k')%设置单位为像素
elseif strcmp(type,'Aerosol')
        title('Aerosol Classification','FontSize',fontsize,'fontweight','bold')
    text('Units','normalized','Position',[-0.03,-0.28],'String',TypeText,...
        'color','k','FontWeight','bold','fontsize',fontsize-2,'EdgeColor','k')%设置单位为像素
elseif strcmp(type,'CAD')
    title('Discriminating Between Cloud and Aerosol','fontsize',fontsize,'FontWeight','bold');
    text('Units','normalized','Position',[0.15,-0.22],'String',TypeText,...
        'color','k','FontWeight','bold','fontsize',fontsize-2,'EdgeColor','k')%设置单位为像素
end

set(gca,'FontSize',fontsize,'fontweight','bold')
axes(IH)

Isize = get(TheFig,'Position');
if  (Isize(3) < size(block,2)) && (Isize(4) < size(block,1)),
    disp('Warning: Image is bigger than the current figure widow');
    disp('         not all pixels may be visible');
elseif  (Isize(3) < size(block,2)),
    disp('Warning: Image is wider than the current figure widow');
    disp('         not all pixels may be visible');
elseif Isize(4) < size(block,1),
    disp('Warning: Image is taller than the current figure widow');
    disp('         not all pixels may be visible');
end


% set(gca,'FontName','Times New Roman','FontSize',fontsize,'FontWeight','bold');
set(gca,'FontSize',fontsize,'FontWeight','bold');
%------------------------------------------------------------------------------
% Helper functions
%------------------------------------------------------------------------------

function correctCBLabel(cb) %Colorbar Handle
if (max(get(cb,'YTick')) == 5)
    set(cb,'YTick',[1 2 3 4 5]);
elseif (max(get(cb,'YTick')) == 6)
    set(cb,'YTick',[1 2 3 4 6]);
end
InputLabel = get(cb,'YTickLabel');
sz = max(size(InputLabel));
label = '';
for i = 1:sz,
    number = (str2num(InputLabel{i,:}))-1;
    txti = sprintf('%d',number);
    label = strvcat(label,txti);
end
set(cb,'YTickLabel',label);

function correctYLabel(Taxis,yaConv)
%yticks = [30 25 20 18 16 14 12 10 8 7 6 5 4 3 2 1 0 -0.5]';
yticks = [30 20 16 12 8 4 0]';
InvYtick = Alt2Ind(yticks);
set(Taxis,'YTick',InvYtick);
InputLabel = get(Taxis,'YTickLabel');
sz = max(size(InputLabel));
% Convert text to a number then raise it to 10^ then convert to text;
label = '';
for i = 1:sz,
    number = round((str2num(InputLabel{i,:})));
    txti = sprintf('%3.0f',yaConv(number));
    label = strvcat(label,txti);
end
set(Taxis,'YTickLabel',label);

function [ind] = Alt2Ind(alt)
% NOTE: Returned index is not an integer.
sz = length(alt);
% for i=1:sz,
%     if alt(i) >= 20.2,
%         ind(i) = (30.1 - alt(i)) / 0.180;
%     elseif alt(i) >= 8.2,
%         ind(i) = (20.2 - alt(i))/(0.06)+55;
%     else
%         ind(i) = (8.2 - alt(i))/(0.03)+255;
%     end
% end

for i=1:sz,
    if alt(i) >= 20.2,
        ind(i) = (30.1 - alt(i)) / 0.180 ;
    elseif alt(i) >= 8.2,
        ind(i) = (20.2 - alt(i))/(0.06) + 55;
    else
        ind(i) = (8.2 - alt(i))/(0.03)+255;
    end
end


function [alt] = Ind2Alt(ind);
sz = length(ind);
for i=1:sz,
    if ind(i) < 56,
        alt(i) = 30.1 - (i)*180/1000;
    elseif ind(i) < 256,
        alt(i) = 20.2 - (i-55)*60/1000;
    else
        alt(i) = 8.2 - (i-255)*30/1000;
    end
end