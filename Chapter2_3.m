clear; close all; clc;
% 加载数据
b=[-1,1];
a=1;
% 绘制频率响应
figure;
n = 2001;       % 频率响应数量
[h,w] = freqz(b,a,'whole',n);   % 获取频率响应
subplot(1,2,1);
plot(w/pi,abs(h));  % 绘图幅度
xlabel("freq/pi");
ylabel("幅度");
title("频率响应（幅度）");
subplot(1,2,2);
plot(w/pi,angle(h)*180/pi); % 绘图相位
xlabel("freq/pi");
ylabel("相角/°");
title("频率响应（相位）");
