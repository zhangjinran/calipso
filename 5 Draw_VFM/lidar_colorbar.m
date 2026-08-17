function hcb=lidar_colorbar(rgb,color_bar,color_bar_labels,loc)
% Plots a colorbar for lidar attenuated backscatter images


%  Taken from COLORBARF Display color bar for a filled contour plot.
% =========================================================================
% colorbarf  Version 1.7 4-Apr-2006
%
% Usage: 
%   colorbarf(cout,H,[loc])
%
%   Example: [cout,H,cf]=contourf(peaks);
%            colorbarf(cout,H);
%
% Description:
%   This Matlab function uses the output arguments from the contourf function
%   to produce a colorbar that sets the tick marks equal to the contour levels
%   in the figure. The area of the colorbar between the tick marks is filled
%   with the same color used by the contourf function. The location may be
%   specified as either 'vert' or 'horiz'.
%
% Input:
%   cout - output argument of contourf containing an matrix describing the
%          contours
%   H    - graphics handles for the contours in the figure
%   loc  - location of the colorbar specified 'vert' for vertical (Default) and
%          'horiz' for horizontal. If not specified, default is set.
%
% Output:
%   hcb  - graphics handle for the colorbar axis
%
% Original Author:
%   Blair Greenan
%   Bedford Institute of Oceanography
%   December 22, 1998
%   Matlab 5.2.1
%   greenanb@mar.dfo-mpo.gc.ca
% =========================================================================
%

%   This function has been derived from the Matlab colorbar function
%   Author: Clay M. Thompson 10-9-92
%   Copyright (c) 1984-98 by The MathWorks, Inc.
%   $Revision: 5.27 $  $Date: 1997/12/18 17:04:01 $
%

% Modifications:
%   Version 1.1 - function now works with the output of the Matlab 
%   contourf function. Colorbarf can now handle situations in which
%   the lowest contour level is not filled if an array, which does not
%   include a value at or below the minimum of the data, is passed to
%   the contourf function. Version 1.0 also did not plot the colorbar
%   appropriately if a colorbar already existed on the figure...this
%   is now fixed.
%   Version 1.2 - ch.UserData changed to ch(i).UserData. This enables 
%   colrbarf to be used on multiple plot figures - Thanks to Peter Brickley, U. of Maine
%   Version 1.3 - changes made to handle NaNs in data - 11-Mar-1999 - Thanks to J. van der Molen 
%   Version 1.4 - removed for loop at line 128 to speed up execution time
%   Version 1.5 - modified line 129 "if (N1 > 1)" to accomodate the MATLAB 6.0 include some NULL
%                 contours that have one point that is simply NaN.
%   Version 1.6 - modified by Aslak Grinsted at line 145 to ensure MATLAB 7
%                   compatability
%   Version 1.7 - modified by Povl Abrahamsen at lines 243 & 320 to ensure
%                   correct scale if clim has been set manually, and if 
%                   Matlab 7 contours have been labeled.

%   If called with COLORBAR(H) or for an existing colorbar, don't change
%   the NextPlot property.
changeNextPlot = 1;

% colorbar must have output parameters from the contourf function
if (nargin < 3)
   error('colorbarf requires a minimum of two input parameters');
end

% default location for colorbar
if nargin<4, loc = 'vert'; end

% if an axes handle is passed for the location
ax = [];
if nargin==4,
    if ishandle(loc)
        ax = loc;
        if ~strcmp(get(ax,'type'),'axes'),
            error('Requires axes handle.');
        end
        units = get(ax,'units'); set(ax,'units','pixels');
        rect = get(ax,'position'); set(ax,'units',units)
        if rect(3) > rect(4), loc = 'horiz'; else loc = 'vert'; end
        changeNextPlot = 0;
    end
end

h = gca;

if (nargin == 3)
   % Search for existing colorbar so that we can plot over it if we find it
   ch = get(findobj(gcf,'type','axes','tag','Colorbar')); ax = [];
   for i=1:length(ch),
      ud = ch(i).UserData; % ch.UserData changed to ch(i).UserData - suggested by P. Brickley
      d = ud.PlotHandle;
      if prod(size(d))==1 & isequal(d,h), 
         ax = findobj(gcf,'type','axes','tag','Colorbar'); 
         pos = ch.Position;
         if pos(3)<pos(4), loc = 'vert'; else loc = 'horiz'; end
         changeNextPlot = 0;
         break; 
      end
   end
