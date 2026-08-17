function [ horizon_resolu_data ] = Fun_horizontal_resolution_Change(horizontal_resolution,beta_m_berore,beta_m_1064_before,beta_O3_before,TAB_532_before,Lat_before,Lon_before,Attenuated_Backscatter_1064_before,VAB_532_before)
% 改变数据的水平分辨率

% 输入信息：
% horizontal_resolution：                水平分辨率
% beta_m_berore：                        空气分子后向散射系数（532） (全分辨率下的数据)
% beta_O3_before：                       臭氧分子后向散射系数（532） (全分辨率下的数据)
% beta_m_1064_before：                   空气分子后向散射系数（1064）(全分辨率下的数据)
% TAB_532_before：                       532nm衰减后向散射系数      (全分辨率下的数据)
% Attenuated_Backscatter_1064_before：   1064nm衰减后向散射系数     (全分辨率下的数据)

% 输出信息：
% TAB_532：                              532nm衰减后向散射系数    (分辨率改变后)
% beta_m：                               532空气分子后向散射系数 （分辨率改变后）
% B_532：                                532校正衰减后向散射系数 （分辨率改变后）
% B_1064：                               1064校正衰减后向散射系数（分辨率改变后）
% asr：                                  衰减散射比序列         （分辨率改变后）
% Threshold_ASR：                        衰减散射比阈值         （分辨率改变后）
% Threshold_spike：                      衰减散射比峰顶阈值      （分辨率改变后）


%% START
% 画图参数预设
gray=[0.6,0.6,0.6];red   =[192/255,38/255,47/255];  blue=[27/255,72/255,158/255];
black=[0,0,0];     yellow=[242/255,145/255,42/255]; green=[40/255,160/255,40/255];

global Lidar_Data_Altitudes
global Day_Night_Flag;
global spike_threshold_factor;
global T0;
global T1;



