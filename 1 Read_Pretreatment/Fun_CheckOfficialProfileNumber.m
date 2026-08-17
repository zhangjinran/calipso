function [ output,Pos ] = Fun_CheckOfficialProfileNumber( input,variable_name,n )
% 预处理（把官方给的20、80km层次结果变成和我检测的20km廓线条数相同） 
% ...因20km和80km分辨率的层次结果都在5km产品中报告，所以在官方层次中它们的廓线条数都与5km廓线条数相同，
% ...这里要进行对比时需要进行廓线条数纠正。以便后续与我检测出的结果对比。

% 输入信息
% input： 输入的待调整的数据
% variable_name:    字段名称
% n：       要获得nkm分辨率正常的数据，只可以是20或80
% 输出信息
% output： 输出的已调整后的数据
% Pos.Row:不重复属性值的行
% Pos.Col:不重复属性行的列
% [Pos(i).Row(j),Pos(i).Col(j)]定位到属性值
% Pos.index:表示属性值进行排序前的位置
%---------2020.09.15liang修改:原本其他字段（第三种情况）寻找的是非NaN最多的行，但有时两行都只是一个非NaN,而且数不一样------------%
%%
if  ~isempty(strfind (variable_name,'top_right')) || ~isempty(strfind (variable_name,'base_right')) ,  % 第一种情况（层底层高km从高往低排）
    if n == 20   % 如果想变成20km分辨率正常廓线条数
        output = nan(size(input,1)/4,size(input,2)); % 预分配空间
        for  i = 1:size(input,1)/4
            clear U   z ;
            input_temp=input(4*i-3:4*i,:);
            U = unique(input_temp);
            %寻找这些不重复值的位置，为其他属性值的分配提供坐标（对其他属性进行分配时，需根据层次位置信息进行分配）
            U_temp=U;U_temp(isnan(U_temp))=[];
            if ~isempty(U_temp)
                L=length(U_temp);
                for k=1:L
                    [Pos(i).Row(k),Pos(i).Col(k)]=find(input_temp==U(k),1,'first');
                end
            end
            %排序后的位置信息
            [z,Pos(i).index] = sort(U(~isnan(U)),'descend');
            for j = 1:length(z)
                output(i,j) = z(j);
            end
        end
    else
        if n == 80
            if rem(size(input,1),16) ~= 0    % 如果不能取整，
                number_replenish = ceil(size(input,1)/16)*16 - size(input,1); % 需要补充多少行数据才能凑整。
                input            = cat(1,input,nan(number_replenish,size(input,2)));
            end
            output = nan(size(input,1)/16,size(input,2)); % 预分配空间
            for  i = 1:size(input,1)/16
                clear U   z ;
                input_temp=input(16*i-15:16*i,:);
                U = unique(input_temp);
                %寻找这些不重复值的位置，为其他属性值的分配提供坐标（对其他属性进行分配时，需根据层次位置信息进行分配）
                U_temp=U;U_temp(isnan(U_temp))=[];
                if ~isempty(U_temp)
                    L=length(U_temp);
                    for k=1:L
                        [Pos(i).Row(k),Pos(i).Col(k)]=find(input_temp==U(k),1,'first');
                    end
                end
              %排序后的位置信息
              [z,Pos(i).index] = sort(U(~isnan(U)),'descend');
                for j = 1:length(z)
                    output(i,j) = z(j);
                end
            end
        end
    end
end
end

                                    
                                        



                            
            
            
        
 
































