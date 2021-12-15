k = 10
Cx = @(x) 3/2 + sin(2*pi*k*x)
x = 0:0.001:1
plot(x, Cx(x))