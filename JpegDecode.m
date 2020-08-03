clear; close all; clc;
% 加载编码结果与所需码表
load jpegcodes.mat;  % 图像编码结果
load JpegCoeff.mat   % 码表
load hall.mat        % 原图
load snow.mat        % 雪花图
% 常量
raw_h = h;  % 原始图像长宽
raw_w = w;
Q = 1;      % 量化步长缩放系数
N = 8;      % 分块边长
preprocess_dec = 128;   % 预处理时减去的值
zigzag_indice = zigzag(N,N);    % zigzag索引
zigzag_indice = sub2ind([N,N],zigzag_indice(:,1),zigzag_indice(:,2));   % 由数组索引变为顺序索引
raw_pic = hall_gray;    % 原图
use_spatial_hide = 0;   % 启动/关闭空域信息隐藏
use_dct_hide = 3;       % 0-关闭DCT域信息隐藏 1-DCT方法1 2-DCT方法2 3-DCT方法3

% DC解码
DC_hat = DCdecode(DC_code,DCTAB);
DC = zeros(size(DC_hat));   % 差分结果还原回原始结果
DC(1)=DC_hat(1);
for n=2:length(DC)
    DC(n) = DC(n-1)-DC_hat(n);  % 根据公式还原
end
% AC解码
AC = ACdecode(AC_code,ACTAB,N);
% 重建DCT变换结果
C = [DC;AC];

switch use_dct_hide
    case 1 % DCT域信息隐藏技术方法1
        msg_bit = bitget(C,1,'int64');   % 读取最后1bit
        msg = bin2str(msg_bit(:));      % 转为字符串
        disp(['DCT域隐藏方法1信息为',msg]);
    case 2 % DCT域信息隐藏技术方法2
        target_max = 15;    % 已填充数据的DCT系数对应的最大量化系数
        QTAB_zigzag = QTAB(zigzag_indice); % 对量化表也进行zigzag使之与C中每列匹配
        target_indice = find(QTAB_zigzag<=target_max);   % 已填充数据的位置
        target_C = C(target_indice,:);     % 取出已填充数据的部分
        msg_bit = bitget(target_C,1,'int64');   % 读取最后1bit
        msg = bin2str(msg_bit(:));      % 转为字符串
        disp(['DCT域隐藏方法2信息为',msg]);
    case 3
        block_cnt = size(C,2);      % 可用的块数量
        msg_bit = zeros(block_cnt,1);
        for n=1:block_cnt
           nonzero_indice = find(C(:,n));       % 找出所有非零项的索引
           msg_bit(n)=C(nonzero_indice(end),n);     % 从最后一个非零项获取数据
        end
        msg_bit = (msg_bit+1)/2;        % 还原回0/1串
        msg = bin2str(msg_bit(:));      % 转为字符串
        disp(['DCT域隐藏方法3信息为',msg]);
end

% 分块情况计算
block_size = ceil([raw_h,raw_w]/N);    % 计算各个维度上块的数量
extended_pic = zeros(N*block_size);     % 扩展后的图像
[extended_h,extended_w] = size(extended_pic); % 扩展后图像大小
% 反量化并还原每一区块
for m=1:block_size(1)   
    for n=1:block_size(2)
        column = (m-1)*block_size(2)+n;     % 选择块对应的DCT变换结果
        c = zeros(N,N);
        c(zigzag_indice) = C(:,column);     % 还原zigzag结果
        c = c.*QTAB*Q;            % 对每个块进行反量化
        extended_pic((m-1)*N+1:m*N,(n-1)*N+1:n*N) = myidct2(c); % DCT反变换并回填像素点
    end
end
% 去除扩展的部分
pic = extended_pic(1:raw_h,1:raw_w);
% 还原预处理操作
pic = pic+preprocess_dec;
% 处理溢出数据
pic(pic<0) = 0;
pic(pic>255)=255;

