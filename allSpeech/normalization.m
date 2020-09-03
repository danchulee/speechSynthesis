function y = normalization(x)
%% input
% x : input signal
%% output
% y = normalized signal

total = 0;
slen = length(x);
for i = 1:slen
    total = total + x(i);
end
smean = total / slen;
% svar : signal's variance
svar = 0;
for i = 1:slen
    svar = svar + (x(i) - smean)^2;
end
for i = 1:slen
    nor(i) = (x(i)-smean)/realsqrt(svar);
end
%wind = hamming(slen)';
%y = nor.*wind;
y=nor;