function [zcrData,zcrMax,zcrMean]=zcrGen(cntFrame,frame_len,frame)

 %zcr ±¸ÇÏ±â
zcrData=zeros(1,cntFrame);

for j=1:cntFrame
    for k=1:frame_len-1
         zcrData(1,j)=zcrData(1,j)+abs(sgn(frame(j,k+1))-sgn(frame(j,k)))*forzcr(frame_len-k,frame_len);
    end
end
    zcrMax=max(zcrData);
    zcrMean=mean(zcrData);
end