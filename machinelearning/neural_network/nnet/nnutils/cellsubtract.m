function c = cellsubtract(a,b)

% Copyright 2007 The MathWorks, Inc.

if iscell(a)
  [rows,cols] = size(a);
  t = cell(rows,cols);
  for i=1:rows
    for j=1:cols
      t{i,j} = a{i,j} - b{i,j};
    end
  end
else
  c = a-b;
end