elseif ((nargin == 4) & (~ishandle(loc)))
   % Search for existing colorbar so that we can plot over it if we find it
   ch = get(findobj(gcf,'type','axes','tag','Colorbar')); ax = [];
   for i=1:length(ch),
      ud = ch(i).UserData; % ch.UserData changed to ch(i).UserData - suggested by P. Brickley
      d = ud.PlotHandle;
      if prod(size(d))==1 & isequal(d,h), 
         ax = findobj(gcf,'type','axes','tag','Colorbar'); 
         pos = ch.Position;
         if pos(3)<pos(4), loc = 'vert'; else loc = 'horiz'; end
         changeNextPlot = 0;
         break; 
      end
   end
end

origNextPlot = get(gcf,'NextPlot');
if strcmp(origNextPlot,'replacechildren') | strcmp(origNextPlot,'replace'),
    set(gcf,'NextPlot','add')
end

%%%%%%%%%%%%%% Filled Colorbar %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% In our case (lidar) we are supplying the colormap and the colar_bar 

% We have the rgb colormap, the color_bar array and the color_bar_labels
% First convert the color_bar array into a 3xN matrix of used colors
colors = zeros(length(color_bar),3);

for i=1:length(color_bar),
    ind = color_bar(i);
    colors(i,:) = rgb(ind,:)/255;
end
%colors = rgb(color_bar,:);

