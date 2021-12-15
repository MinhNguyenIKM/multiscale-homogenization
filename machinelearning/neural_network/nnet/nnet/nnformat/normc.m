function n = normc(m)
%NORMC Normalize columns of a matrix.
%
%  Syntax
%
%    normc(M)
%
%  Description
%
%    NORMC(M) normalizes the columns of M to a length of 1.
%
%  Examples
%    
%    m = [1 2; 3 4]
%    n = normc(m)
%
%  See also NORMR

% Mark Beale, 1-31-92
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.5 $  $Date: 2007/11/09 20:49:52 $

if nargin < 1,error('NNET:Arguments','Not enough input arguments.'); end

[mr,mc] = size(m);
if (mr == 1)
  n = ones(1,mc);
else
  n =ones(mr,1)*sqrt(ones./sum(m.*m)).*m;
end
