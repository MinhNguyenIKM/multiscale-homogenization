function [w,b] = solvelin(p,t)
%SOLVELIN Design linear network paramters.
%  
%  This function is obselete.
%  Use NEWLIND to design your network.

nntobsf('solvelin','Use NEWLIND to design your network.')

%  [W,B] = SOLVELIN(P,T)
%    P - RxQ matrix of Q input vectors.
%    T - SxQ matrix of Q target vectors.
%  Returns:
%    W - SxR weight matrix.
%    B - Sx1 bias vector.
%  
%  SOLVELIN(P,T)
%  Returns SxR weight matrix for network without biases.
%  
%  See also NNSOLVE, LINNET, SIMLIN, INITLIN, LEARNWH, ADAPTWH, TRAINWH.

% Mark Beale, 1-31-92
% Copyright 1992-2002 The MathWorks, Inc.
% $Revision: 1.11.4.1 $  $Date: 2008/10/31 06:24:37 $

if nargin < 2,error('NNET:solvelin:Arguments','Not enough arguments.'),end

if nargout <= 1
  w= t/p;
else
  [pr,pc] = size(p);
  x = t/[p; ones(1,pc)];
  w = x(:,1:pr);
  b = x(:,pr+1);
end
