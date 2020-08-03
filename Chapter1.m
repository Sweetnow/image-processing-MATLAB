clear; close all; clc;
% 加载数据并计算长宽
load('hall.mat');
[v,h,~]=size(hall_color);
x = 1:h;
y = 1:v;
[xx,yy]=meshgrid(x,y); % 生成距离网格
R = hall_color(:,:,1); % 提取红色分量
G = hall_color(:,:,2); % 提取绿色分量
B = hall_color(:,:,3); % 提取蓝色分量
% 画红圆
r = min(h,v)/2;        % 计算半径
distance = ((xx-h/2).^2+(yy-v/2).^2).^0.5; % 计算各个点到中心的距离
is_red = distance<r;    % 确定画圆范围
red_R = R;red_B = B;red_G = G;
red_R(is_red) = 255;        % 画圆
red_B(is_red) = 0;
red_G(is_red) = 0;
red_circle = cat(3,red_R,red_G,red_B);  % 重建图像
figure;
imshow(red_circle);         % 显示图像
imwrite(red_circle,'red_circle.jpg');   % 保存图像

% 画黑白格
square_a = 10;  % 方格长度
square_xx = floor(xx/square_a);     % 确定横向的方格坐标
square_yy = floor(yy/square_a);     % 确定纵向的方格坐标
is_black = uint8(mod(square_xx + square_yy,2)); % 确定涂黑区域
square_R = R.*is_black;     % 涂黑
square_G = G.*is_black;
square_B = B.*is_black;
square = cat(3,square_R,square_G,square_B); % 重建图像
figure;
imshow(square); % 显示图像
imwrite(square, 'square.jpg');   % 保存图像



