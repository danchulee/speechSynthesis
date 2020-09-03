[x,Fs] = audioread('input/³ª°¬³Ä.wav');
x_len = length(x);
lpc_order = 10;

frame_size = 0.032;
frame_len = frame_size * Fs;
cntFrame = floor(x_len / (0.5 * frame_len)) - 1;

%% normalization

total = 0;
for i = 1 : x_len
    total = total + x(i);
end
smean = total / x_len;
% svar : signal's variance
svar = 0;
for i = 1 : x_len
    svar = svar + (x(i) - smean)^2;
end
for i = 1 : x_len
    nor(i) = (x(i) - smean) / realsqrt(svar);
end
wind = hamming(x_len)';
x = nor .* wind;

%% framing & windowing

frame = zeros(cntFrame, frame_len);
frame_wind = hamming(frame_len, 'periodic');
h_frame_len = 0.5 * frame_len;

for i = 1 : cntFrame
    frame(i, :) = x(h_frame_len * (i-1) + 1 : h_frame_len * (i-1) + frame_len);
    frame(i, :) = frame(i, :) .* frame_wind';
end

%% extract ZCR rate

zcrData=zeros(1,cntFrame);

for i = 1 : cntFrame
    for j = 1 : frame_len - 1
         if frame(i, j + 1) < 0
             sgn_data2 = -1;
         else
             sgn_data2 = 1;
         end
         if frame(i, j) < 0
             sgn_data1 = -1;
         else
             sgn_data1 = 1;
         end
         sgn_data = sgn_data2 - sgn_data1;
         if frame_len - j >=0 && frame_len - j < frame_len
             w_data = 1 / (2 * frame_len);
         else
             w_data = 0;
         end
         
         zcrData(1, i) = zcrData(1, i) + abs(sgn_data) * w_data;
    end
end

%% extract Energy

energyData = zeros(1, cntFrame);
window = hamming(frame_len, 'periodic');
for i = 1 : cntFrame
   for j = 1 : frame_len
       energyData(1, i) = energyData(1, i) + (frame(i, j) .* window(j))^2;
   end
end
energyData = sqrt(energyData);

%% extract Pitch

corrFrame = zeros(cntFrame, frame_len * 2 - 1);
pitch = zeros(1, cntFrame);

for i = 1 : cntFrame
    
    sum = zeros(1, frame_len);
    for j = 1 : frame_len
       for k = 1 : frame_len - j - 1
           sum(j) = sum(j) + abs(frame(i, k) - frame(i, k + j));
       end
    end
    sum = sum ./ frame_len;
    sum = (-sum) + max(sum);
    
    [pks_corr, locs_corr] = findpeaks(sum);
    [mm, mm_i] = max(pks_corr);
    pks_corr(mm_i) = 0;
    [mm2, mm_i2] = max(pks_corr);

    period = abs(locs_corr(mm_i2) - locs_corr(mm_i)) / Fs;
    pitch(1, i) = 1 /period;


end

%% extract VUV (voiced / unvoiced)

% high zcr / low energy : 1 (unvoiced)
% low zcr / high energy : 0 (voiced)
% else? 2 -> acf

zcr_rate = 0.75;
energy_rate = 0.65;
zcr_max = max(zcrData);
energy_max = max(energyData);

zcr_set = zcr_max * zcr_rate;
energy_set = energy_max * energy_rate;

vuvData = zeros(1, cntFrame);

for i = 1 : cntFrame
   if zcrData(1, i) >= zcr_set && energyData(1, i) <= energy_set
       vuvData(1, i) = 1; %unvoice
   elseif zcrData(1, i) < zcr_set && energyData(1, i) > energy_set
       vuvData(1, i) = 0; %voice
   else
       vuvData(1, i) = 2;
   end
end

if vuvData(1, 1) == 2
    vuvData(1, 1) = 1;
elseif vuvData(1, end) == 2
    vuvData(1, end) = 1;
end

    % 2 ºÎºÐ determination
