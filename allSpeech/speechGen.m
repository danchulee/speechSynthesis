function speechData=speechGen(cntFrame,frame_len,length,a,signal,power)

tmp=zeros(cntFrame,frame_len);
speechData=zeros(1,length);

for j=1:cntFrame
   tmp(j,:)=filter(1,a(j,:),signal(j,:));
   tmp(j,:)=power(1,j).*tmp(j,:);
end

%ù �� ��ġ�� �κ�
speechData(1,1:frame_len/2)=tmp(1,1:frame_len/2);
for j=1:cntFrame-1
   speechData(1,j*frame_len/2+1:(j+1)*frame_len/2)=tmp(j,frame_len/2+1:frame_len);
   speechData(1,j*frame_len/2+1:(j+1)*frame_len/2)=speechData(1,j*frame_len/2+1:(j+1)*frame_len/2)+tmp(j+1,1:frame_len/2);
end
%�� �� ��ġ�� �κ�
speechData(1,length-frame_len/2+1:length)=tmp(cntFrame,frame_len/2+1:frame_len);

end