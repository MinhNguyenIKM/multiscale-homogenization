function cm = cellmat(rows1,cols1,rows2,cols2,value)

% Copyright 2007 The MathWorks, Inc.

if nargin < 5, value = 0; end
if nargin < 4, cols2 = 1; end
if nargin < 3, rows2 = 1; end
if nargin < 2, cols1 = 1; end
if nargin < 1, rows1 = 1; end

if numel(rows2) < rows1
  rows2 = rows2(ones(1,rows1));
end
if numel(cols2) < cols1
  cols2 = cols2(ones(1,cols1));
end


cm = cell(rows1,cols1);
for i=1:rows1
  for j=1:cols1
    cm{i,j} = zeros(rows2(i),cols2(j))+value;
  end
end