%% 水平分辨率为1/3km时计算层次检测需要的值
if horizontal_resolution==1/3
    
    Lat                         = Lat_before;
    Lon                         = Lon_before;
    beta_m                      = beta_m_berore;
    beta_O3                     = beta_O3_before;
    beta_m_1064                 = beta_m_1064_before;
    TAB_532                     = TAB_532_before;
    Attenuated_Backscatter_1064 = Attenuated_Backscatter_1064_before;
    VAB_532                     = VAB_532_before;

    % 计算其他需要用到的量
    alpha_m       = beta_m*8*pi/3;          % 单位（个/km）
    alpha_O3      = beta_O3;                % 单位（个/km）
    alpha_m_1064  = beta_m_1064*8*pi/3;     % 单位（个/km）
    for i=1:size(beta_m,1)                  % 矩阵除法要求两矩阵必须具有相同的行和列，所以此处要用for循环。
        T2_m(i,:)                = exp(-2.*(-cumtrapz(Lidar_Data_Altitudes,alpha_m(i,:))));              % 532空气分子双向透过率
        T2_O3(i,:)               = exp(-2.*(-cumtrapz(Lidar_Data_Altitudes,alpha_O3(i,:))));              % 532臭氧分子双向透过率
        T2_m_1064(i,:)           = exp(-2.*(-cumtrapz(Lidar_Data_Altitudes,alpha_m_1064(i,:))));         % 1064空气分子双向透过率
        B_532(i,:)               = TAB_532(i,:)./(T2_m(i,:).*T2_O3(i,:));             % 532校正衰减后向散射系数
        VB_532(i,:)               = VAB_532(i,:)./(T2_m(i,:).*T2_O3(i,:));             % 532校正衰减后向散射系数
        B_1064(i,:)              = Attenuated_Backscatter_1064(i,:)./T2_m_1064(i,:);  % 1064校正衰减后向散射系数
        AttBackscatCoef_air(i,:) = beta_m(i,:).*T2_m(i,:).*T2_O3(i,:);                % 清洁大气衰减后向散射系数。
        AttBackscatCoef_air_1064(i,:) = beta_m_1064(i,:).*T2_m_1064(i,:);             % 清洁大气衰减后向散射系数。
    end
    asr = TAB_532./AttBackscatCoef_air; % 衰减散射比
    asr_1064=Attenuated_Backscatter_1064./AttBackscatCoef_air_1064;    
    % 计算了一系列初始阈值序列
    for i=1:size(beta_m,1)
        clear output1;
        % 532nm通道构建的阈值
        MBV_30_40km(i) =double(nanstd(TAB_532(i,1:33),1));% MBV（measured backscatter variation）为不变噪声，可通过计算30.1—40.0km高度区域测得的衰减后向散射系数的标准偏差来获得近似值。
        RBV(i,:)       = sqrt(AttBackscatCoef_air(i,:).*AttBackscatCoef_air(i,1));%RBV（relative backscatter variation）为相对噪声。
        MBV(i,1:33)    = MBV_30_40km(i);      
        MBV(i,34:88)   = MBV_30_40km(i)*sqrt(5) ;
        MBV(i,89:288)  = MBV_30_40km(i)*5;
        MBV(i,289:578) = MBV_30_40km(i)*5*sqrt(6);
        MBV(i,579:583) = MBV_30_40km(i)*sqrt(15);
        % 1064nm通道构建的阈值
        MBV_20_30km_1064(i) = double(nanstd(Attenuated_Backscatter_1064(i,34:88),1));% MBV（measured backscatter variation）为不变噪声，可通过计算30.1—40.0km高度区域测得的衰减后向散射系数的标准偏差来获得近似值。
        MBV_1064(i,1:33)    = nan(1,33);      
        MBV_1064(i,34:88)   = MBV_20_30km_1064(i) ;
        MBV_1064(i,89:288)  = MBV_20_30km_1064(i)*sqrt(5);
        MBV_1064(i,289:578) = MBV_20_30km_1064(i)*sqrt(15);
        MBV_1064(i,579:583) = MBV_20_30km_1064(i)*sqrt(3);
        if strcmpi(Day_Night_Flag,'N')
            flag = 1;
        else
            flag = 2;
        end
        Threshold_AttBackscat_Coef(i,:) =AttBackscatCoef_air(i,:)+T0(flag).*MBV(i,:)+T1(flag).*RBV(i,:)+1*0.0075;% 衰减散射系数阈值。
        Threshold_ASR(i,:)              =Threshold_AttBackscat_Coef(i,:)./AttBackscatCoef_air(i,:);
        Threshold_spike(i,:)            =Threshold_ASR(i,:)*spike_threshold_factor(flag); % 尖峰阈值因子？
%         output1 = Fun_select_suitable_clear_air(0,asr(i,:),PBL_nominal,[],24,[]);
%         T2_above(i) = nanmean(asr(i,output1.startbin:output1.endbin));
%         beta_MaxAerosol_filled = beta_MaxAerosol*ones(1,583);
%         horizon_resolu_data.PBL_Threshold(i,:) = T2_above(i)*(AttBackscatCoef_air_1064(i,:)+T0(flag)*MBV_1064(i,:)+T2*beta_MaxAerosol_filled); % 1064nm通道的衰减散射系数阈值
    end
end

