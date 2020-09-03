function energyData=energyGen(cntFrame,frame_len,frame)

energyData=zeros(1,cntFrame);
window=hamming(frame_len,'periodic');

for j=1:cntFrame
   for k=1:frame_len
       energyData(1,j)=energyData(1,j)+(frame(j,k).*window(k))^2;
   end
end

energyData=sqrt(energyData);
end