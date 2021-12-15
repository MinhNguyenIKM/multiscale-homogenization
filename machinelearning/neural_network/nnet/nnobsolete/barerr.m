function barerr(e,t)
%BARERR Plot bar chart of errors.
%
%  This function is obselete.
%  Use BAR to make bar plots.

nntobsf('barerr','Use BAR to make bar plots.')

%  
%  BARERR(E)
%    E - SxQ matrix of error vectors.
%  Plots bar chart of the squared errors in each column.
%  
%  EXAMPLE: e = [1.0  0.0 -0.2  2.0; 0.5  0.0  0.6 -1.0];
%           barerr(e)
%  
%  See also NNPLOT, ERRSURF, PLOTERR, PLOTES, PLOTEP.

% Mark Beale, 1-31-92
% Revised 12-15-93, MB
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.11.4.3 $  $Date: 2007/11/09 20:53:37 $

if nargin < 1, error('NNET:Arguments','Not enough input arguments'),end
if nargin == 2, e = t-e; end

bar(nnsumc(e .* e));
title('Network Errors');
xlabel('Input/Target Pairs')
ylabel('Sum-Squared Error')