%% 水平分辨率为1km时计算层次检测需要的值
if horizontal_resolution==1
    if rem(size(beta_m_berore,1),3) ~= 0 % 如果不能取整，
        number_replenish   = ceil(size(beta_m_berore,1)/3)*3 - size(beta_m_berore,1); % 需要补充多少行数据才能凑整。
        beta_m_berore      = cat(1,beta_m_berore,nan(number_replenish,size(beta_m_berore,2)));
        beta_O3_before     = cat(1,beta_O3_before,nan(number_replenish,size(beta_O3_before,2)));
        beta_m_1064_before = cat(1,beta_m_1064_before,nan(number_replenish,size(beta_m_1064_before,2)));
        if size(TAB_532_before,1) < size(beta_m_berore,1)    % 如果TAB行数小于更新补充后的beta_m行数，
            TAB_532_before = cat(1,TAB_532_before,nan(number_replenish,size(TAB_532_before,2)));
        end
        VAB_532_before=cat(1,VAB_532_before,nan(number_replenish,size(VAB_532_before,2)));
        Attenuated_Backscatter_1064_before = cat(1,Attenuated_Backscatter_1064_before,nan(number_replenish,size(Attenuated_Backscatter_1064_before,2)));
        Lat_before                         = cat(1,Lat_before,nan(number_replenish,size(Lat_before,2)));
        Lon_before                         = cat(1,Lon_before,nan(number_replenish,size(Lon_before,2)));
    end
    
    for i=1:size(beta_m_berore,1)/3 
        Lat(i,:)                             =[Lat_before(3*i-2);Lat_before(3*i)];
        Lon(i,:)                             = [Lon_before(3*i-2);Lon_before(3*i)];
        beta_m(i,1:583)                      = nanmean(beta_m_berore(3*i-2:3*i,1:583));
        beta_O3(i,1:583)                     = nanmean(beta_O3_before(3*i-2:3*i,1:583));
        beta_m_1064(i,1:583)                 = nanmean(beta_m_1064_before(3*i-2:3*i,1:583));
        TAB_532(i,1:583)                     = nanmean(TAB_532_before(3*i-2:3*i,1:583));
        Attenuated_Backscatter_1064(i,1:583) = nanmean(Attenuated_Backscatter_1064_before(3*i-2:3*i,1:583));
        VAB_532(i,1:583)                     = nanmean(VAB_532_before(3*i-2:3*i,1:583));
    end
    
    % 计算其他需要用到的量
    alpha_m       = beta_m*8*pi/3;               % 单位（个/km）
    alpha_O3      = beta_O3;               % 单位（个/km）
    alpha_m_1064  = beta_m_1064*8*pi/3;     % 单位（个/km）
    for i=1:size(beta_m,1)            % 矩阵除法要求两矩阵必须具有相同的行和列，所以此处要用for循环。
        T2_m(i,:)                = exp(-2.*(-cumtrapz(Lidar_Data_Altitudes,alpha_m(i,:))));              % 532空气分子双向透过率
        T2_O3(i,:)               = exp(-2.*(-cumtrapz(Lidar_Data_Altitudes,alpha_O3(i,:))));              % 532臭氧分子双向透过率
        T2_m_1064(i,:)           = exp(-2.*(-cumtrapz(Lidar_Data_Altitudes,alpha_m_1064(i,:))));         % 1064空气分子双向透过率
        B_532(i,:)               = TAB_532(i,:)./(T2_m(i,:).*T2_O3(i,:));% 532校正衰减后向散射系数
        VB_532(i,:)               = VAB_532(i,:)./(T2_m(i,:).*T2_O3(i,:));             % 532校正衰减后向散射系数
        B_1064(i,:)              = Attenuated_Backscatter_1064(i,:)./T2_m_1064(i,:);  % 1064校正衰减后向散射系数
        AttBackscatCoef_air(i,:) = beta_m(i,:).*T2_m(i,:).*T2_O3(i,:);                % 清洁大气衰减后向散射系数。
        AttBackscatCoef_air_1064(i,:) = beta_m_1064(i,:).*T2_m_1064(i,:);             % 清洁大气衰减后向散射系数。
    end
    asr = TAB_532./AttBackscatCoef_air; % 衰减散射比
    asr_1064=Attenuated_Backscatter_1064./AttBackscatCoef_air_1064;    
    % 计算了一系列初始阈值序列(计算MBV、RBV)
    for i=1:size(beta_m,1)
        MBV_30_40km(i) =double(nanstd(TAB_532(i,1:33),1));% MBV（measured backscatter variation）为不变噪声，可通过计算30.1—40.0km高度区域测得的衰减后向散射系数的标准偏差来获得近似值。
        RBV(i,:)       = sqrt(AttBackscatCoef_air(i,:).*AttBackscatCoef_air(i,1));%RBV（relative backscatter variation）为相对噪声。
        MBV(i,1:33)    = MBV_30_40km(i);
        MBV(i,34:88)   = MBV_30_40km(i)*sqrt(5) ;
        MBV(i,89:288)  = MBV_30_40km(i)*5;
        MBV(i,289:578) = MBV_30_40km(i)*5*sqrt(6);
        MBV(i,579:583) = MBV_30_40km(i)*sqrt(15);
        % 1064nm通道构建的阈值
        MBV_20_30km_1064(i) = double(nanstd(Attenuated_Backscatter_1064(i,34:88),1));% MBV（measured backscatter variation）为不变噪声，可通过计算30.1—40.0km高度区域测得的衰减后向散射系数的标准偏差来获得近似值。
        MBV_1064(i,1:33)    = nan(1,33);
        MBV_1064(i,34:88)   = MBV_20_30km_1064(i) ;
        MBV_1064(i,89:288)  = MBV_20_30km_1064(i)*sqrt(5);
        MBV_1064(i,289:578) = MBV_20_30km_1064(i)*sqrt(15);
        MBV_1064(i,579:583) = MBV_20_30km_1064(i)*sqrt(3);
        if strcmpi(Day_Night_Flag,'N')
            flag = 1;
        else
            flag = 2;
        end
        Threshold_AttBackscat_Coef(i,:) = AttBackscatCoef_air(i,:)+T0(flag).*MBV(i,:)+T1(flag).*RBV(i,:);% 衰减散射系数阈值。T0按高度序列取值，T1白天取值1.75，夜晚取值2.5。
        Threshold_ASR(i,:)              = Threshold_AttBackscat_Coef(i,:)./AttBackscatCoef_air(i,:);
        Threshold_spike(i,:)            = Threshold_ASR(i,:)*spike_threshold_factor(flag); % 尖峰阈值因子？