for i = 1 : cntFrame
   if vuvData(1, i) == 2 
       r = i - 1; %rear
       t = i + 1; %tail
       
       while r > 0 && vuvData(1, r) == 2
           r = r - 1;
       end
       
       while t < cntFrame - 1 && vuvData(1, t) == 2
           t = t + 1;
       end
       if r < 0
           r = 0;
       end
       if t > cntFrame
           t = cntFrame;
       end
       
       if vuvData(1, r) == 1 && vuvData(1, t) == 1
           vuvData(1, i) = 1;
       elseif vuvData(1, r) == 0 && vuvData(1, t) == 1
           vuvData(1, i) = 0;
       elseif vuvData(1, r) == 1 && vuvData(1, t) == 0
           vuvData(1, i) = 0;
       elseif vuvData(1, r) == 0 && vuvData(1, t) == 0
           vuvData(1, i) = 0;
       end
       
       if i == 1
           vuvData(1, i) = vuvData(1, t);
       elseif i == cntFrame
           vuvData(1, i) = vuvData(1, r);
       end
   end

   if vuvData(1, i) == 2
       r = i - 1; %rear
       t = i + 1; %tail
       
       while r > 0 && vuvData(1, r) == 2
           r = r - 1;
       end
       
       while t < cntFrame - 1 && vuvData(1, t) == 2
           t = t + 1;
       end

       tmp_1 = corrcoef(frame(r, :), frame(i, :));
       similarity_1 = tmp_1(1, 2) * 100;
       tmp_2 = corrcoef(frame(i, :), frame(t, :));
       similarity_2 = tmp_2(1, 2) * 100;
       
       if similarity_1 > similarity_2
           vuvData(1, i)=vuvData(1, r);
       else
           vuvData(1, i)=vuvData(1, t);
       end
   end
end

%% LPC coefficients
a = zeros(cntFrame, lpc_order);
for i = 1 : cntFrame
    a(i, :) = lpc(frame(i, :), lpc_order - 1);
end

%% Signal Generation
pulse = zeros(cntFrame, frame_len);

for i = 1 : cntFrame
    pulse(i, 1 : floor(pitch(1, i)) : frame_len) = 1;
end

noise = wgn(cntFrame, frame_len, 0) / 4;
signal = zeros(cntFrame, frame_len);

for i = 1 : cntFrame
    if vuvData(1, i) == 0 %voice
        signal(i, :) = pulse(i, :);
    else %unvoice
        signal(i, :) = noise(i, :);
    end
end

%% Speech Synthesis
tmp = zeros(cntFrame, frame_len);
speechData = zeros(1, x_len);

for i = 1 : cntFrame
    tmp(i, :) = filter(1, a(i, :), signal(i, :));
    tmp(i, :) = energyData(1, i) .* tmp(i, :);
end

speechData(1, 1:frame_len / 2) = tmp(1, 1:frame_len / 2);
speechData(1, x_len - frame_len / 2 + 1 : x_len) = tmp(cntFrame, frame_len / 2 + 1 : frame_len);
for i = 1 : cntFrame - 1
   speechData(1, i * frame_len / 2 + 1 : (i + 1) * frame_len / 2) = tmp(i, frame_len / 2 + 1 : frame_len);
   speechData(1, i * frame_len / 2 + 1 : (i + 1) * frame_len / 2) = speechData(1, i * frame_len / 2 + 1 : (i + 1) * frame_len / 2) + tmp(i + 1, 1 : frame_len / 2);
end

audiowrite(['output/new' num2str(lpc_order) '.wav'], speechData, Fs);

%% Writing txt File

cnt_x = 1 : cntFrame;
A = [cnt_x; energyData; zcrData; vuvData; pitch];

fileID = fopen("result.txt", 'w');
fprintf(fileID, '%6s %12s %12s %12s %12s\r\n', 'index', 'energy', 'zcr', 'vuv', 'pitch');
fprintf(fileID, '%6d %12.4f %12.3f %12d %12.3f\r\n', A);
type result.txt
