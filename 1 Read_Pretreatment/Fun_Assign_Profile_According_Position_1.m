function [output]=Fun_Assign_Profile_According_Position(input,pos,resolution)
%% Pos:坐标
% Pos.Row:不重复属性值的行
% Pos.Col:不重复属性行的列
% [Pos(i).Row(j),Pos(i).Col(j)]定位到属性值
% Pos.index:表示属性值进行排序前的位置
%%
if resolution==20
    n=4;
elseif resolution==80
    n=16;
end
%%
output_temp = nan(size(input,1)/n,size(input,2)); % 预分配空间
output= nan(size(input,1)/n,size(input,2)); % 预分配空间
for  i = 1:size(input,1)/n
     input_temp=input(n*(i-1)+1:n*i,:);
     Row_temp=pos(i).Row;
     Col_temp=pos(i).Col;
     Len=length(Row_temp);
     for j=1:Len
         output_temp(i,j)=input_temp(Row_temp(j),Col_temp(j));
     end
     index=pos(i).index;
     output(i,1:Len)=output_temp(i,index);
end
end