%         MBV_1064(i)                     = double(nanstd(Attenuated_Backscatter_1064(i,1:33),1));
    end
end

%% 水平分辨率为5km时计算层次检测需要的值
if horizontal_resolution==5
    if rem(size(beta_m_berore,1),15) ~= 0    % 如果不能取整，
        number_replenish   = ceil(size(beta_m_berore,1)/15)*15 - size(beta_m_berore,1); % 需要补充多少行数据才能凑整。
        beta_m_berore      = cat(1,beta_m_berore,nan(number_replenish,size(beta_m_berore,2)));
        beta_O3_before     = cat(1,beta_O3_before,nan(number_replenish,size(beta_O3_before,2)));
        beta_m_1064_before = cat(1,beta_m_1064_before,nan(number_replenish,size(beta_m_1064_before,2)));
        if size(TAB_532_before,1) < size(beta_m_berore,1)   % 如果TAB行数小于更新补充后的beta_m行数，则补充，否则不补充TAB
            TAB_532_before = cat(1,TAB_532_before,nan(number_replenish,size(TAB_532_before,2)));
            VAB_532_before=cat(1,VAB_532_before,nan(number_replenish,size(VAB_532_before,2)));
        end
        Attenuated_Backscatter_1064_before = cat(1,Attenuated_Backscatter_1064_before,nan(number_replenish,size(Attenuated_Backscatter_1064_before,2)));
        Lat_before                         = cat(1,Lat_before,nan(number_replenish,size(Lat_before,2)));
        Lon_before                         = cat(1,Lon_before,nan(number_replenish,size(Lon_before,2)));        
    end
    
   % ------------------- 主处理：每15行取平均 -------------------

% 1. 计算循环次数并预分配内存
n_rows = size(beta_m_berore, 1);
num_windows = floor(n_rows / 15);

