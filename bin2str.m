function s = bin2str(b)
%   bin2str 将二进制串转为字符串
%   输入列向量二进制串，返回对应的字符串
t = char(b+'0');        % 变换回字符0/1串
len = floor(length(t)/8);
t = t(1:len*8);
t = reshape(t,8,length(t)/8);   % 每8个一列，还原形状
s = char(bin2dec(t'))';          % bin2dec还原
end

