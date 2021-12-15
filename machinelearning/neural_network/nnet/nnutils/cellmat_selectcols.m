function c = cellmat_selectcols(c,col_indices)

% Copyright 2007 The MathWorks, Inc.

[rows,cols] = size(c);
for i=1:rows
  for j=1:cols
    c{i,j} = c{i,j}(:,col_indices);
  end
end
