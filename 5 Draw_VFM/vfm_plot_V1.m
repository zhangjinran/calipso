function [block,TypeText] = vfm_plot_V1(vfm,lims,type,lat,noplot)
% 修改版（官方给的有问题）
% Description: Plots a vertical feature mask (vfm) within a specified set of horizontal limits and of a specified type. 
% Inputs: vfm - a 2d array (????x5515) of vfm data that has been imported using the hdftool
%        lims - a 1x2 array that specify the x limits of the plot in index units (e.g. [1 1000])
%        type - a string, choose ONE of the following:
%         'type','all','qa','phase','phaseqa','aerosol','cloud','psc','subtype','typeqa','averaging'
%        imgSize - the size in pixels of the image, good sizes are 1024x512 for saving, 
%                  or 1024x430 for side-by-side comparison in matlab 
%        noplot - if added will it will not produce a plot;
% Outputs: block - a 2d array of typed vfm data...the data that is to be plotted.
%       TypeText - a data structure that contains text information (a legend) about the vfm type returned
% Example: >> vfm_plot(vfm,[1 1000],'all');
% Will produce an image(plot) of vfm data from x indexes 1 to 1000 of the original vfm array of the feature
% type (i.e. invalid, clear air, cloud, aerosol, etc.)
%
% Uses vfm_type,vfm_row2block,CreateColorMap
% Return type is uint8
global fileTime1
global Str
imgSize = [1024,512];
folder_name=['/',fileTime1(2:end-1),'/',Str];
figureNum=6;   
className = 'uint8';
offset = 1165;
step = 290;
global Z;
linewidth  = 3;
fontsize  = 26;
% For now only return low alt data
% This low altitude data is stored as 15 profiles 30m vertical by 333m horizontal
% This corresponds to an array 290x15 packed in a 1d-array 4350 elements long;

% Get typed array;

%block = ones(290,15,className)*10;
% Get the number of rows of the vfm data (In Matlab data is ROWxCOL)
sz = size(vfm,1);
% Convert the first row of data and convert to a block (block variable is automatically created)
[block,TypeText] = vfm_row2block(vfm(lims(1),:),type);
% Convert the rest of the rows to block and append
for i =lims(1)+1:lims(2),
 block=cat(2,block,vfm_row2block(vfm(i,:),type));
end

% Was 'noplot' option used?
if (nargin == 6),
    disp('Plotting is off');
    if length(imgSize) ~= 2,
	error('imgSize is not a usable size. Must be 1x2 it is %f',size(imgSize));
    end
else 
    % Determine or set image size
    if (exist('imgSize'))
        if length(imgSize) ~= 2,
            MSG = num2str(length(imgSize));
            error('imgSize is not a usable size. Must be of length 2, it is %s',MSG);
        end
    else
        imgSize = [1024 512];
    end

    % Create axis arrays (i.e. distances);
    y = zeros(55+200+290,1);
    x = zeros((lims(2)-lims(1)+1)*15,1);
%     temp = [0:1:(lims(2)-lims(1))*15]';
%     x = lims(1)*15*333/1000 + 333*temp/1000; % distance in km
    ya = [1:1:545]';
    y = Ind2Alt(ya);

    % Create Figure & set size
    TheFig=figure(figureNum);
    set(gcf,'color','w');               % gcf 返回当前Figure 对象的句柄值,地图设置为白色
    set(gcf,'unit','centimeters','position',[2 2 20 15]);
    temp = get(TheFig,'Position');
%     set(TheFig,'Position',[temp(1) temp(2) imgSize(1) imgSize(2)]);
    set(TheFig,'Position',[temp(1) temp(2) temp(3) temp(4)]);
    axes('Position',[0.1 0.18 0.8 0.75]);
    image(x,ya,block);
    % Get the axis handle (NOTE: axes and axis are distinct and different!)
    IH = gca;
    % Reverse the direction of the y axis
    set(IH,'YDir','reverse');
    % Change the size of the image wrt the figure window
    correctYLabel(gca,y); % Puts the correct labels on
    % clolrbar//////////
    len = length(TypeText.ByteTxt);  %Get number of types to be plotted
    [r,g,b] = CreateColorMap(len,TypeText.FieldDescription);
    colormap([r g b]);  %Set colormap
    caxis([0 len]);     %Set color axis limits
    cb = colorbar;      %Put on colorbar
    
