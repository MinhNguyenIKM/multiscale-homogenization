function d = nnunpackdata(d,mode)

% Copyright 2005 The MathWorks, Inc.

if mode == 0
  d = d{1,1};
elseif mode == 1
  % do nothing
else
  d = [];
end