%colors = rgb/255;
nColors = length(colors);
nLabels = length(color_bar_labels);
%if (nLabels-1 ~= nColors)
%    disp('There is going to be a problem with the labels')
%end
%nColors = nColors-1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if loc(1)=='v', % Append vertical scale to right of current plot
    
    if isempty(ax),
        units = get(h,'units'); set(h,'units','normalized')
        pos = get(h,'Position'); 
        [az,el] = view;
        stripe = 0.075; edge = 0.02; 
        if all([az,el]==[0 90]), space = 0.05; else space = .1; end
        set(h,'Position',[pos(1) pos(2) pos(3)*(1-stripe-edge-space) pos(4)])
        rect = [pos(1)+(1-stripe-edge)*pos(3) pos(2) stripe*pos(3) pos(4)];
        ud.origPos = pos;
        
        % Create axes for stripe and
        % create DeleteProxy object (an invisible text object in
        % the target axes) so that the colorbar will be deleted
        % properly.
        ud.DeleteProxy = text('parent',h,'visible','off',...
                              'tag','ColorbarDeleteProxy',...
                              'handlevisibility','off',...
             'deletefcn','eval(''delete(get(gcbo,''''userdata''''))'','''')');
        ax = axes('Position', rect,'Tag','TMW_COLORBAR');
        set(ud.DeleteProxy,'userdata',ax)
        set(h,'units',units)
    else % if colobar axes already exist
        axes(ax);
        ud = get(ax,'userdata');
    end
    % Create color stripe by drawing the appropriate number of filled rectangles 
    if any(isnan(colors)) % if the bottom level is not filled
       for j = 1:nColors
          k = j - 1; % don't fill bottom rectangle on colorbar
          x(1) = 0;
          x(2) = 1;
          x(3) = 1;
          x(4) = 0;
          %y(1) = (j-1)*(1/(nColors+1));
          %y(2) = (j-1)*(1/(nColors+1));
          %y(3) = j*(1/(nColors+1));
          %y(4) = j*(1/(nColors+1));
          y(1) = (j-1);
          y(2) = (j-1);
          y(3) = j;
          y(4) = j;
          if (k == 0)
             hfill = fill(x,y,colors(length(colors),:)); % fill with NaN
          else
             hfill = fill(x,y,colors(k,:));
          end
          hold on
       end
    else %we have filled the bottom contour level
       for j = 1:nColors
          x(1) = 0;
          x(2) = 1;
          x(3) = 1;
          x(4) = 0;
          y(1) = (j-1);
          y(2) = (j-1);
          y(3) = j;
          y(4) = j;
          hfill = fill(x,y,colors(j,:));
          hold on
       end
    end
    set(ax,'YAxisLocation','right')
    set(ax,'xtick',[])
    ylimits = get(gca,'ylim');
    ylimits(1) = 1;
    nColor_Interval = 2;
    nColor_change = length([1:nColor_Interval:nColors]);
    deltaTick =  (ylimits(2)-ylimits(1))/(nColor_change);
    %endTick =  ylimits(2)-deltaTick;
    endTick =  nColors;
    myYticks = [ylimits(1):nColor_Interval:endTick]-1/2;
    set(gca,'ytick',myYticks);
    
   % myStr{1} = ' ';
   kkk = 1;
    for kk = 1:nColor_Interval: nColors;
       myStr{kkk} = num2str(color_bar_labels(kk));
       kkk = kkk+1;
       %myStr{kk+1} = num2str(color_bar_labels(kk));
    end
    myStr{kkk} = ' ';
    set(gca,'YTickLabel',myStr)
    set(gca,'CLim',caxis(h)) %version 1.7 changed by Povl Abrahamsen

    % set up axes deletefcn
    set(ax,'tag','Colorbar','deletefcn','colorbar(''delete'')')
    
elseif loc(1)=='h', % Append horizontal scale to top of current plot
    
    if isempty(ax),
        units = get(h,'units'); set(h,'units','normalized')
        pos = get(h,'Position');
        stripe = 0.075; space = 0.1;
        set(h,'Position',...
            [pos(1) pos(2)+(stripe+space)*pos(4) pos(3) (1-stripe-space)*pos(4)])
        rect = [pos(1) pos(2) pos(3) stripe*pos(4)];
        ud.origPos = pos;

        % Create axes for stripe and
        % create DeleteProxy object (an invisible text object in
        % the target axes) so that the colorbar will be deleted
        % properly.
        ud.DeleteProxy = text('parent',h,'visible','off',...
                              'tag','ColorbarDeleteProxy',...
                              'handlevisibility','off',...
             'deletefcn','eval(''delete(get(gcbo,''''userdata''''))'','''')');
        ax = axes('Position', rect,'Tag','TMW_COLORBAR');
        set(ud.DeleteProxy,'userdata',ax)
        set(h,'units',units)
    else % if colobar axes already exist
        axes(ax);
        ud = get(ax,'userdata');
    end
    
    % Create color stripe by drawing the appropriate number of filled rectangles 
    if any(isnan(colors)) % if the bottom level is not filled
       for j = 1:nColors
          k = j - 1; % don't fill bottom rectangle on colorbar
          y(1) = 0;
          y(2) = 1;
          y(3) = 1;
          y(4) = 0;
          x(1) = (j-1)*(1/(nColors+1));
          x(2) = (j-1)*(1/(nColors+1));
          x(3) = j*(1/(nColors+1));
          x(4) = j*(1/(nColors+1));
          if (k == 0)
             hfill = fill(x,y,colors(length(colors),:)); % fill with NaN
          else
             hfill = fill(x,y,colors(k,:));
          end
          hold on
       end
    else %we have filled the bottom contour level
       for j = 1:nColors
          y(1) = 0;
          y(2) = 1;
          y(3) = 1;
          y(4) = 0;
          x(1) = (j-1)*(1/(nColors+1));
          x(2) = (j-1)*(1/(nColors+1));
          x(3) = j*(1/(nColors+1));
          x(4) = j*(1/(nColors+1));
          hfill = fill(x,y,colors(j,:));
          hold on
       end
    end
    set(ax,'ytick',[])
    xlimits = get(gca,'xlim');
    myXticks = xlimits(1):(xlimits(2)-xlimits(1))/(nColors+1):xlimits(2)...
       -((xlimits(2)-xlimits(1))/(nColors+1));
    set(gca,'xtick',myXticks);
    
    myStr{1} = ' ';
    for kk = 1:nColors
       myStr{kk+1} = num2str(color_bar_labels(kk));
    end
    myStr{(nColors+2)} = ' ';
    set(gca,'XTickLabel',myStr)
    set(gca,'CLim',caxis(h))  %version 1.7 changed by Povl Abrahamsen

    % set up axes deletefcn
    set(ax,'tag','Colorbar','deletefcn','colorbar(''delete'')')
    
else
  error('COLORBAR expects a handle, ''vert'', or ''horiz'' as input.')
end

if ~isfield(ud,'DeleteProxy'), ud.DeleteProxy = []; end
if ~isfield(ud,'origPos'), ud.origPos = []; end
ud.PlotHandle = h;
set(ax,'userdata',ud)
set(gcf,'CurrentAxes',h)
set(gcf,'NextPlot',origNextPlot)

if nargout>0, hcb = ax; end
