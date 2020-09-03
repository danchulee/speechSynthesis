function signal=sigGen(cntFrame,frame_len,pitch,vuv)
    
pulse=zeros(cntFrame,frame_len);

for j=1:cntFrame
    pulse(j,1:ceil(pitch(1,j)):frame_len)=1;
end

noise=wgn(cntFrame,frame_len,0)/3;
signal=zeros(cntFrame,frame_len);

for j=1:cntFrame
   if vuv(1,j)==0 %voice
      signal(j,:)=pulse(j,:);
   else           %unvoice
      signal(j,:)=noise(j,:);
   end
end

end