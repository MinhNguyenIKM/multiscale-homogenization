function [x,flag] = cellmat_force(x)

% Copyright 2007 The MathWorks, Inc.

if isdouble(x)
  flag = false;
  x = {x};
else
  flag = true;
end
