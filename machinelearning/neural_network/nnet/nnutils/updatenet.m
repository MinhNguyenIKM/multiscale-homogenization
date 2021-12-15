function net = updatenet(net)
%UPDATENET Creates a current network object from an old network structure.
%
%
%  NET = UPDATE(S)
%    S - Structure with fields of old neural network object.
%  Returns
%    NET - New neural network
%
%  This function is caled by NETWORK/LOADOBJ to update old neural
%  network objects when they are loaded from an M-file.

% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.2.4.8 $  $Date: 2008/03/13 17:33:50 $

if isfield(net,'version')
  version = net.version;
  if ischar(version), version = str2double(version); end
elseif isfield(net,'gradientFcn')
  version = 5.0;
else
  version = 0;
end

if ~any(version == [0 5.0 5.1 6.0])
  error('NNET:Compatibility','Unrecognized network object version.')
end

if ischar(version), version = str2double(version); end
if (version == 0)
  net = updatePre5p0_to_5p0(net);
  version = 5.0;
end

if (version == 5.0)
  net = update5p0_to_5p1(net);
  version = 5.1;
end

if (version == 5.1)
  net = update5p1_to_6p0(net);
  version = 6.0;
end

if (version ~= 6.0)
  error('NNET:Compatibility','Unable to update network object.')
end

% Fix order of fields, clear and recalculate hints
net = order_fields(net);
net.hint = [];
net.hint.ok = 0;
net = network(net);
net.numInputs = net.numInputs;
  
%% Order Fields
function net2 = order_fields(net1)

net2.version = net1.version;
net2.name = net1.name;
net2.numInputs = net1.numInputs;
net2.numLayers = net1.numLayers;
net2.numInputDelays = net1.numInputDelays;
net2.numLayerDelays = net1.numLayerDelays;
net2.biasConnect = net1.biasConnect;
net2.inputConnect = net1.inputConnect;
net2.layerConnect = net1.layerConnect;
net2.outputConnect = net1.outputConnect;
net2.numOutputs = net1.numOutputs;
net2.inputs = net1.inputs;
net2.layers = net1.layers;
net2.biases = net1.biases;
net2.inputWeights = net1.inputWeights;
net2.layerWeights = net1.layerWeights;
net2.outputs = net1.outputs;
net2.adaptFcn = net1.adaptFcn;
net2.adaptParam = net1.adaptParam;
net2.divideFcn = net1.divideFcn;
net2.divideParam = net1.divideParam;
net2.gradientFcn = net1.gradientFcn;
net2.gradientParam = net1.gradientParam;
net2.initFcn = net1.initFcn;
net2.initParam = net1.initParam;
net2.performFcn = net1.performFcn;
net2.performParam = net1.performParam;
net2.plotFcns = net1.plotFcns;
net2.plotParams = net1.plotParams;
net2.trainFcn = net1.trainFcn;
net2.trainParam = net1.trainParam;
net2.IW = net1.IW;
net2.LW = net1.LW;
net2.b = net1.b;
net2.userdata = net1.userdata;
net2.hint = net1.hint;
net2.revert = net1.revert;

%% Update 5.0 network
function net = update5p1_to_6p0(net)

net.name = '';
net.version = 6.0;
net.plotFcns = {};
net.plotParams = {};

if ~isempty(net.trainFcn)
  net.trainParam.showCommandLine = false;
  net.trainParam.showWindow = true;
end
net.plotFcns = {'plottrainstate'};

for i=1:net.numInputs
  net.inputs{i}.name = 'Input';
end
for i=1:net.numLayers
  net.layers{i}.name = 'Layer';
end
for i=find(net.outputConnect ~= 0)
  net.outputs{i}.name = 'Output';
end

%% Update 5.0 network
function net = update5p0_to_5p1(net)

net.version = '5.1';

if any(net.targetConnect ~= net.outputConnect)
  warning('NNET:Obsolete','net.targetConnect is now obsolete. Use net.outputConnect instead.');
end

net = rmfield(net,'numTargets');
net = rmfield(net,'targetConnect');
net = rmfield(net,'targets');

