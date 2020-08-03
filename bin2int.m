function d = bin2int(b)
% bin2int 将给定的二进制序列b转为整数d
%  输入待转化的二进制串b，输出整数d
sign=1;     % 符号
if b(1)==0  
    b=1-b;  % 取反
    sign=-1;
end
d=char(b+'0');  % 变为bin2dec可用的字符串
d=bin2dec(d)*sign;  % 转为数字
end
