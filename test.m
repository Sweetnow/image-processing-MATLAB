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