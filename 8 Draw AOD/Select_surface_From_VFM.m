function [surface_mask] = Select_surface_From_VFM(vfm,lims,type)

surface_mask=ones(lims(2),1);

for i=1:lims(2)
    [block,TypeText] = vfm_row2block(vfm(i,:),type);
    for j=1:size(block,2)
        if any(block(:,j)==5)
        else
            surface_mask(i,1)=0;
            continue
        end
    end
end