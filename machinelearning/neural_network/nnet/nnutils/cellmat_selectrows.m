function c = cellmat_selectrows(c,row_indices)

% Copyright 2007 The MathWorks, Inc.

[rows,cols] = size(c);
for i=1:rows
  for j=1:cols
    c{i,j} = c{i,j}(row_indices,:);
  end
end