% 空域信息隐藏技术
if use_spatial_hide
    msg_bit = bitget(uint8(pic),1); % 读取最后1bit
    msg = bin2str(msg_bit(:));      % 转为字符串
    disp(['空域隐藏信息为',msg]);
end

% 绘制图像
figure;
subplot(1,2,1);
imshow(raw_pic);
title('原图');
subplot(1,2,2);
imshow(uint8(pic));
if use_spatial_hide
    title('JPEG-空域信息隐藏方法3');
elseif use_dct_hide==1
    title('JPEG-DCT域信息隐藏方法1');
elseif use_dct_hide==2
    title('JPEG-DCT域信息隐藏方法2');
elseif use_dct_hide==3
    title('JPEG-DCT域信息隐藏方法3');
else
    title('JPEG');
end
% 评价解码结果
MSE = mean((double(raw_pic)-pic).^2,'all');
PSNR = 10*log10(255*255/MSE);
disp(['编码质量PSNR为',num2str(PSNR)]);

function DC = DCdecode(code,DCTAB)
% DC熵解码函数
% 输入编码结果code，码表DCTAB
% 输出差分后的DC值
first=1;    % 初始化
last=1;
DC = [];
while last<=length(code)    % 扫描到结尾结束
    len = last-first+1;     % 当前解码长度
    target = zeros(1,size(DCTAB,2)-1);
    target(1:len)=code(first:last);    % 当前检查的编码序列
    target_row_index = find(all(DCTAB(:,2:end)==target,2)); % 在码表中找到对应的行
    if ~isempty(target_row_index) && DCTAB(target_row_index,1)==len    % 存在对应的行且长度一致，判定为解码成功
        category = target_row_index(1)-1;   % 计算数字长度
        if category>0
            val = bin2int(code(last+1:last+category));  % 非0值解码
            DC = [DC,val];
        else
            DC = [DC,0];    % 0直接处理
        end
        first = last+category+1;    % 从后续继续解码
        last = first;
    else
        last=last+1;                % 解码不成功则last自增继续解码
    end
end
end

function AC = ACdecode(code,ACTAB,N)
% AC熵解码函数
% 输入编码结果code，码表ACTAB，block边长N
% 输出AC值矩阵，每列为一个block
first=1;    % 初始化
last=1;
AC=[];      % AC值矩阵
AC_now=zeros(1,N*N-1);  % 当前block的结果
AC_next=1;  % 当前block数组待填写位置索引
while last<=length(code)    % 扫描到结尾结束
    len = last-first+1;     % 当前解码长度
    target = zeros(1,size(ACTAB,2)-3);
    target(1:len)=code(first:last);    % 当前检查的编码序列
    target_row_index = find(all(ACTAB(:,4:end)==target,2)); % 在码表中找到对应的行
    if all(target(1:4)==[1,0,1,0],'all') && len == 4        % EOB
        AC = [AC;AC_now];   % 结束本块，将结果存入整个矩阵
        AC_now=zeros(1,N*N-1);  % 重新初始化当前块
        AC_next=1;
        last = last+1;     % 从后续继续解码
        first = last;
    elseif all(target(1:11)==[1,1,1,1,1,1,1,1,0,0,1],'all') && len == 11        % ZRL
        AC_next=AC_next+16;     % 直接跳过16个数（初始化时置0）
        last = last+1;     % 从后续继续解码
        first = last;
    elseif ~isempty(target_row_index) && ACTAB(target_row_index,3)==len    % 存在对应的行且长度一致，判定为解码成功
        row = target_row_index(1);
        run = ACTAB(row,1);         % 取出游程数
        category = ACTAB(row,2);    % 计算数字长度
        AC_next = AC_next+run;      % 直接跳过一定数量的数（初始化时置0）
        val = bin2int(code(last+1:last+category));  % 非0值解码
        AC_now(AC_next) = val;
        AC_next = AC_next+1;        
        last = last+category+1;     % 从后续继续解码
        first = last;
    else
        last=last+1;                % 解码不成功则last自增继续解码
    end
end
AC=AC';
end