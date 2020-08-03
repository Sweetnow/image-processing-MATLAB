function indice = zigzag(h,w)
%ZIGZAG 对于h*w的二维矩阵给出zigzag的索引路径
%   输入矩阵形状h,w  输出下标索引
indice = [1,1]; % 数组索引起始状态
now = [1,1];    % 起始点
direction_loop={'edge','southwest','edge','northeast'}; % 移动方向的循环顺序
i=1;    % 循环起点southwest
while any(now ~= [h,w]) % 达到右下角退出
    direction = direction_loop{i};  % 选择方向
    next = zigzag_next(h,w,now,direction);  % 计算终点
    if ~strcmp(direction,'edge')
        if next(1)>now(1)   % 根据增加/减少的维度调整序列生成方式
            nexts = [now(1):1:next(1);now(2):-1:next(2)]';  % 起点到终点的连续变化序列
        else
            nexts = [now(1):-1:next(1);now(2):1:next(2)]';  % 起点到终点的连续变化序列
        end
        nexts = nexts(2:end,:); % 排除当前点
    else
        nexts = next;   % 边缘只移动一个单位长度，不需要特殊处理
    end
    indice = [indice;nexts];    % 拼接索引
    now = next;                 % 更新当前点
    i = mod(i,4)+1; % 选择下一方向
end
end

function next_pos = zigzag_next(h,w,now_pos,direction)
% 本函数用于zigzag中向一个指定方向移动并计算终点
% direction: 'southwest', 'northeast', 'edge' 标记移动方向，前两个为斜向进行的，最后为沿边缘前进一格
% h,w为矩阵长宽
% now_pos 为当前位置

% 错误输入1，起始坐标不在范围内
if now_pos(1) > h || now_pos(1) < 1 || now_pos(2) > w || now_pos(2) < 1
    ME = MException('zigzag:wronginput', 'now_pos should be in [1:h]*[1:w]');
    throw(ME);
end
% 错误输入2，起始坐标已到达zigzag终点
if now_pos(1) == h && now_pos(2) == w
    ME = MException('zigzag:wronginput', 'now_pos is at the end');
    throw(ME);
end
switch direction
    % 如果当前点在边缘，则水平/竖直移动一个单位长度距离
    case 'edge'
        if (now_pos(1)==1 || now_pos(1)==h) && now_pos(2) ~= w % 当前点在上/下边界（排除右上角）时，水平向右一个单位长度
            next_pos = now_pos + [0,1];
        elseif now_pos(2)==1 || now_pos(2)==w % 当前点在左右边界（已排除左上、左下、右下角）时，竖直向下一个单位长度
            next_pos = now_pos + [1,0];
        else
            ME = MException('zigzag:wronginput', 'now_pos is not at the edge'); % 错误输入3：当前点不在边缘
            throw(ME);    
        end
    % 向左下方移动
    case 'southwest'
        sum_pos = sum(now_pos);     % 计算行列和
        x = min(sum_pos-1, h);      % 行数不足时只能在最后一行
        next_pos = [x, sum_pos-x];  % 行列和一定一致
    % 向右上方移动
    case 'northeast'
        sum_pos = sum(now_pos);     % 计算行列和
        y = min(sum_pos-1, w);      % 列数不足时只能在最后一列
        next_pos = [sum_pos-y, y];  % 行列和一定一致
    % 错误输入4： 方向不在指定选项中
    otherwise
        ME = MException('zigzag:wronginput', 'direction should be `southwest`, `northeast` or `edge`');
        throw(ME);
end
end