% 预分配输出数组内存
Lat = zeros(num_windows, 3);
Lon = zeros(num_windows, 3);
beta_m = zeros(num_windows, size(beta_m_berore, 2)); % 使用原始数据的列数，更灵活
beta_O3 = zeros(num_windows, size(beta_O3_before, 2));
beta_m_1064 = zeros(num_windows, size(beta_m_1064_before, 2));
Attenuated_Backscatter_1064 = zeros(num_windows, size(Attenuated_Backscatter_1064_before, 2));

% 2. 循环处理数据
for i = 1:num_windows
    % 计算当前窗口的起始和结束索引
    start_idx = 15 * i - 14;
    end_idx = 15 * i;
    
    % 提取Lat和Lon（取第1, 8, 15个点）
    Lat(i, :) = [Lat_before(start_idx); Lat_before(start_idx + 7); Lat_before(end_idx)];
    Lon(i, :) = [Lon_before(start_idx); Lon_before(start_idx + 7); Lon_before(end_idx)];
    
    % ------------------- 核心修正部分 -------------------
    % 对每个数据矩阵的每一列，循环计算其在窗口内的平均值
    % beta_m
    for col = 1:size(beta_m_berore, 2)
        window_col_data = beta_m_berore(start_idx:end_idx, col);
        beta_m(i, col) = mean(window_col_data(~isnan(window_col_data)));
    end
    % beta_O3
    for col = 1:size(beta_O3_before, 2)
        window_col_data = beta_O3_before(start_idx:end_idx, col);
        beta_O3(i, col) = mean(window_col_data(~isnan(window_col_data)));
    end
    % beta_m_1064
    for col = 1:size(beta_m_1064_before, 2)
        window_col_data = beta_m_1064_before(start_idx:end_idx, col);
        beta_m_1064(i, col) = mean(window_col_data(~isnan(window_col_data)));
    end
    % Attenuated_Backscatter_1064
    for col = 1:size(Attenuated_Backscatter_1064_before, 2)
        window_col_data = Attenuated_Backscatter_1064_before(start_idx:end_idx, col);
        Attenuated_Backscatter_1064(i, col) = mean(window_col_data(~isnan(window_col_data)));
    end
    % ------------------------------------------------------
end


% ------------------- 条件处理：TAB_532 和 VAB_532 -------------------

% 检查输入数据的分辨率，以决定合并窗口大小
if size(TAB_532_before, 1) * 3 == size(beta_m_berore, 1)
    % 情况A：输入的是1km分辨率数据，每5行取平均
    n_rows_tab = size(TAB_532_before, 1);
    num_windows_tab = floor(n_rows_tab / 5);
    
    % 预分配内存
    TAB_532 = zeros(num_windows_tab, size(TAB_532_before, 2));
    VAB_532 = zeros(num_windows_tab, size(VAB_532_before, 2));
    
    % 循环处理
    for i = 1:num_windows_tab
        start_idx = 5 * i - 4;
        end_idx = 5 * i;
        
        % ------------------- 核心修正部分 -------------------
        for col = 1:size(TAB_532_before, 2)
            window_col_data = TAB_532_before(start_idx:end_idx, col);
            TAB_532(i, col) = mean(window_col_data(~isnan(window_col_data)));
        end
        for col = 1:size(VAB_532_before, 2)
            window_col_data = VAB_532_before(start_idx:end_idx, col);
            VAB_532(i, col) = mean(window_col_data(~isnan(window_col_data)));
        end
        % ------------------------------------------------------
    end
else
    % 情况B：输入的是原始全分辨率数据，每15行取平均
    % 预分配内存
    TAB_532 = zeros(num_windows, size(TAB_532_before, 2));
    VAB_532 = zeros(num_windows, size(VAB_532_before, 2));
    
    % 循环处理
    for i = 1:num_windows
        start_idx = 15 * i - 14;
        end_idx = 15 * i;
        
        % ------------------- 核心修正部分 -------------------
        for col = 1:size(TAB_532_before, 2)
            window_col_data = TAB_532_before(start_idx:end_idx, col);
            TAB_532(i, col) = mean(window_col_data(~isnan(window_col_data)));
        end
        for col = 1:size(VAB_532_before, 2)
            window_col_data = VAB_532_before(start_idx:end_idx, col);
            VAB_532(i, col) = mean(window_col_data(~isnan(window_col_data)));
        end
        % ------------------------------------------------------
    end
