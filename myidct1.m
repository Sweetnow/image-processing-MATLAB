function p = myidct1(c)
% 1-D离散反余弦变换
% 输入列向量p 输出变换结果列向量c
N = length(c);
% 根据公式构造变换矩阵D
D = (1:2:2*N-1).*(0:1:N-1)';
D = cos(D*pi/(2*N));
D(1,:)=sqrt(0.5);
D = D*sqrt(2/N);
% 计算变换结果
p = D'*c;
end

