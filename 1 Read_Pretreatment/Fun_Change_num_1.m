function [change_num]=Fun_Change_num(top_right_80km_change)
% 作者：罗熙，写于2019年3月7日
[m,n]=size(top_right_80km_change);
if m<=16
    error('The Range is too small');
end
tmp_num=mod(m,16);
tmp_array=zeros(m-15,n);
Row_Start=0;
for i=1:1:m-15
    if sum(isnan(top_right_80km_change(i,:)))==n
                tmp_array(i,:)=0;
                continue;
    end
    for j=1:1:15
        for k=1:1:n
            if ~isnan(top_right_80km_change(i,k))
                if (find(top_right_80km_change(i+j,:)==top_right_80km_change(i,k))==1)
                    tmp_array(i,k)=tmp_array(i,k)+1;  
                    if j>tmp_array(i,k)
                        tmp_array(i,k)=j;
                    end
                end
            end
        end
    end
    Imax=max(tmp_array(i,:));
    if Imax==15
        Row_Start=i;
        break;
    end
end

% 可注释
% if Imax~=15
%     error('Cannot find the continuous 80km Layer ');
% end
change_num(1)=mod(Row_Start,16)-1;
if change_num(1)<0
    change_num(1)=15;
end
change_num(2)=mod((m-change_num(1)),16);
end