end

    % 计算其他需要用到的量
    alpha_m       = beta_m*8*pi/3;               % 单位（个/km）
    alpha_O3      = beta_O3;               % 单位（个/km）
    alpha_m_1064  = beta_m_1064*8*pi/3;     % 单位（个/km）
    for i=1:size(beta_m,1)            % 矩阵除法要求两矩阵必须具有相同的行和列，所以此处要用for循环。
        T2_m(i,:)                = exp(-2.*(-cumtrapz(Lidar_Data_Altitudes,alpha_m(i,:))));              % 532空气分子双向透过率
        T2_O3(i,:)               = exp(-2.*(-cumtrapz(Lidar_Data_Altitudes,alpha_O3(i,:))));              % 532臭氧分子双向透过率
        T2_m_1064(i,:)           = exp(-2.*(-cumtrapz(Lidar_Data_Altitudes,alpha_m_1064(i,:))));         % 1064空气分子双向透过率
        B_532(i,:)               = TAB_532(i,:)./(T2_m(i,:).*T2_O3(i,:));             % 532校正衰减后向散射系数
        VB_532(i,:)               = VAB_532(i,:)./(T2_m(i,:).*T2_O3(i,:));             % 532校正衰减后向散射系数
        B_1064(i,:)              = Attenuated_Backscatter_1064(i,:)./T2_m_1064(i,:);  % 1064校正衰减后向散射系数
        AttBackscatCoef_air(i,:) = beta_m(i,:).*T2_m(i,:).*T2_O3(i,:);                % 清洁大气衰减后向散射系数。
        AttBackscatCoef_air_1064(i,:) = beta_m_1064(i,:).*T2_m_1064(i,:);             % 清洁大气衰减后向散射系数。
    end
    asr = TAB_532./AttBackscatCoef_air; % 衰减散射比
    asr_1064=Attenuated_Backscatter_1064./AttBackscatCoef_air_1064;

end

%% 水平分辨率为20km时计算层次检测需要的值
if horizontal_resolution==20
    if rem(size(beta_m_berore,1),60) ~= 0   % 如果不能取整，
        number_replenish                   = ceil(size(beta_m_berore,1)/60)*60 - size(beta_m_berore,1); % 需要补充多少行数据才能凑整。
        beta_m_berore                      = cat(1,beta_m_berore,nan(number_replenish,size(beta_m_berore,2)));
        beta_O3_before                     = cat(1,beta_O3_before,nan(number_replenish,size(beta_O3_before,2)));
        beta_m_1064_before                 = cat(1,beta_m_1064_before,nan(number_replenish,size(beta_m_1064_before,2)));
        Attenuated_Backscatter_1064_before = cat(1,Attenuated_Backscatter_1064_before,nan(number_replenish,size(Attenuated_Backscatter_1064_before,2)));
        Lat_before                         = cat(1,Lat_before,nan(number_replenish,size(Lat_before,2)));
        Lon_before                         = cat(1,Lon_before,nan(number_replenish,size(Lon_before,2)));
    end
    
    for i=1:size(beta_m_berore,1)/60
        Lat(i,:)                             = [Lat_before(60*i-59);Lat_before(60*i)];
        Lon(i,:)                             = [Lon_before(60*i-59);Lon_before(60*i)];
        beta_m(i,1:583)                      = nanmean(beta_m_berore(60*i-59:60*i,1:583));
        beta_O3(i,1:583)                     = nanmean(beta_O3_before(60*i-59:60*i,1:583));
        beta_m_1064(i,1:583)                 = nanmean(beta_m_1064_before(60*i-59:60*i,1:583));
