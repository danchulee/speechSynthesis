function [vuvData,zcrset]=vuvGen(cntFrame,zcr,power)

zcr_rate = 0.55;
power_rate = 0.45;
zcr_max = max(zcr);
power_max = max(power);
zcrset=zcr_rate*zcr_max;
powerset=power_rate*power_max;

vuvData=zeros(1,cntFrame);
    %zcr 기준 zcr_max*zcr_rate
    %power 기준 power_max*power_rate
    %zcr 높고 power 낮음 : 1 무성음
    %zcr 낮고 power 높음 : 0 유성음
    %%% 두 가지 케이스에 해당되지 않을시에 2부여하고 재결정
for j=1:cntFrame
   if zcr(1,j)>=zcrset&&power(1,j)<=powerset
       vuvData(1,j)=1; %unvoice
   elseif zcr(1,j)<zcrset&&power(1,j)>powerset
       vuvData(1,j)=0; %voice
   else
       vuvData(1,j)=2;
   end
end
    % 2 부분 determination
for j=1:cntFrame
   if vuvData(1,j)==2 
       r=j-1; %rear
       t=j+1; %tail
       while r>0&&vuvData(1,r)==2
           r=r-1;
       end
       while t<cntFrame-1&&vuvData(1,t)==2
           t=t+1;
       end
       if r<1
           r=1;
       end
       if t>cntFrame
           t=cntFrame;
       end
       if vuvData(1,r)==1&&vuvData(1,t)==1
           vuvData(1,j)=1;
       elseif vuvData(1,r)==0&&vuvData(1,t)==1
           vuvData(1,j)=0;
       elseif vuvData(1,r)==1&&vuvData(1,t)==0
           vuvData(1,j)=0;
       elseif vuvData(1,r)==0&&vuvData(1,t)==0
           vuvData(1,j)=0;
       end
   end
   if vuvData(1,j)==2
       vuvData(1,j)=1;
   end
end