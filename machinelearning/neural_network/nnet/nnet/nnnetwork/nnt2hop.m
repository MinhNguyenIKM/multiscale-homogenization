function net = nnt2hop(w,b)
%NNT2HOP Update NNT 2.0 Hopfield recurrent network.
%
%  Syntax
%
%    net = nnt2p(w,b)
%
%  Description
%
%    NNT2HOP(W,B) takes these arguments,
%      W   - SxS weight matrix.
%      B   - Sx1 bias vector
%    and returns a perceptron.
%
%    Once a network has been updated it can be simulated,
%    initialized, adapted, or trained with SIM, INIT, ADAPT, and TRAIN.
%    
%  See also NEWHOP.

% Mark Beale, 11-31-97
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.5 $

% Check
if size(w,1) ~= size(w,2), error('NNET:Arguments','W must be a square matrix.'), end
if size(w,1) ~= size(b,1), error('NNET:Arguments','W and B sizes do not match.'), end
if size(b,2) ~= 1, error('NNET:Arguments','B must have one column.'), end

% Update
net = network(0,1,1,[],1,1);
net.layers{1}.size = size(w,1);
net.layers{1}.transferFcn = 'satlins';
net.b{1} = b;
net.lw{1,1} = w;
net.layerWeights{1,1}.delays = 1;
