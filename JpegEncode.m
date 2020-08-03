clear; close all; clc;
% 加载图像与所需码表
load hall.mat;  % 图像
load snow.mat   % 雪花图
load JpegCoeff.mat % 码表
pic = hall_gray;
% 设定常量
Q = 1;                  % 量化步长缩放系数
N = 8;                  % 分块边长
preprocess_dec = 128;   % 预处理时减去的值
[raw_h,raw_w] = size(pic);         % 原始图像大小
zigzag_indice = zigzag(N,N);    % zigzag索引
zigzag_indice = sub2ind([N,N],zigzag_indice(:,1),zigzag_indice(:,2));   % 由数组索引变为顺序索引
use_spatial_hide = 0;   % 启动/关闭空域信息隐藏
use_dct_hide = 3;       % 0-关闭DCT域信息隐藏 1-DCT方法1 2-DCT方法2 3-DCT方法3
msg = 'Copyright@zhangjun';    % 信息
msg_bit_cnt = length(msg)*8;   % 信息转为二进制后的长度

% 编码信息
if use_spatial_hide || use_dct_hide
    msg_bit = str2bin(msg);
end
% 空域信息隐藏技术
if use_spatial_hide
    % 重复信息以填充整个图片
    pixel = raw_h*raw_w;    % 计算总像素点数
    repeat_cnt = ceil(pixel/msg_bit_cnt);   % 计算重复次数
    spatial_msg_bit = repmat(msg_bit,repeat_cnt,1); % 生成重复过的序列
    spatial_msg_bit = spatial_msg_bit(1:pixel);     % 删去超出的部分
    pic = bitset(pic,1,reshape(spatial_msg_bit,size(pic))); % 修改最后一个bit
end

% 图像预处理
pic = double(pic)-preprocess_dec;
% 分块与补全
block_size = ceil(size(pic)/N);    % 计算各个维度上块的数量
extended_pic = zeros(N*block_size);     % 扩展后的图像
[extended_h,extended_w] = size(extended_pic); % 扩展后图像大小
extended_pic(1:raw_h,1:raw_w) = pic;
if raw_h<extended_h
    extended_pic(raw_h+1:end,:) = repmat(extended_pic(raw_h,:),extended_h-raw_h,1);    % 行补全
end
if raw_w<extended_w
    extended_pic(:,raw_w+1:end) = repmat(extended_pic(:,raw_w),1,extended_w-raw_w);    % 列补全
end
% 处理每个块（DCT 量化）
C = zeros(N*N,block_size(1)*block_size(2));
for m=1:block_size(1)   
    for n=1:block_size(2)
        block = extended_pic((m-1)*N+1:m*N,(n-1)*N+1:n*N);  % 选择块
        c = round(mydct2(block)./(QTAB*Q));     % 对每个块进行DCT变换与量化
        c = c(zigzag_indice);               % zigzag索引
        column = (m-1)*block_size(2)+n;
        C(:,column) = c;                    % 填入C
    end
end % 到此实现题8要求

