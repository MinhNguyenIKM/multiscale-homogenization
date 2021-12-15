function f = is_nn_matrix(x)

% Copyright 2007-2008 The MathWorks, Inc.

if ~(isnumeric(x) || islogical(x))
  f = false;
elseif ~isreal(x)
  f = false;
elseif ndims(x) > 2
  f = false;
elseif numel(x) == 0
  f = false;
elseif any(any(isinf(x)))
  f = false;
else
  f = true;
end
