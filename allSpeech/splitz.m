function [splits,zcrs,powers,vuvs]=splitz(frame,frame_len)

    splits=zeros(2,0.5*frame_len);
    splits(1,:)=frame(1:0.5*frame_len);
    splits(2,:)=frame(0.5*frame_len+1:frame_len);
    
    zcrs=zeros(1,2);
    for j=1:2
        for k=1:0.5*frame_len-1
            tframe=splits(j,:);
            zcrs(1,j)=zcrs(1,j)+abs(sgn(tframe(1,k+1))-sgn(tframe(1,k)))*forzcr(frame_len-k,frame_len);
        end
    end
    
    powers=zeros(1,2);
    window=hamming(frame_len,'periodic');
    for j=1:2
        for k=1:0.5*frame_len
            tframe=splits(j,:);
            powers(1,j)=powers(1,j)+(tframe(1,k).*window(k))^2;
        end
    end
    powers=sqrt(powers);
    
    vuvs=zeros(1,2);
    vuvs=vuvGen(2,zcrs,powers);
    
    
end