%     correctCBLabel(cb); %Correct the label for if 4 color colorbar
    set(cb,'Limits',[0,len],'Position',[0.92 0.113 0.013 0.845]);%Set size & loc of colorbar
    set(cb,'FontName','Times New Roman','fontsize',fontsize-11,'FontWeight','bold');
    set(cb,'ytick',[0.5:1:0.5+len-1],'yticklabel',TypeText.ByteTxt(1:end));
    % Title and legend
%     title(TypeText.FieldDescription,'FontName','Times New Roman','Fontsize',fontsize,'FontWeight','bold');
    % 调整X轴
    set(gca,'xtick',[15:round(size(x,1)/10):size(x,1)]); 
%     set(gca,'xtick',[2000:10000:size(x,1)]); 
    xx = get(gca,'XTick');
%     xx(1) = [];% 自己添加，避免开始为0
    cc = cell(size(xx));
    cc = char(sprintf('%5.2f',lat(round(xx(1)/15))));
    for j=2:length(xx)
        cc = char(cc,sprintf('%5.2f',lat(round(xx(j)/15))));
    end 
    set(gca,'XTickLabel',cc);
    % 调整Y轴
%     set(gca,'YDir','reverse');
%     set(gca,'YLim',[92,556],'Ytick',[92,125,158,191,225,258,295,362,429,495,556]);
%     set(gca,'YLim',[59,556],'Ytick',[59,92,125,158,191,225,261,328,395,462,528]);
%     yy = get(gca,'YTick');
%     dd = cell(size(yy));
%     dd = char(sprintf('%d',round(Z(yy(1)))));
%     for j=2:length(yy)
%         dd = char(dd,sprintf('%d',round(Z(yy(j)))));
%     end
%     set(gca,'YTickLabel',dd);
    %???????????????????????
    xlabel('Latitude','FontName','Times New Roman','fontsize',fontsize,'FontWeight','bold');
    ylabel('Altitude (km)','FontName','Times New Roman','fontsize',fontsize,'FontWeight','bold');
    % Make the image the current axes
    axes(IH)
       
    % 第三步：画图保存
%     if isa(vfm,'cell')
%         directory1 =[cd,folder_name];
%         [X,~]=getframe(gcf);
%         imwrite(X,[directory1,'.png']);% 保存图片到新建的文件夹下。
%     else
%         directory1 =[cd,folder_name];
%         [X,~]=getframe(gcf);
%         imwrite(X,[directory1,'.png']);% 保存图片到新建的文件夹下。
%     end

    % Display warning messages when image is larger than figure window (in pixels)
    % this is to let you know that you're trying to display more information than what
    % is there and that small/thin feature may be missing. If you use the zoom tool that
    % data will be visible.
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

end % if nargin == 4
set(gca,'FontName','Times New Roman','FontSize',fontsize,'FontWeight','bold');
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
yticks = [30 25 20 18 16 14 12 10 8 7 6 5 4 3 2 1 0 -0.5]';
InvYtick = Alt2Ind(yticks);
set(Taxis,'YTick',InvYtick);
InputLabel = get(Taxis,'YTickLabel');
    sz = max(size(InputLabel));
    % Convert text to a number then raise it to 10^ then convert to text;
    label = '';
    for i = 1:sz,
	number = round((str2num(InputLabel{i,:})));
	txti = sprintf('%3.1f',yaConv(number));
	label = strvcat(label,txti);
    end
    set(Taxis,'YTickLabel',label);

function [ind] = Alt2Ind(alt)
% NOTE: Returned index is not an integer.
sz = length(alt);
 for i=1:sz,
     if alt(i) >= 20.2,
         ind(i) = (30.1 - alt(i)) / 0.180;
     elseif alt(i) >= 8.2,
         ind(i) = (20.2 - alt(i))/(0.06)+55;
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