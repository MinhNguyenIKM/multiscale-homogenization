function [simplefitInputs,simplefitTargets] = create_simplefit()

% Copyright 2007 The MathWorks, Inc.

midd = 0.15;
width = 0.03;

startd = 0.1;
change = 0.9;

mind = midd - width;
maxd = midd + width;

x1 = 2;
y1 = simplefit(x1);
xx = x1;
yy = y1;
while true
  dx = startd;
  while true
    x2 = x1 + dx;
    y2 = simplefit(x2);
    d = sqrt((y2-y1)^2+(x2-x1)^2);
    if (d > maxd)
      dx = dx * change;
    elseif (d < mind)
      dx = dx / change;
    else
      break;
    end
  end
  if x2 > 9, break; end
  x1 = x2;
  y1 = y2;
  xx = [xx x1];
  yy = [yy y1];
end

simplefitInputs = (xx-2) * (10/7);
simplefitTargets = (yy-min(yy))*(10 ./ ((max(yy)-min(yy))));

plot(simplefitInputs,simplefitTargets,simplefitInputs,simplefitTargets,'+');

%%
function y = simplefit(x)

y = -sin(cos(x*0.7)*sqrt(x))*(x-5).^2;
y = (y+17)/2;
