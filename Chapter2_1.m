clear; close all; clc;
% 加载数据
load('hall.mat');
target = hall_gray(1:8,1:8);  % 选取用于后续步骤的区块
% 直接减去128的结果
preprocess1 = target - 128;
disp(preprocess1);
% 变换域处理
C = mydct2(double(target));  % 使用了库函数double将unit8转为便于计算的double
C(1,1) = C(1,1)-128*size(target,2); % 修改直流分量实现空域减去128的效果
preprocess2 = uint8(myidct2(C)); % 还原到空域
disp(preprocess1);