switch use_dct_hide
    case 1  % DCT域信息隐藏技术方法1
        % 重复信息以填充整个变换阵
        [C_h,C_w] = size(C);
        C_cnt = C_h*C_w;    % 计算C矩阵大小
        repeat_cnt = ceil(C_cnt/msg_bit_cnt);       % 计算重复次数    
        dct1_msg_bit = repmat(msg_bit,repeat_cnt,1);% 生成重复过的序列
        dct1_msg_bit = dct1_msg_bit(1:C_cnt);       % 删去超出的部分
        C = bitset(C,1,reshape(dct1_msg_bit,size(C)),'int64'); % 修改最后一个bit
    case 2  % DCT域信息隐藏技术方法2
        target_max = 15;    % 可填充数据的DCT系数对应的最大量化系数
        QTAB_zigzag = QTAB(zigzag_indice); % 对量化表也进行zigzag使之与C中每列匹配
        target_indice = find(QTAB_zigzag<=target_max);   % 可填充数据的位置
        target_C = C(target_indice,:);     % 取出可填充数据的部分
        [C_h,C_w] = size(target_C);
        C_cnt = C_h*C_w;    % 计算C矩阵大小
        repeat_cnt = ceil(C_cnt/msg_bit_cnt);       % 计算重复次数    
        dct2_msg_bit = repmat(msg_bit,repeat_cnt,1);% 生成重复过的序列
        dct2_msg_bit = dct2_msg_bit(1:C_cnt);       % 删去超出的部分
        target_C = bitset(target_C,1,reshape(dct2_msg_bit,size(target_C)),'int64'); % 修改最后一个bit
        C(target_indice,:) = target_C;              % 回填数据
    case 3  % DCT域信息隐藏技术方法3
        block_cnt = size(C,2);      % 可用的块数量
        dct3_msg_bit=2*msg_bit-1;   % 转为1 -1表示
        repeat_cnt = ceil(block_cnt/msg_bit_cnt);       % 计算重复次数   
        dct3_msg_bit = repmat(dct3_msg_bit,repeat_cnt,1);% 生成重复过的序列
        dct3_msg_bit = dct3_msg_bit(1:block_cnt);       % 删去超出的部分
        for n=1:block_cnt
           nonzero_indice = find(C(:,n));       % 找出所有非零项的索引
           if nonzero_indice(end) == size(C,1)  % 最后一个非零项为整个块最后一个
               target = nonzero_indice(end);    % 修改最后一个系数
           else
               target = nonzero_indice(end)+1;  % 修改最后一个非零系数的后一个
           end
           C(target,n)=dct3_msg_bit(n);     % 修改数据
        end
end



% DC熵编码
DC = C(1,:);                        % 提取直流分量
DC_hat = [2*DC(1),DC(1:end-1)]-DC;  % 差分运算
DC_code = DCencode(DC_hat,DCTAB);   % 计算DC编码

% AC熵编码
AC_code = [];
for block=1:size(C,2)
    AC = C(2:end,block)';
    AC_code = [AC_code,ACencode(AC,ACTAB)];
end

% 保存结果
h=raw_h;
w=raw_w;
save('jpegcodes.mat','h','w','DC_code','AC_code');
% 计算压缩比
input_byte = raw_h*raw_w;   % 输入图像数据类型为uint8，每一个占1B
output_byte = (length(DC_code)+length(AC_code))/8;  % 输出数据为二进制流，每8个占1B
ratio = output_byte/input_byte;
disp(['压缩比为',num2str(ratio),':1']);


function code = DCencode(DC,DCTAB)
% DC编码函数
% 输入行向量DC与码表DCTAB
% 输出编码后的结果行向量code
code = [];                       % DC编码
DC_cat = floor(log2(abs(DC)))+1;% 转化为Category
DC_cat(DC==0) = 0;              % 修复Category 0
for n =1:length(DC)             % 遍历所有数字
    category = DC_cat(n);       % 获取category
    len = DCTAB(category+1,1);  % 获取长度
    code = [code, DCTAB(category+1,2:1+len),int2bin(DC(n),category)];   % 在code后附加新的编码结果
end
end

function code = ACencode(AC,ACTAB)
% AC编码函数
% 输入行向量AC与码表DCTAB
% 输出编码后的结果行向量code
zero_cnt=0;     % 计数之前出现过的0的个数
code=[];        % 编码
for n=1:length(AC)  % 对每个值循环
    now_num = AC(n);    % 当前值
    if now_num==0       % 当前值为0则计数
        zero_cnt = zero_cnt+1;
    else                % 不为0
        while zero_cnt >= 16     % 处理ZRL的情况
            code=[code,[1,1,1,1,1,1,1,1,0,0,1]];
            zero_cnt = zero_cnt - 16;
        end
        category = floor(log2(abs(now_num)))+1;  % 计算size
        runsize_row_index = all(ACTAB(:,1:2)==[zero_cnt,category],2);   % 获取(run/size)对应的码表行
        runsize_row = ACTAB(repmat(runsize_row_index,1,size(ACTAB,2)))';
        len = runsize_row(3);   % 获取编码长度
        code=[code,runsize_row(4:3+len),int2bin(now_num,category)]; % 附加新的编码结果
        zero_cnt=0;
    end
end
code = [code,[1,0,1,0]];    % 结束符
end