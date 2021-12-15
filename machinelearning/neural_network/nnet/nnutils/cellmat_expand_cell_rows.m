% ============================================================
function y = cellmat_expand_cell_rows(x,ind,rows)

% Copyright 2007 The MathWorks, Inc.

y = cell(rows,size(x,2));
y(ind,:) = x;
