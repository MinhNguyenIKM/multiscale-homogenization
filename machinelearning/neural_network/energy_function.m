a = -1;
b = 1;
N = 10^4; % number of sampling points
% D = 6 in our case (dimensional space)
% x1 = a + (b - a) .* rand(N,1);
% x2 = a + (b - a) .* rand(N,1);
% x3 = a + (b - a) .* rand(N,1);
% x4 = a + (b - a) .* rand(N,1);
% x5 = a + (b - a) .* rand(N,1);
% x6 = a + (b - a) .* rand(N,1);
x1 = (-1:2*1e-5:1)';
x2 = x1;
% x1 = a + (b - a) .* rand(N,1);
% x2 = a + (b - a) .* rand(N,1);
% energy function is simply defined like this
% f = x1.^2 + x2.^2 + x3.^2 + x4.^2 + x5.^2 + x6.^2;
f = x1.^2 + x2.^2;
scatter3(x1,x2,f)