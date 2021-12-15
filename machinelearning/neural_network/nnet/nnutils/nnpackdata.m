function [d,mode] = nnpackdata(d)

% Copyright 2005 The MathWorks, Inc.

if isnumeric(d)
  d = {d};
  mode = 0;
elseif iscell(d)
  mode = 1;
else
  d = []
  mode = -1;
end
