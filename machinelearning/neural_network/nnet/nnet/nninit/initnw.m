function net=initnw(net,i)
%INITNW Nguyen-Widrow layer initialization function.
%
%  Syntax
%
%    net = initnw(net,i)
%
%  Description
%
%    INITNW is a layer initialization function which initializes
%    a layer's weights and biases according to the Nguyen-Widrow
%    initialization algorithm.  This algorithm chooses values in order
%    to distribute the active region of each neuron in the layer
%    evenly across the layer's input space.
%
%    INITNW is best used with layers whose transfer function has a finite
%    active input interval, such as TANSIG, not an infinite active input
%    interval, such as PURELIN.
%
%    INITNW(NET,i) takes two arguments,
%      NET - Neural network.
%      i   - Index of a layer.
%    and returns the network with layer i's weights and biases updated.
%
%  Network Use
%
%    You can create a standard network that uses INITNW by calling
%    NEWFF or NEWCF.
%
%    To prepare a custom network to be initialized with INITNW:
%    1) Set NET.initFcn to 'initlay'.
%       (This will set NET.initParam to the empty matrix [] since
%       INITLAY has no initialization parameters.)
%    2) Set NET.layers{i}.initFcn to 'initnw'.
%
%    To initialize the network call INIT.
%
%    See NEWFF and NEWCF for training examples.
%
%  Algorithm
%
%    The Nguyen-Widrow method generates initial weight and bias
%    values for a layer so that the active regions of the layer's
%    neurons will be distributed roughly evenly over the input space.
%
%    Advantages over purely random weights and biases are:
%    (1) Few neurons are wasted (since all the neurons are in the input space).
%    (2) Training works faster (since each area of the input space has neurons).
%
%    The Nguyen-Widrow method can only be applied to layers...
%    ...with a bias,
%    ...with weights whose "weightFcn" is DOTPROD,
%    ...with "netInputFcn" set to NETSUM.
%    If these conditions are not met then INITNW uses RANDS to
%    initialize the layer's weights and biases.
%
%  See also INITLAY, INITWB, INIT.

% Mark Beale, 11-31-97
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.8 $