for i=1:net.numInputs
  oldInput = net.inputs{i};
  
  newInput = [];
  newInput.exampleInput = oldInput.range;
  newInput.name = 'Input';
  newInput.processFcns = {};
  newInput.processParams = {};
  newInput.processSettings = cell(1,0);
  newInput.processedRange = oldInput.range;
  newInput.processedSize = oldInput.size;
  newInput.range = oldInput.range;
  newInput.size = oldInput.size;
  newInput.userdata = oldInput.userdata;
  
  net.inputs{i} = newInput;
end

for i=find(net.numLayers)
  oldLayer = net.layers{i};
  
  newLayer.dimensions = oldLayer.dimensions;
  newLayer.distanceFcn = oldLayer.distanceFcn;
  newLayer.distances = oldLayer.distances;
  newLayer.initFcn = oldLayer.initFcn;
  newLayer.name = 'Layer';
  newLayer.netInputFcn = oldLayer.netInputFcn;
  newLayer.netInputParam = oldLayer.netInputParam;
  newLayer.positions = oldLayer.positions;
  newLayer.size = oldLayer.size;
  newLayer.topologyFcn = oldLayer.topologyFcn;
  newLayer.transferFcn = oldLayer.transferFcn;
  newLayer.transferParam = oldLayer.transferParam;
  newLayer.userdata = oldLayer.userdata;
  
  net.layers{i} = newLayer;
end

for i=find(net.outputConnect)
  oldOutput = net.outputs{i};
  
  newOutput = [];
  newOutput.exampleOutput = NaN+zeros(oldOutput.size,2);
  newOutput.name = 'Output';
  newOutput.processFcns = {};
  newOutput.processParams = {};
  newOutput.processSettings = {};
  newOutput.processedRange = NaN+zeros(oldOutput.size,2);
  newOutput.processedSize = oldOutput.size;
  newOutput.range = NaN+zeros(oldOutput.size,2);
  newOutput.size = oldOutput.size;
  newOutput.userdata = oldOutput.userdata;
  
  net.outputs{i} = newOutput;
end

net.divideFcn = '';
net.divideParam = [];

net.hint = [];
net.hint.ok = 0;

%% Update Pre-5.0 network
function net2 = updatePre5p0_to_5p0(net1)

% Architecture
net2.numInputs = net1.numInputs;
net2.numLayers = net1.numLayers;
net2.biasConnect = net1.biasConnect;
net2.inputConnect = net1.inputConnect;
net2.layerConnect = net1.layerConnect;
net2.outputConnect = net1.outputConnect;
net2.targetConnect = net1.targetConnect;

net2.numOutputs = net1.numOutputs;
net2.numTargets = net1.numTargets;
net2.numInputDelays = net1.numInputDelays;
net2.numLayerDelays = net1.numLayerDelays;

% inputs
net2.inputs = cell(net2.numInputs,1);
for i=1:net1.numInputs
  net2.inputs{i}.size = net1.inputs{i}.size;
  net2.inputs{i}.range = net1.inputs{i}.range;
  net2.inputs{i}.userdata = net1.inputs{i}.userdata;
end

% layers
net2.layers = cell(net2.numLayers,1);
for i=1:net1.numLayers
  net2.layers{i}.dimensions = net1.layers{i}.dimensions;
  net2.layers{i}.distanceFcn = net1.layers{i}.distanceFcn;
  net2.layers{i}.distances = net1.layers{i}.distances;
  net2.layers{i}.initFcn = net1.layers{i}.initFcn;
  net2.layers{i}.netInputFcn = net1.layers{i}.netInputFcn;
  net2.layers{i}.netInputParam = feval(net1.layers{i}.netInputFcn,'fpdefaults');
  net2.layers{i}.positions = net1.layers{i}.positions;
  net2.layers{i}.size = net1.layers{i}.size;
  net2.layers{i}.topologyFcn = net1.layers{i}.topologyFcn;
  net2.layers{i}.transferFcn = net1.layers{i}.transferFcn;
  net2.layers{i}.transferParam = feval(net1.layers{i}.transferFcn,'fpdefaults');
  net2.layers{i}.userdata = net1.layers{i}.userdata;
end