%         Attenuated_Backscatter_1064(i,1:583) = nanmean(Attenuated_Backscatter_1064_before(60*i-59:60*i,1:583));
    end
    
    for i=1:size(TAB_532_before,1)/4    % 输入的若是5km分辨率衰减校正后的TAB_532时
        TAB_532(i,1:583) = nanmean(TAB_532_before(4*i-3:4*i,1:583));     % 注意这里TAB_532的维度和其他数据不一样。
        VAB_532(i,1:583)  = nanmean(VAB_532_before(4*i-3:4*i,1:583));
        Attenuated_Backscatter_1064(i,1:583) = nanmean(Attenuated_Backscatter_1064_before(4*i-3:4*i,1:583));

    end
    
    % 计算其他需要用到的量
    alpha_m      = beta_m*8*pi/3;          % 单位（个/km）
    alpha_O3     = beta_O3;               % 单位（个/km）
    alpha_m_1064 = beta_m_1064*8*pi/3;     % 单位（个/km）
    for i=1:size(beta_m,1)                 % 矩阵除法要求两矩阵必须具有相同的行和列，所以此处要用for循环。
        T2_m(i,:)                = exp(-2.*(-cumtrapz(Lidar_Data_Altitudes,alpha_m(i,:))));              % 532空气分子双向透过率
        T2_O3(i,:)               = exp(-2.*(-cumtrapz(Lidar_Data_Altitudes,alpha_O3(i,:))));              % 532臭氧分子双向透过率
        T2_m_1064(i,:)           = exp(-2.*(-cumtrapz(Lidar_Data_Altitudes,alpha_m_1064(i,:))));         % 1064空气分子双向透过率
        B_532(i,:)               = TAB_532(i,:)./(T2_m(i,:).*T2_O3(i,:));             % 532校正衰减后向散射系数
        VB_532(i,:)               = VAB_532(i,:)./(T2_m(i,:).*T2_O3(i,:));             % 532校正衰减后向散射系数
        B_1064(i,:)              = Attenuated_Backscatter_1064(i,:)./T2_m_1064(i,:);  % 1064校正衰减后向散射系数
        AttBackscatCoef_air(i,:) = beta_m(i,:).*T2_m(i,:).*T2_O3(i,:);                % 清洁大气衰减后向散射系数。
        AttBackscatCoef_air_1064(i,:) = beta_m_1064(i,:).*T2_m_1064(i,:);             % 清洁大气衰减后向散射系数。
    end
    asr = TAB_532./AttBackscatCoef_air; % 衰减散射比
    asr_1064=Attenuated_Backscatter_1064./AttBackscatCoef_air_1064;
   
end

%% 水平分辨率为80km时计算层次检测需要的值
if horizontal_resolution==80
    if rem(size(beta_m_berore,1),240) ~= 0 % 如果不能取整，
        number_replenish                   = ceil(size(beta_m_berore,1)/240)*240 - size(beta_m_berore,1); % 需要补充多少行数据才能凑整。
        beta_m_berore                      = cat(1,beta_m_berore,nan(number_replenish,size(beta_m_berore,2)));
        beta_O3_before                     = cat(1,beta_O3_before,nan(number_replenish,size(beta_O3_before,2)));
        beta_m_1064_before                 = cat(1,beta_m_1064_before,nan(number_replenish,size(beta_m_1064_before,2)));
