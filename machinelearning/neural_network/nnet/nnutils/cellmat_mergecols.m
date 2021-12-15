function c = mergecols(c,varargin)

% Copyright 2007 The MathWorks, Inc.

sources = length(varargin);
[rows,cols] = size(c);
for i=1:rows
  for j=1:cols
    for k=1:sources
      c{i,j} = [c{i,j} varargin{k}{i,j}];
    end
  end
end
