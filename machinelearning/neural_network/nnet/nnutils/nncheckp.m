function err = nncheckp(p,pname)

% Copyright 2005-2008 The MathWorks, Inc.

if nargin < 2, pname = 'P'; end

err = [];

if isnumeric(p)
  if length(size(p)) > 2
    err = [pname ' has more than 2 dimensions.'];
    return;
  end
  return;
end

if iscell(p)
  [R,TS] = size(p);
  for i=1:R
    for j=1:S
      if ~isnumeric(p{i,j}), error('NNET:Arguments',[pname ' is not a matrix or cell array of matrices.']); end
      if length(size(p)) > 2, error('NNET:Arguments',[pname ' has more than 2 dimensions.']), end
      Q = size(p{1,1},2);
      ri = size(p{i,1});
      if (size(p{i,j},2) ~= Q), error('NNET:Arguments',[pname '{1,1} and ' pname '{' num2str(i) ',' num2str(j) '} have different number of columns.']); end
      if (size(p{i,j},1) ~= ri), error('NNET:Arguments',[pname '{1,' num2str(j) '} and ' pname '{' num2str(i) ',' num2str(j) '} have different number of rows.']); end
    end
  end
end

err = [pname ' is not a matrix or cell array of matrices.'];
