function flag = iscellmat(c)

% Copyright 2007 The MathWorks, Inc.

if ~iscell(c)
  flag = false;
elseif isempty(c)
  flag = true;
elseif ndims(c) > 2
  flag = false;
else
  [rows1,cols1] = size(c);
  cols2 = size(c{1,1},2);
  for i=1:rows1
    rows2 = size(c{i,1},1);
    for j=1:cols1
      if any(size(c{i,j}) ~= [rows2 cols2])
        flag = false;
        return;
      end
    end
  end
  flag = true;
end
