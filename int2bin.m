function b = int2bin(d,n)
%INT2BIN 将给定的整数d转为n位二进制序列，负数以反码表示
%  输入待转化的整数d，位数n 输出二进制串b
if d>=0
    b=dec2bin(d,n); % 正数直接转化
else
    b=['0',dec2bin(2^n+d-1,n-1)];   % 负数先转为反码对应的正数再转化
end
b=double(b)-'0';    % char转为double
end

