function f = nn_is_scalar_binary(x)

% Copyright 2008 The MathWorks, Inc.

if numel(x) ~= 1
  f = false;
  return;
end

if islogical(x)
  f = true;
  return;
end

if isnumeric(x)
  if (x == 1) || (x == 0)
    f = true;
    return;
  end
end

f = false;
