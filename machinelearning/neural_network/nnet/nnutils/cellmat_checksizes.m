function err = cellmat_checksizes(cm,rows1,cols1,rows2,cols2)

% Copyright 2007 The MathWorks, Inc.

if nargin < 5, cols2 = 1; end
if nargin < 4, rows2 = 1; end
if nargin < 3, cols1 = 1; end
if nargin < 2, rows1 = 1; end

if numel(rows2) < rows1
  rows2 = rows2(ones(1,rows1));
end
if numel(cols2) < cols1
  cols2 = cols2(ones(1,cols1));
end

[r,c] = size(cm);
if (r ~= rows1)
  err = ['Has ' num2str(r) ' rows instead of ' num2str(rows1) '.'];
  return;
end
if (c ~= cols1)
  err = ['Has ' num2str(c) ' columns instead of ' num2str(cols1) '.'];
  return
end
for i=1:rows1
  for j=1:cols1
    m = cm{i,j};
    [r,c] = size(m);
    if (r ~= rows2(i))
      err = ['Element {' num2str(i) ',' num2str(j) '} has ' num2str(r) ' rows instead of ' num2str(rows2(i)) '.'];
      return;
    end
    if (r ~= rows2(i))
      err = ['Element {' num2str(i) ',' num2str(j) '} has ' num2str(c) ' cols instead of ' num2str(cols2(i)) '.'];
      return;
    end
  end
end

err = '';
