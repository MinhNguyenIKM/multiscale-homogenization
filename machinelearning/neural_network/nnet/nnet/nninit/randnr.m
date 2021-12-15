function w = randnr(s,pr)
%RANDNR Normalized row weight initialization function.
%
%  Syntax
%
%     W = randnr(S,PR)
%     W = randnr(S,R)
%
%  Description
%
%    RANDNR is a weight initialization function.
%
%    RANDNR(S,P) takes these inputs,
%      S  - Number of rows (neurons).
%      PR - Rx2 matrix of input value ranges = [Pmin Pmax].
%    and returns an SxR random matrix with normalized rows.
%  
%    Can also be called as RANDNR(S,R).
%  
%  See also RANDNC.

% Mark Beale, 1-31-92
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.6 $  $Date: 2007/11/09 20:50:09 $

fn = mfilename;
if (nargin < 1), error('NNET:Arguments','Not enough arguments.'); end
if ischar(s)
  switch(s)
    case 'name'
      w = 'Midpoint';
    otherwise, error('NNET:Arguments',['Unrecognized code: ''' s ''''])
  end
  return
end
if (nargin < 2), error('NNET:Arguments','Not enough arguments.'); end

if size(pr,2) == 1
  r = pr;
else
  r = size(pr,1);
end
w = normr(rands(s,r));
