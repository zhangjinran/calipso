function block = Fun_Make_Block(topbin_cell,basebin_cell,Para_Cell,type)

global Lidar_Data_Altitudes
topbin_5km       = topbin_cell{1,1};
basebin_5km      = basebin_cell{1,1};
topbin_20km      = topbin_cell{1,2};
basebin_20km     = basebin_cell{1,2};
topbin_80km      = topbin_cell{1,3};
basebin_80km     = basebin_cell{1,3};
Para_5km         = Para_Cell{1,1};
Para_20km        = Para_Cell{1,2};
Para_80km        = Para_Cell{1,3};

block = nan(length(Lidar_Data_Altitudes),size(topbin_5km,1));

%make block
if strcmp(type,'Cloud')
step = 16;
for i = 1:size(topbin_80km,1)
    for j = 1:size(topbin_80km,2)
        if ~isnan(topbin_80km(i,j))
            topbin_cur = topbin_80km(i,j);
            basebin_cur = basebin_80km(i,j);
            block(topbin_cur:basebin_cur,(i-1)*step+1:i*step) = Para_80km(i,j);
        end
    end
end
step = 4;
for i = 1:size(topbin_20km,1)
    for j = 1:size(topbin_20km,2)
        if ~isnan(topbin_20km(i,j))
            topbin_cur = topbin_20km(i,j);
            basebin_cur = basebin_20km(i,j);
            block(topbin_cur:basebin_cur,(i-1)*step+1:i*step) = Para_20km(i,j);
            
        end
    end
end
step = 1;
for i = 1:size(topbin_5km,1)
    for j = 1:size(topbin_5km,2)
        if ~isnan(topbin_5km(i,j))
            topbin_cur = topbin_5km(i,j);
            basebin_cur = basebin_5km(i,j);
            block(topbin_cur:basebin_cur,(i-1)*step+1:i*step) = Para_5km(i,j);
            
        end
    end
end


elseif strcmp(type,'Aerosol')
    
    Tropospheric_Type_5km   = Para_Cell{1,4};
    Tropospheric_Type_20km  = Para_Cell{1,5};
    Tropospheric_Type_80km  = Para_Cell{1,6};
    step = 16;
    for i = 1:size(topbin_80km,1)
        for j = 1:size(topbin_80km,2)
            if ~isnan(topbin_80km(i,j))
                topbin_cur = topbin_80km(i,j);
                basebin_cur = basebin_80km(i,j);
                if Tropospheric_Type_80km(i,j) == 3
                    block(topbin_cur:basebin_cur,(i-1)*step+1:i*step) = Para_80km(i,j);
                elseif Tropospheric_Type_80km(i,j) == 4
                    if Para_80km(i,j) == 4
                        block(topbin_cur:basebin_cur,(i-1)*step+1:i*step) = Para_80km(i,j) + 2;
                    else
                        block(topbin_cur:basebin_cur,(i-1)*step+1:i*step) = Para_80km(i,j) + 7;
                    end
                end
                
            end
        end
    end
    step = 4;
    for i = 1:size(topbin_20km,1)
        for j = 1:size(topbin_20km,2)
            if ~isnan(topbin_20km(i,j))
                topbin_cur = topbin_20km(i,j);
                basebin_cur = basebin_20km(i,j);
                if Tropospheric_Type_20km(i,j) == 3
                    block(topbin_cur:basebin_cur,(i-1)*step+1:i*step) = Para_20km(i,j);
                elseif Tropospheric_Type_20km(i,j) == 4
                    if Para_20km(i,j) == 4
                        block(topbin_cur:basebin_cur,(i-1)*step+1:i*step) = Para_20km(i,j) + 2;
                    else
                        block(topbin_cur:basebin_cur,(i-1)*step+1:i*step) = Para_20km(i,j) + 7;
                    end
                end
                
            end
        end
    end
    step = 1;
    for i = 1:size(topbin_5km,1)
        for j = 1:size(topbin_5km,2)
            if ~isnan(topbin_5km(i,j))
                topbin_cur = topbin_5km(i,j);
                basebin_cur = basebin_5km(i,j);
                if Tropospheric_Type_5km(i,j) == 3
                    block(topbin_cur:basebin_cur,(i-1)*step+1:i*step) = Para_5km(i,j);
                elseif Tropospheric_Type_5km(i,j) == 4
                    if Para_5km(i,j) == 4
                        block(topbin_cur:basebin_cur,(i-1)*step+1:i*step) = Para_5km(i,j) + 2;
                    else
                        block(topbin_cur:basebin_cur,(i-1)*step+1:i*step) = Para_5km(i,j) + 7;
                    end
                end
            end
        end
    end
    
    
    
end



end