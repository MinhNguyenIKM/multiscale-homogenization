function [w,b] = initlin(r,s)
%INITLIN Initialize linear layer.
%  
%  This function is obselete.
%  Use NNT2LIN and INIT to update and initialize your network.

nntobsf('initlin','Use NNT2LIN and INIT to update and initialize your network.')

%  [W,B] = INITLIN(R,S)
%    R - Number of inputs to the layer.
%    S - Number of neurons in layer.
%  Returns:
%    W - SxR Weight matrix.
%    B - Bias (column) vector.
%  
%  [W,B] = INITLIN(P,T)
%    P - RxQ matrix of input vectors.
%    T - SxQ matrix of target outputs.
%  Returns weights and biases.
%  
%  EXAMPLE: [w,b] = initlin(2,3)
%           p = [1; 2; 3];
%           a = simulin(p,w,b)
%  
%  See also NNINIT, LINNET, SOLVELIN, SIMULIN, LEARNWH, ADAPTWH, TRAINWH.

% Mark Beale, 12-15-93
% Copyright 1992-2002 The MathWorks, Inc.
% $Revision: 1.11.4.1 $  $Date: 2008/10/31 06:23:55 $

if nargin < 2,error('NNET:initlin:Arguments','Not enough arguments.'),end

% NUMBER OF INPUTS
[R,Q] = size(r);
if max(R,Q) > 1
  r = R;
end

% NUMBER OF NEURONS
[S,Q] = size(s);
if max(S,Q) > 1
  s = S;
end

[w,b] = rands(s,r);