%         Attenuated_Backscatter_1064_before = cat(1,Attenuated_Backscatter_1064_before,nan(number_replenish,size(Attenuated_Backscatter_1064_before,2)));
        Lat_before                         = cat(1,Lat_before,nan(number_replenish,size(Lat_before,2)));
        Lon_before                         = cat(1,Lon_before,nan(number_replenish,size(Lon_before,2)));
    end
    
    for i=1:size(beta_m_berore,1)/240
        Lat(i,:)                             = [Lat_before(240*i-239);Lat_before(240*i)];
        Lon(i,:)                             = [Lon_before(240*i-239);Lon_before(240*i)];
        beta_m(i,1:583)                      = nanmean(beta_m_berore(240*i-239:240*i,1:583));
        beta_O3(i,1:583)                     = nanmean(beta_O3_before(240*i-239:240*i,1:583));
        beta_m_1064(i,1:583)                 = nanmean(beta_m_1064_before(240*i-239:240*i,1:583));
    end
    
    for i=1:size(TAB_532_before,1)/4   % 输入的若是20km分辨率衰减校正后的TAB_532时
        TAB_532(i,1:583) = nanmean(TAB_532_before(4*i-3:4*i,1:583));     % 注意这里TAB_532的维度和其他数据不一样。
        VAB_532(i,1:583)  = nanmean(VAB_532_before(4*i-3:4*i,1:583));
        Attenuated_Backscatter_1064(i,1:583) = nanmean(Attenuated_Backscatter_1064_before(4*i-3:4*i,1:583));

    end
    
    % 计算其他需要用到的量
    alpha_m      = beta_m*8*pi/3;          % 单位（个/km）
    alpha_O3      = beta_O3;               % 单位（个/km）
    alpha_m_1064 = beta_m_1064*8*pi/3;     % 单位（个/km）
    for i=1:size(beta_m,1)                 % 矩阵除法要求两矩阵必须具有相同的行和列，所以此处要用for循环。
        T2_m(i,:)                = exp(-2.*(-cumtrapz(Lidar_Data_Altitudes,alpha_m(i,:))));              % 532空气分子双向透过率
        T2_O3(i,:)               = exp(-2.*(-cumtrapz(Lidar_Data_Altitudes,alpha_O3(i,:))));              % 532臭氧分子双向透过率
        T2_m_1064(i,:)           = exp(-2.*(-cumtrapz(Lidar_Data_Altitudes,alpha_m_1064(i,:))));         % 1064空气分子双向透过率
        B_532(i,:)               = TAB_532(i,:)./(T2_m(i,:).*T2_O3(i,:));             % 532校正衰减后向散射系数
        VB_532(i,:)               = VAB_532(i,:)./(T2_m(i,:).*T2_O3(i,:));             % 532校正衰减后向散射系数
        B_1064(i,:)              = Attenuated_Backscatter_1064(i,:)./T2_m_1064(i,:);  % 1064校正衰减后向散射系数
        AttBackscatCoef_air(i,:) = beta_m(i,:).*T2_m(i,:).*T2_O3(i,:);                % 清洁大气衰减后向散射系数。
        AttBackscatCoef_air_1064(i,:) = beta_m_1064(i,:).*T2_m_1064(i,:);             % 清洁大气衰减后向散射系数。
    end
    asr = TAB_532./AttBackscatCoef_air; % 衰减散射比
     asr_1064=Attenuated_Backscatter_1064./AttBackscatCoef_air_1064;
   
end

%% 输出
horizon_resolu_data.Lat                        = Lat;
horizon_resolu_data.Lon                        = Lon;
horizon_resolu_data.TAB_532                    = TAB_532;
horizon_resolu_data.VAB_532                    = VAB_532;
horizon_resolu_data.VB_532                     = VB_532;
horizon_resolu_data.AB_1064                    =Attenuated_Backscatter_1064;
horizon_resolu_data.beta_m                     = beta_m;
horizon_resolu_data.beta_m_1064                     = beta_m_1064;
horizon_resolu_data.B_532                      = B_532;
horizon_resolu_data.B_1064                     = B_1064;
horizon_resolu_data.asr                        = asr;
horizon_resolu_data.asr_1064                        = asr_1064;
horizon_resolu_data.AttBackscatCoef_air        = AttBackscatCoef_air;
horizon_resolu_data.AttBackscatCoef_air_1064   = AttBackscatCoef_air_1064;
end