if (nargin < 1), error('NNET:Arguments','Not enough arguments.'); end
if ischar(net)
  switch(net)
    case 'name'
      net = 'Nguyen-Widrow';
    otherwise, error('NNET:Arguments',['Unrecognized code: ''' net ''''])
  end
  return
end

% Calculate source indices
inputInds = find(net.inputConnect(i,:));
numInputs = length(inputInds);
layerInds = find(net.layerConnect(i,:));
numLayers = length(layerInds);

% Get source sizes and delays
inputSizes = zeros(numInputs,1);
inputDelays = zeros(numInputs,1);
for j=1:numInputs
  inputDelays(j) = length(net.inputWeights{i,inputInds(j)}.delays);
  inputSizes(j) = net.inputWeights{i,inputInds(j)}.size(2);
end
totalInputSize = sum(inputSizes);

layerSizes = zeros(numLayers,1);
layerDelays = zeros(numInputs,1);
for j=1:numLayers
  layerDelays(j) = length(net.layerWeights{i,layerInds(j)}.delays);
  layerSizes(j) = net.layerWeights{i,layerInds(j)}.size(2);
end
totalLayerSize = sum(layerSizes);

totalSourceSize = totalInputSize + totalLayerSize;

% Calculate range indices
inputStart = cumsum([1; inputSizes]);
inputStop = cumsum(inputSizes);
layerStart = cumsum([1; layerSizes])+totalInputSize;
layerStop = cumsum(layerSizes)+totalInputSize;

% Get source ranges
range = zeros(totalSourceSize,2);
for j=1:numInputs
  irange = net.inputs{inputInds(j)}.processedRange;
  
  % ODJ 4/1/02 Avoid problem with delays and one column weights
  temp=size(irange,1)*inputDelays(j);
  if temp~=inputStop(j)-inputStart(j)-1
     temp=repmat(irange,inputDelays(j),1);
     range(inputStart(j):inputStop(j),:) = temp((inputStart(j):inputStop(j))-inputStart(j)+1,:);
  else  
     range(inputStart(j):inputStop(j),:) = repmat(irange,inputDelays(j),1);
  end
end
for j=1:numLayers
  lrange = feval(net.layers{layerInds(j)}.transferFcn,'output');
  if any(~isfinite(lrange))
    lrange = [max(lrange(1),-1) min(lrange(2),1)];
  end
  range(layerStart(j):layerStop(j),:) = lrange(ones(layerSizes(j),1),:);
end

% Get transferFcn info
transferFcn = net.layers{i}.transferFcn;
active = feval(transferFcn,'active');

% Check layer and sources for compatibility with Nguyen-Widrow method
ok = 1;
if ~strcmp(net.layers{i}.netInputFcn,'netsum')
  ok = 0;
end
if ~net.biasConnect(i)
  ok = 0;
end
if ~all(isfinite(active))
  ok = 0;
end
for j=1:numInputs
  if ~strcmp(net.inputWeights{i,inputInds(j)}.weightFcn,'dotprod')
    ok = 0;
  end
end
for j=1:numLayers
  if ~strcmp(net.layerWeights{i,layerInds(j)}.weightFcn,'dotprod')
    ok = 0;
  end
end

% Use Nguyen-Widrow method if network checks out ok
if ok
  [w,b] = calcnw(range,net.layers{i}.size,active);
  
% Otherwise use RANDS
else
  sizeRows = 0;
  for j=1:numInputs
    if(net.inputWeights{i,inputInds(j)}.size(1)>sizeRows)
      sizeRows = net.inputWeights{i,inputInds(j)}.size(1);
    end
  end
  for j=1:numLayers
    if(net.layerWeights{i,layerInds(j)}.size(1)>sizeRows)
      sizeRows = net.layerWeights{i,layerInds(j)}.size(1);
    end
  end
  w = rands(sizeRows,totalSourceSize);
  if net.biasConnect(i)
    b = rands(net.layers{i}.size,1);
  end
end

for j=1:numInputs
  net.IW{i,inputInds(j)} = w(1:net.inputWeights{i,inputInds(j)}.size(1),inputStart(j):inputStop(j));
end
for j=1:numLayers
  net.LW{i,layerInds(j)} = w(1:net.layerWeights{i,layerInds(j)}.size(1),layerStart(j):layerStop(j));
end
if net.biasConnect(i)
  net.b{i} = b;
end

%===========================================================
function [w,b]=calcnw(pr,s,n)
%CALCNW Calculates Nugyen-Widrow initial conditions.
%
%  PR
%  S - Number of neurons.
%  N - Active region of transfer function N = [Nmin Nmax].

r = size(pr,1);

% Null case
% ---------

if (r == 0) || (s == 0)
  w = zeros(s,r);
  b = zeros(s,1);
  return
end

% Remove constant inputs that provide no useful info
% --------------------------------------------------

R = r;
ind = find(pr(:,1) ~= pr(:,2));
r = length(ind);
pr = pr(ind,:);

% Nguyen-Widrow Method
% --------------------

% Assume inputs and net inputs range in [-1 1].

% Weights
wMag = 0.7*s^(1/r);
wDir = randnr(s,r);
w = wMag*wDir;

% Biases
if (s==1)
  b = 0;
else
  b = wMag*linspace(-1,1,s)'.*sign(w(:,1));
end

% Conversions
% -----------

% Conversion of net inputs of [-1 1] to [Nmin Nmax]
x = 0.5*(n(2)-n(1));
y = 0.5*(n(2)+n(1));
w = x*w;
b = x*b+y;

% Conversion of inputs of PR to [-1 1]
x = 2./(pr(:,2)-pr(:,1));
y = 1-pr(:,2).*x;

xp = x';
b = w*y+b;
w = w.*xp(ones(1,s),:);

% Replace constant inputs
% -----------------------

ww = w;
w = zeros(s,R);
w(:,ind) = ww;

%===========================================================
