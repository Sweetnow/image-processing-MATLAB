function b = str2bin(s)
%   str2bin 将字符串转为二进制串
%   输入char[]型字符串，返回对应的二进制串列向量
t=dec2bin(uint8(s),8)';  % 变换为字符串表示的二进制序列
t=t(:);                 % 展平
b=(double(t)-'0');     % 变换为double类型的0/1列向量
end

