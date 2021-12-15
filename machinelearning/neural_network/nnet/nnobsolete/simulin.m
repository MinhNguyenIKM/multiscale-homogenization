function a = simulin(p,w,b)
%SIMULIN Simulate linear layer.
%  
%  This function is obselete.
%  Use NNT2LIN and SIM to update and simulate your network.

nntobsf('simulin','Use NNT2LIN and SIM to update and simulate your network.')

%  SIMULIN(P,W,B)
%    P - RxQ Matrix of input (column) vectors.
%    W - SxR Weight matrix of the layer.
%    B - Sx1 Bias (column) vector of the layer.
%  Returns outputs of the perceptron layer.
%  
%  EXAMPLE: [w,b] = initlin(2,3);
%           p = [2; -3];
%           a = simulin(p,w,b)
%  
%  See also NNSIM, LINNET, SOLVELIN, INITLIN, LEARNWH, ADAPTWH, TRAINWH.

% Mark Beale, 12-15-93
% Copyright 1992-2002 The MathWorks, Inc.
% $Revision: 1.11.4.1 $  $Date: 2008/10/31 06:24:31 $

if nargin < 2,error('NNET:simulin:Arguments','Not enough arguments'), end

if nargin == 2
  a = purelin(w*p);
else
  a = purelin(w*p,b);
end
