function net = sp2narx(net)
%SP2NARX Convert a series-parallel NARX network to parallel (feedback) form.
%
%  Syntax
%
%    net = sp2narx(NET)
%
%  Description
%
%    SP2NARX(NET) takes,
%      NET - Original NARX network in series-parallel form
%    and returns an NARX network in parallel (feedback) form.
%
%  Examples
%
%    Here a series-parallel narx network is created.  The network's input ranges
%    from [-1 to 1].  The first layer has five TANSIG neurons, the
%    second layer has one PURELIN neuron.  The TRAINLM network
%    training function is to be used.
%
%      net = newnarxsp({[-1 1] [-1 1]},[1 2],[1 2],[5 1],{'tansig' 'purelin'});
%
%    Here the network is converted from series parallel to parallel narx.
%
%       net2 = sp2narx(net);
%
%  See also NEWNARXSP, NEWNARX

% Orlando De Jesús, Martin Hagan, 7-20-05
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.7 $

if nargin < 1
  error('NNET:Arguments','Not enough input arguments')
end

Nl = net.numLayers;

% Feedback connection is made
net.layerConnect(1,Nl)=1;
net.layerWeights{1,Nl}.delays = net.inputWeights{1,2}.delays;
net.LW{1,Nl} = net.IW{1,2};

% Second input is removed
net.numInputs = 1;
