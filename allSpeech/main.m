clear all; close all; clc;

% (1) filename     (5) zcr        (9)  noise       (13) pitch
% (2) length       (6) power      (10) pulse       (14) a-lpc coefficients
% (3) cntFrame     (7) corrFrame  (11) signal
% (4) frames       (8) vuv        (12) speech

%여자 무성음 frame 하나 zcr
%남자 무성음 frame 하나 zcr

file = struct;

file(1).filename='남자무성음';   file(2).filename='여자무성음';  
file(3).filename='연아는';   file(4).filename='먼저';   file(5).filename='나갔냐';    file(6).filename='연아는2';
file(7).filename='먼저2'; file(11).filename='이제'; file(12).filename='시작이네';


file(8).filename='남연아는'; file(9).filename='남먼저'; file(10).filename='남나갔냐';



file(11).vuvtemp=[0,0,0,0,0,0,1,1,0,0,0,0,0];
file(12).vuvtemp=[1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0];
file(3).vuvtemp=[0,0,0,0,0,0,0,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1];
file(4).vuvtemp=[0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0];
file(5).vuvtemp=[0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
file(6).vuvtemp=[0,0,0,0,0,0,0,1,1,1,0,0,1,1,1,1,1,1,1,1,1,1,1,1];
file(7).vuvtemp=[0,0,0,0,0,0,0,0,0,1,1,0,0,0,0];
file(8).vuvtemp=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
file(9).vuvtemp=[0,0,0,0,0,0,1,0,0,0,0,0];
file(10).vuvtemp=[0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];





for i=1:12
    if i==1
        [x,Fs]=audioread('input/남자무.wav');
    elseif i==2
        [x,Fs]=audioread('input/여자무.wav');
    elseif i==3
        [x,Fs]=audioread('input/연아는.wav');
    elseif i==4
        [x,Fs]=audioread('input/먼저.wav');
    elseif i==5
        [x,Fs]=audioread('input/나갔냐.wav');
    elseif i==6
        [x,Fs]=audioread('input/연아는2.wav');
    elseif i==7
        [x,Fs]=audioread('input/먼저2.wav');
    elseif i==8
        [x,Fs]=audioread('input/남연아는.wav');
    elseif i==9
        [x,Fs]=audioread('input/남먼저.wav');
    elseif i==10
        [x,Fs]=audioread('input/남나갔냐.wav');
    elseif i==11
        [x,Fs]=audioread('input/이제.wav');
    elseif i==12
        [x,Fs]=audioread('input/시작이네.wav');
    end
    
    file(i).origin=x;
    
    Fs=16000;
    len_x=length(x);
    fprintf("샘플 수 : %d\n", len_x);

    y=normalization(x);
    file(i).length=length(y);
    Ts=1/Fs; %샘플주기

    frame_size=0.032;
    frame_len=frame_size*Fs;
    h_frame_len=frame_len*0.5;
   
    file(i).cntFrame=floor(file(i).length/(0.5*frame_len))-1; %512samples 씩 프레임 개수
    
    file(i).frame=zeros(file(i).cntFrame,frame_len);
    for j=1:file(i).cntFrame %프레임 쪼개기
        file(i).frame(j,:)=y(h_frame_len*(j-1)+1:h_frame_len*(j-1)+frame_len);
    end
    
    window=hamming(frame_len,'periodic');
    for j=1:file(i).cntFrame %각각의 프레임 windowing
        file(i).frame(j,:)=file(i).frame(j,:).*window';
    end

    %zcr 구하기
    [file(i).zcr,file(i).zcrmax,file(i).zcrmean]=zcrGen(file(i).cntFrame,frame_len,file(i).frame);
    
    %power 구하기
    file(i).power=energyGen(file(i).cntFrame,frame_len,file(i).frame);
    
    boyzcr=mean(file(1).zcr);
    girlzcr=mean(file(2).zcr);
    boypower=mean(file(1).power);
    girlpower=mean(file(2).power);
    
    %acf
    [file(i).corrFrame,file(i).pitch]=acf(file(i).cntFrame,frame_len,file(i).frame);
    
    lpc_order=10;
    
    %vuv
    file(i).vuv=vuvGen(file(i).cntFrame,file(i).zcr,file(i).power);
%     if i>=3&&i<=7||i==11||i==12
%         file(i).vuv=vuvGen(file(i).cntFrame,file(i).zcr,file(i).power,girlzcr,girlpower);
%     elseif i>=8&&i<=10
%         file(i).vuv=vuvGen(file(i).cntFrame,file(i).zcr,file(i).power,boyzcr,boypower);
%     else
%         file(i).vuv=vuvGen(file(i).cntFrame,file(i).zcr,file(i).power);
%     end
   

    %lpc 구하기
    file(i).a=zeros(file(i).cntFrame,lpc_order);
    for j=1:file(i).cntFrame
       file(i).a(j,:)=lpc(file(i).frame(j,:),lpc_order-1); 
    end

    %frame에 곱할 signal generator
    file(i).signal=sigGen(file(i).cntFrame,frame_len,file(i).pitch,file(i).vuv);
    if i>=3&&i<=12
        file(i).signal2=sigGen(file(i).cntFrame,frame_len,file(i).pitch,file(i).vuvtemp);
    end
    
    %음성합성
    file(i).speech=speechGen(file(i).cntFrame,frame_len,file(i).length,file(i).a,file(i).signal,file(i).power);
    if i>=3&&i<=12
        file(i).speech2=speechGen(file(i).cntFrame,frame_len,file(i).length,file(i).a,file(i).signal2,file(i).power);
    end
    
    if i==11
        audiowrite(['output/이제set' num2str(lpc_order) '.wav'], file(i).speech, Fs );
        %audiowrite(['output/이제n' num2str(lpc_order) '.wav'], file(i).speech, Fs );
    elseif i==12
        audiowrite(['output/시작이네set' num2str(lpc_order) '.wav'], file(i).speech, Fs );
        %audiowrite(['output/시작이네n' num2str(lpc_order) '.wav'], file(i).speech2, Fs );
    elseif i==3
        audiowrite(['output/연아는set' num2str(lpc_order) '.wav'], file(i).speech, Fs );
        %audiowrite(['output/연아는n' num2str(lpc_order) '.wav'], file(i).speech2, Fs );
    elseif i==4
        audiowrite(['output/먼저set' num2str(lpc_order) '.wav'], file(i).speech, Fs );
        %audiowrite(['output/먼저n' num2str(lpc_order) '.wav'], file(i).speech2, Fs );
    elseif i==5
        audiowrite(['output/나갔냐set' num2str(lpc_order) '.wav'], file(i).speech, Fs );   
        %audiowrite(['output/나갔냐n' num2str(lpc_order) '.wav'], file(i).speech2, Fs );   
    elseif i==6
        audiowrite(['output/연아는2set' num2str(lpc_order) '.wav'], file(i).speech, Fs );
        %audiowrite(['output/연아는2n' num2str(lpc_order) '.wav'], file(i).speech2, Fs );
    elseif i==7
        audiowrite(['output/먼저2set' num2str(lpc_order) '.wav'], file(i).speech, Fs );
        %audiowrite(['output/먼저2n' num2str(lpc_order) '.wav'], file(i).speech2, Fs );
    elseif i==8
        audiowrite(['output/남연아는2set' num2str(lpc_order) '.wav'], file(i).speech, Fs );   
        %audiowrite(['output/남연아는2n' num2str(lpc_order) '.wav'], file(i).speech2, Fs );   
    elseif i==9
        audiowrite(['output/남먼저2set' num2str(lpc_order) '.wav'], file(i).speech, Fs );  
        %audiowrite(['output/남먼저2n' num2str(lpc_order) '.wav'], file(i).speech2, Fs );  
    elseif i==10
        audiowrite(['output/남나갔냐2set' num2str(lpc_order) '.wav'], file(i).speech, Fs );  
        %audiowrite(['output/남나갔냐2n' num2str(lpc_order) '.wav'], file(i).speech2, Fs );  
    end
  
end
%무성음 zcr



% for i=1:10
%     while file(i).vuv==2
%         for j=1:file(i).cntFrame
%             if file(i).vuv(1,j)==2
%                 [tempframe,tempzcr,tempower,tempvuv]=splitz(file(i).frame(j,:),frame_len);
%                 
%             end
%         end
%     end
% end

tmp_noise=wgn(1,16000,0);
c_frame=floor(16000/512);

tmp_frame=zeros(c_frame,frame_len);
for j=1:c_frame %프레임 쪼개기
    tmp_frame(j,:)=tmp_noise(frame_len*(j-1)+1:frame_len*(j-1)+frame_len);
end

tmp_zcr=zcrGen(c_frame,frame_len,tmp_frame);
tmp_power=energyGen(c_frame,frame_len,tmp_frame);
white_zcr=mean(tmp_zcr);
white_power=mean(tmp_power);


for i=1:10
   figure(i); 
   
   subplot(211); 
   plot(file(i+2).origin','-b','linewidth',2); hold on; 
   plot(file(i+2).speech,'r'); 
   legend("original file","synthesis result");


   subplot(212);    
   plot(file(i+2).origin','-b','linewidth',2); hold on;
   plot(file(i+2).speech2,'g'); 
   legend("original file","ineye result");
   
end

%%


%비슷한 파일 찾기
for i=3:12
   exInput=file(4).vuv;
   lInput=length(exInput);
   lfile=length(file(i).vuv);
   if lInput>lfile
       exInput=resample(exInput,lfile,lInput);
       lchoose=lfile;
   else
       file(i).vuv=resample(file(i).vuv,lInput,lfile);
       lchoose=lInput;
   end
%   file(i).similar=xcorr(file(i).vuv,exInput); 
   file(i).coeff=corrcoef(file(i).vuv,exInput);
%   file(i).similar=xcorr(file(i).vuvtemp,exInput);
 %  file(i).coeff=corrcoef(file(i).vuvtemp,exInput);
%   [file(i).pks,file(i).locs]=findpeaks(file(i).similar);
%   figure(i); plot(file(i).similar);
end

for i=3:12
   fprintf("유사성 : ")
   disp(file(i).coeff(1,2)*100)
   fprintf("% \n")
   disp(i)
   if file(i).coeff(1,2)==1
       fprintf("번째는 같은 파일\n");
       sound(file(i).speech,Fs);
   elseif file(i).coeff(1,2)>0.65
       fprintf("번째는 유사 파일\n");
       sound(file(i).speech,Fs);
   else
       fprintf("번째는 다른 파일\n");
   end
end