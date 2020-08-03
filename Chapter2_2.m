clear; close all; clc;
% 加载数据
load('hall.mat');
start_x=100;    % 寻找一个适合观察的区域
start_y=10;     % 寻找一个适合观察的区域
target = hall_gray(start_x:start_x+7,start_y:start_y+7);  % 选取用于后续步骤的区块
figure;
subplot(2,3,1); 
imshow(target,'InitialMagnification','fit');    % 显示原始图像
title('原始图像');
% 变换域
C = mydct2(double(target));  % 使用了库函数double将unit8转为便于计算的double
% 右侧4列置零
C_r = C;
C_r(:,5:8) = 0;
P_r = uint8(myidct2(C_r)); % 还原到空域
subplot(2,3,2);
imshow(P_r,'InitialMagnification','fit');    % 显示右侧4列置零的图像
title('变换域右侧4列为0图像');
% 左侧4列置零
C_l = C;
C_l(:,1:4) = 0;
P_l = uint8(myidct2(C_l)); % 还原到空域
subplot(2,3,3);
imshow(P_l,'InitialMagnification','fit');    % 显示左侧4列置零的图像
title('变换域左侧4列为0图像');
% 转置
C_t = C';
P_t = uint8(myidct2(C_t)); % 还原到空域
subplot(2,3,4);
imshow(P_t,'InitialMagnification','fit');    % 显示转置的图像
title('变换域转置图像');
% 旋转90度
C_r90 = rot90(C);
P_r90 = uint8(myidct2(C_r90)); % 还原到空域
subplot(2,3,5);
imshow(P_r90,'InitialMagnification','fit');    % 显示旋转90度的图像
title('变换域旋转90度图像');
% 旋转180度
C_r180 = rot90(C_r90);
P_r180 = uint8(myidct2(C_r180)); % 还原到空域
subplot(2,3,6);
imshow(P_r180,'InitialMagnification','fit');    % 显示旋转180度的图像
title('变换域旋转180度图像');