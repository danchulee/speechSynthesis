function [corrFrame,pitch]=acf(cntFrame,frame_len,frame)

corrFrame=zeros(cntFrame,frame_len*2-1);
pitch=zeros(1,cntFrame);
Fs=16000;
Ts=1/Fs;

for r=1:cntFrame
    corrFrame(r,:)=xcorr(frame(r,:));
    l=length(corrFrame);
    corrFrame(r,500:520)=0;

    [pks_corr,locs_corr]=findpeaks(corrFrame(r,:));

    [mm, mm_i]=max(pks_corr);
    pks_corr(mm_i)=0;
    [mm2,mm_i2]=max(pks_corr);
    period=abs(locs_corr(mm_i2)-locs_corr(mm_i))/Fs;
    pitch(1,r)=1/period;
end

end