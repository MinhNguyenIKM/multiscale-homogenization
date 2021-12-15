function d=calcerr(a,b)
%CALCERR Calculates matrix or cell array errors.
%
%  E = CALCERR(T,A)
%    T - MxN matrix.
%    A - MxN matrix.
%  Returns
%    D - MxN matrix A-B.
%
%  E = CALCERR(A,B)
%    T - MxN cell array of matrices A{i,j}.
%    A - MxN cell array of matrices B{i,j}.
%  Returns
%    D - MxN cell array of matrices A{i,j}-B{i,j}.

% Mark Beale, 11-31-97
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.8.4.4 $ $Date: 2008/01/10 21:12:38 $

if isnumeric(a) && isnumeric(b)

  d = a-b;

elseif iscell(a) && iscell(b)

  [m,n] = size(a);
  d = cell(m,n);
  for i=1:m
    for j=1:n
      aij = a{i,j};
      bij = b{i,j};
      if isempty(aij) || isempty(bij)
        dij = [];
      else
        dij = aij-bij;
        dij(isnan(dij)) = 0;
      end
      d{i,j} = dij;
    end
  end

else

  error('NNET:Arguments','Inputs must both be matrices or both be cell-arrays')

end