% biases
net2.biases = cell(net2.numLayers,1);
for i=find(net1.biasConnect')
  net2.biases{i}.initFcn = net1.biases{i}.initFcn;
  net2.biases{i}.learn = net1.biases{i}.learn;
  net2.biases{i}.learnFcn = net1.biases{i}.learnFcn;
  net2.biases{i}.learnParam = net1.biases{i}.learnParam;
  net2.biases{i}.userdata = net1.biases{i}.userdata;
end

% inputsWeights
net2.inputWeights = cell(net2.numLayers,net2.numInputs);
for i=1:net1.numLayers
  for j = find(net1.inputConnect(i,:))
    net2.inputWeights{i,j}.delays = net1.inputWeights{i,j}.delays;
    net2.inputWeights{i,j}.initFcn = net1.inputWeights{i,j}.initFcn;
    net2.inputWeights{i,j}.learn = net1.inputWeights{i,j}.learn;
    net2.inputWeights{i,j}.learnFcn = net1.inputWeights{i,j}.learnFcn;
    net2.inputWeights{i,j}.learnParam = net1.inputWeights{i,j}.learnParam;
    net2.inputWeights{i,j}.size = net1.inputWeights{i,j}.size;
    net2.inputWeights{i,j}.userdata = net1.inputWeights{i,j}.userdata;
    net2.inputWeights{i,j}.weightFcn = net1.inputWeights{i,j}.weightFcn;
    net2.inputWeights{i,j}.weightParam = feval(net1.inputWeights{i,j}.weightFcn,'fpdefaults');
  end
end

% layerWeights
net2.layerWeights = cell(net2.numLayers,net2.numLayers);
for i=1:net1.numLayers
  for j = find(net1.layerConnect(i,:))
    net2.layerWeights{i,j}.delays = net1.layerWeights{i,j}.delays;
    net2.layerWeights{i,j}.initFcn = net1.layerWeights{i,j}.initFcn;
    net2.layerWeights{i,j}.learn = net1.layerWeights{i,j}.learn;
    net2.layerWeights{i,j}.learnFcn = net1.layerWeights{i,j}.learnFcn;
    net2.layerWeights{i,j}.learnParam = net1.layerWeights{i,j}.learnParam;
    net2.layerWeights{i,j}.size = net1.layerWeights{i,j}.size;
    net2.layerWeights{i,j}.userdata = net1.layerWeights{i,j}.userdata;
    net2.layerWeights{i,j}.weightFcn = net1.layerWeights{i,j}.weightFcn;
    net2.layerWeights{i,j}.weightParam = feval(net1.layerWeights{i,j}.weightFcn,'fpdefaults');
  end
end

% outputs
net2.outputs = cell(1,net2.numOutputs);
for i=find(net1.outputConnect)
  net2.outputs{i}.size = net1.outputs{i}.size;
  net2.outputs{i}.userdata = net1.outputs{i}.userdata;
end

% targets
net2.targets = cell(1,net2.numTargets);
for i=find(net1.targetConnect)
  net2.targets{i}.size = net1.targets{i}.size;
  net2.targets{i}.userdata = net1.targets{i}.userdata;
end

% Functions
net2.adaptFcn = net1.adaptFcn;
net2.adaptParam = net1.adaptParam;
net2.initFcn = net1.initFcn;
net2.initParam = net1.initParam;
net2.performFcn = net1.performFcn;
net2.performParam = net1.performParam;
net2.trainFcn = net1.trainFcn;
net2.trainParam = net1.trainParam;

if isfield(net1,'gradientFcn'),
  net2.gradientFcn = net1.gradientFcn;
  net2.gradientParam = net1.gradientParam;
elseif ~isempty(net2.trainFcn)
  net2.gradientFcn = feval(net2.trainFcn,'gdefaults',net2.numLayerDelays);
  net2.gradientParam = [];
else
  net2.gradientFcn = '';
  net2.gradientParam = [];
end

% Weight and Bias Values
net2.IW = net1.IW;
net2.LW = net1.LW;
net2.b = net1.b;

% User data
net2.userdata = net1.userdata; 
net2.hint = [];
net2.revert = [];
