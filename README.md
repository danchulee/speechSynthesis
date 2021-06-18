# Speech Synthesis after Analysis

> Note : 2019.07 ~ 2020.05



**사용 언어**

- MATLAB



## 목차

_Note: 클릭시 해당 부분으로 이동_

- [Sections](#sections)
  - [Speech Synthesis][#speech-synthesis]
  - [Normalization](#normalization)
  - [Framing And Windowing](#framing-and-windowing)
  - [Short Time Zero Crossing Rate](#short-time-zero-crossing-rate)
  - [Short Time Energy](#short-time-energy)
  - [Voiced Unvoiced](#voiced-unvoiced)
  - [Pitch](#pitch)
  - [LPC Coefficients](#lpc-coefficients)
  - [Signal Generation](#signal-generation)
  - [Speech Synthesis](#speech-synthesis)
- [Plot](#plot)



## Sections

### Speech Synthesis

**프로젝트 개요**

- 음성을 데이터로 분석한 뒤에 특성을 살려 재합성하는 과정을 나타낸다.
- 입력 받은 음성 데이터 x samples를 512 samples를 가지는 각각의 frame으로 나눠 저장한 뒤에 진행한다.



### Normalization

- 분산과 평균을 이용한 간단한 정규화인 Mean Normalization을 거친다.

  ```matlab
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
  ```



### Framing And Windowing

- 각 frame에 Hamming window를 취해, 이후에 연결될 frames 앞뒤의 불연속적인 부분을 최소화한다.
  - Fourier Transform은 길이가 무한한 signal에서 적용되는 알고리즘이므로, 유한한 signal을 분석할 때에는 spectral leakage가 발생한다.

* 앞서 정한 cntFrame(프레임 개수) * frame_len(프레임 길이)로 frame을 나눈다.
* frame_window는 periodic한 frame_len 길이의 hamming window다.

```matlab
frame = zeros(cntFrame, frame_len);
frame_wind = hamming(frame_len, 'periodic');
h_frame_len = 0.5 * frame_len;

for i = 1 : cntFrame
	frame(i, :) = x(h_frame_len * (i-1) + 1 : h_frame_len * (i-1) + frame_len);
	frame(i, :) = frame(i, :) .* frame_wind';
end
```



### Short Time Zero Crossing Rate

- 유성음(Voiced)와 무성음(Unvoiced)의 구분에 사용된다.
- 유성음의 ZCR << 무성음의 ZCR임에 기반하여, Threshold를 기준으로 구별하는 데에 사용한다.

- 단구간 영 교차율은 0을 교차하는 비율을 의미한다.
- 현재 sample 값 * 앞의 sample 값 < 0 일 시에 1을 반환하여 sum을 계산한다.
- sum/sample_length인 영 교차율에 Hamming Window를 취한다.

```matlab
zcrData = zeros(1,cntFrame);
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
    if frame_len - j >=0 && frame_len - j <  frame_len
    	w_data = 1 / (2 * frame_len);
    else
    	w_data = 0;
    end
  	zcrData(1, i) = zcrData(1, i) + abs(sgn_data) * w_data;
  end
end
```



### Short Time Energy

- 유성음(Voiced)와 무성음(Unvoiced)의 구분에 사용된다.
- 유성음의 에너지 >> 무성음의 에너지임에 기반하여, Threshold를 기준으로 구별하는 데에 사용한다.
- Energy에 Hamming Window를 취해서 유한한 길이의 signal을 Energy를 구한다.

```matlab
energyData = zeros(1, cntFrame);
window = hamming(frame_len, 'periodic');
for i = 1 : cntFrame
	for j = 1 : frame_len
		energyData(1, i) = energyData(1, i) + (frame(i, j) .* window(j))^2;
	end
end
energyData = sqrt(energyData);
```



### Voiced Unvoiced

- ZCR 작음, Energy 큼 -> 유성음
- ZCR 큼, Energy 작음 -> 무성음
- ZCR과 Energy가 임의의 threshold를 넘지 않아 판별이 불가능할 경우, 앞/뒤 frame과의 유사성을 비교한다.
  - 이 때는 correlation coefficients를 통해 유사도를 확인하고, 더 유사한 frame의 VUV를 따라간다.

```matlab
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
% 2 determination
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
```



### Pitch

- ACF 를 통하여 pitch를 계산한다.
- 신호의 peaks는 주기적인 period에 따라 pulse하게 된다.
  - 이때, 이 period를 구해서 pitch로 지정할 수 있다.
- pks_corr(0) 은 늘 1로, 이를 제외해야 signal에 따른 max값을 구할 수 있다.

```matlab
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
```



### LPC Coefficients

- MATLAB에서 제공하는 lpc 함수를 이용해 선형 예측 필터 계수를 구한다.

```matlab
a = zeros(cntFrame, lpc_order);
for i = 1 : cntFrame
    a(i, :) = lpc(frame(i, :), lpc_order - 1);
end
```



### Signal Generation

- 유성음일 경우에는 pulse 신호를 signal로, 무성음일 경우에는 white Gaussian noise를 signal로 준다.

```matlab
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
```



### Speech Synthesis

- 1차 filter, signal, energy 데이터를 이용하여 임시 데이터를 생성한다.
- 임시 데이터를 256sample씩 앞뒤로 overlay하여 신호의 불연속성을 최소화한다.

```matlab
tmp = zeros(cntFrame, frame_len);
peechData = zeros(1, x_len);
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
audiowrite(['output' num2str(lpc_order) '.wav'], speechData, Fs);
```







## Plot

**Normalization** 

**On Hamming Window**

**ZCR Result**

**Power Result**

**AutoCorrelation function**

**Voiced/Unvoiced**

**Synthesized Result**

**Overlapped Synthesized on Original wav file**

**Calculated VUV vs Hard coded VUV**





**필요 개선사항**

* VUV 알고리즘
* 수학적인 접근을 통한 극대값 도출로 정확한 peak 값 도출



