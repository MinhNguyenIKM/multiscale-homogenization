function err = nncheckdata(p,pname)

% Copyright 2007 The MathWorks, Inc.

if nargin < 1, error('NNET:Arguments','Not enough arguments.'); end
if nargin < 2, pname = 'Data'; end

err = [];

if isnumeric(p)
  if length(size(p)) > 2
    err = [pname ' has more than 2 dimensions.'];
    return;
  end
  return;
end

if iscell(p)
  if length(size(p)) > 2, error('NNET:Arguments',[pname ' has more than 2 dimensions.']); end
  [R,TS] = size(p);
  for i=1:R
    for j=1:TS
      if ~isnumeric(p{i,j}), error('NNET:Arguments',[pname '{' num2str(i) ',' num2str(j) '} is not a matrix or cell array of matrices.']); end
      if length(size(p)) > 2, error('NNET:Arguments',[pname '{' num2str(i) ',' num2str(j) '} has more than 2 dimensions.']), end
      Q = size(p{1,1},2);
      ri = size(p{i,1},1);
      if (size(p{i,j},2) ~= Q), error('NNET:Arguments',[pname '{1,1} and ' pname '{' num2str(i) ',' num2str(j) '} have different number of columns.']); end
      if (size(p{i,j},1) ~= ri), error('NNET:Arguments',[pname '{1,' num2str(j) '} and ' pname '{' num2str(i) ',' num2str(j) '} have different number of rows.']); end
    end
  end
  return
end

err = [pname ' is not a matrix or cell array of matrices.'];
