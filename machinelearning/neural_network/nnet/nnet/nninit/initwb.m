function net=initwb(net,i)
%INITWB By-weight-and-bias layer initialization function.
%
%  Syntax
%
%    net = initwb(net,i)
%  
%  Description
%
%    INITWB is a layer initialization function which initializes
%    a layer's weights and biases according to their own initialization
%    functions.
%
%    INITWB(NET,i) takes two arguments,
%      NET - Neural network.
%      i   - Index of a layer.
%    and returns the network with layer i's weights and biases updated.
%
%  Network Use
%
%    You can create a standard network that uses INITWB by calling
%    NEWP or NEWLIN.
%
%    To prepare a custom network to be initialized with INITWB:
%    1) Set NET.initFcn to 'initlay'.
%       (This will set NET.initParam to the empty matrix [] since
%       INITLAY has no initialization parameters.)
%    2) Set NET.layers{i}.initFcn to 'initwb'.
%    3) Set each NET.inputWeights{i,j}.initFcn to a weight initialization function.
%       Set each NET.layerWeights{i,j}.initFcn to a weight initialization function.
%       Set each NET.biases{i}.initFcn to a bias initialization function.
%       (Examples of such functions are RANDS and MIDPOINT.)
%
%    To initialize the network call INIT.
%
%    See NEWP and NEWLIN for training examples.
%
%  Algorithm
%
%    Each weight (bias) in layer i is set to new values calculated
%    according to its weight (bias) initialization function.
%
%  See also INITNW, INITLAY, INIT.

% Mark Beale, 11-31-97
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.6 $

if ischar(net)
  switch (net)
    case 'name'
      net = 'By-Weight-and-Bias';
    case 'pnames',
      net = {};
    case 'pdefaults',
      net = [];
    otherwise,
    error('NNET:Arguments','Unrecognized code.')
  end
  return
end

% BIAS
if net.biasConnect(i)
  initFcn = net.biases{i}.initFcn;
  if ~isempty(initFcn)
    net.b{i} = feval(initFcn,net.layers{i}.size,[1 1]);
  end
end
  
% INPUT WEIGHTS
for j=find(net.inputConnect(i,:))
  initFcn = net.inputWeights{i,j}.initFcn;
  if ~isempty(initFcn)
    pr = net.inputs{j}.processedRange;
    siz = net.inputs{j}.processedSize;
    cols = net.inputWeights{i,j}.size(2);
    ind = floor(rem((0:(cols-1)),siz))+1;
    pr2 = pr(ind,:);
    if strcmp(initFcn,'initsompc')
      net.IW{i,j} = ...
        initsompc('new_weights',net.inputWeights{i,j},net.inputs{j},net.layers{i});
    else
      net.IW{i,j} = feval(initFcn,net.inputWeights{i,j}.size(1),pr2);
    end
  end
end
  
% LAYER WEIGHTS
for j=find(net.layerConnect(i,:))
  initFcn = net.layerWeights{i,j}.initFcn;
  if ~isempty(initFcn)
    pr = feval(net.layers{j}.transferFcn,'output');
    cols = net.layerWeights{i,j}.size(2);
    ind = ones(1,cols);
    pr2 = pr(ind,:);
    net.LW{i,j} = feval(initFcn,net.layerWeights{i,j}.size(1),pr2);
  end
end
