clear; close all; clc;
% 常量
image_cnt = 33; % 训练使用的图像数
N = 8;  % 真彩色位宽
L = 5;  % 颜色位数
v = zeros(2^(3*L),1); % 特征向量

for n=1:image_cnt  % 遍历所有图像
    pic=imread(['Faces/',num2str(n),'.bmp']);   % 读取图片
    v = v+pic2vec(pic,L);   % 图像转为特征向量
end
v = v/image_cnt;    % 计算均值

% 人脸检测算法
% 常量
image_path = 'test.jpg';    % 测试文件
windows = [20,40,60]';    % 扫描窗大小
steps = [5,10,15]';       % 每种扫描窗移动步长
ratio = 0.5;                % 合并判断标准
switch L    % 不同的L对应不同阈值
    case 3
        epison = 0.20;
    case 4
        epison = 0.40;
    case 5
        epison = 0.55;
end
               
% 读取图像
pic = imread(image_path);
[h,w,~]=size(pic);          % 获取图像大小
% pic = imresize(pic,[h,2*w]); % 缩放
pic = imrotate(pic,-90);   % 旋转
% pic = imadjust(pic,[0.2,0.8]); % 改变颜色
[h,w,~]=size(pic);          % 获取图像大小
targets = [];               % 每行代表一个目标框（x,y,w,h）格式，候选集
for n = 1:length(windows)   % 遍历所有扫描窗大小
    win = windows(n);
    step = steps(n);
    for row=1:step:h-win+1  % 遍历图像
        for col=1:step:w-win+1
            this_v = pic2vec(pic(row:row+win-1,col:col+win-1,:),L); % 计算窗内的特征向量
            dist = face_distance(this_v,v);
            if dist < epison  % 接近人脸的特征向量
                y = row;              % 计算目标框的坐标
                x = col;
                targets = [targets;[x,y,win,win]];  % 加入候选集
            end
        end
    end
end
% 检测窗合并
while 1 % 重复合并直到没有需要合并的检测窗
    merged_targets = []; % 合并结果
    for n=1:size(targets,1) % 遍历当前检测窗
        target = targets(n,:);
        if isempty(merged_targets) % 如果合并结果为空，则加入
            merged_targets=[merged_targets;target];
        else
            num = size(merged_targets,1); % 不为空则逐一对比当前窗与已经处理过的窗
            flag=1; % flag为1表示当前窗不与之前任何一个匹配，需要直接作为一个单独的结果
            for m=1:num
                compared_target=merged_targets(m,:); % 待比较的窗
                if check_merge(compared_target,target,ratio) % 判断是否可以合并
                    merged_targets(m,:)=merge_recs([compared_target;target]); % 合并窗
                    flag=0; % 表示已合并过
                    break;  % 发生一次合并，当前窗即丢弃
                end
            end
            if flag
                merged_targets=[merged_targets;target]; % 从未发生过合并的，需要作为一个独立的结果
            end
        end
    end
    if all(size(merged_targets)==size(targets)) % 如果一个循环中没有任何合并操作，认为已经不存在可合并的窗，退出合并部分
        break;
    end
    targets = merged_targets; % 更新用于合并的窗
end
imshow(pic); % 显示图像
for n=1:size(targets,1)
    rectangle('Position',targets(n,:),'EdgeColor','r'); %显示框
end
% title(['L=',num2str(L)]);
title('旋转角度');

function v = pic2vec(RGB,L)
% pic2vec 将输入的RGB图像转化为特征向量v，颜色位数由L决定
L_pic = int32(bitshift(RGB,L-8)); % 抽取颜色的高L位
color = bitshift(L_pic(:,:,1),2*L)+bitshift(L_pic(:,:,2),L)+L_pic(:,:,3);   % 拼接RGB三种颜色的高L位
color = color(:);   % 展平
 v = zeros(2^(3*L),1);    % 长度为2^(3L)
for m=1:length(color)
    v(color(m)+1) = v(color(m)+1)+1;  % 对每种颜色分别计数
end
v = v/length(color);    % 归一化
end

function d = face_distance(v1,v2)
% distance 计算向量v1到v2的距离（根据式4.13）
d=1-sum(sqrt(v1.*v2),'all');
end

function bool = check_merge(rec1,rec2,ratio)
% 检查两个候选框是否可以合并，判断的依据是交集占较小框的比例是否大于比例ratio
% 输入两个矩形框rec1 rec2 [x,y,w,h]形式,ratio为占比的阈值
% 输出是否合并bool
s1 = rec1(:,3).*rec1(:,4);  % 计算候选框面积
s2 = rec2(:,3).*rec2(:,4);
min_s = min(s1,s2);         % 计算较小框的面积
% 计算交集
left = max(rec1(:,1),rec2(:,1));                        % 左边框的最大值
right = min(rec1(:,1)+rec1(:,3),rec2(:,1)+rec2(:,3));   % 右边框的最小值
up = max(rec1(:,2),rec2(:,2));                          % 上边框的最大值
down = min(rec1(:,2)+rec1(:,4),rec2(:,2)+rec2(:,4));    % 下边框的最小值
mask = (right>left) & (down>up);                        % 交集存在
inter_s = (down-up).*(right-left);                      % 交集面积
inter_s(~mask)=0;                                       % 无交集的置零
bool = (inter_s>=(ratio*min_s));                        % 判断是否可以合并
end

function rec = merge_recs(recs)
% 合并多个矩形框，返回合并结果
% 输入矩形框向量，每一行代表一个矩形框，输出合并结果
rec_left = min(recs(:,1));                        % 左边框的最小值
rec_right = max(recs(:,1)+recs(:,3));             % 右边框的最大值
rec_up = min(recs(:,2));                          % 上边框的最小值
rec_down = max(recs(:,2)+recs(:,4));    % 下边框的最大值
rec=[rec_left,rec_up,rec_right-rec_left,rec_down-rec_up];
end