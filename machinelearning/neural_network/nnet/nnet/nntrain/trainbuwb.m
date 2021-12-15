function [net,tr]=trainbuwb(net,tr,trainV,valV,testV,varargin)
%TRAINBUWB Batch unsupervised weight/bias training.
%
%  Syntax
%  
%    [net,tr] = trainbuwb(net,tr,trainV,valV,testV)
%    info = trainbuwb('info')
%
%  Description
%
%    TRAINBUWB is not called directly.  Instead it is called by TRAIN for
%    network's whose NET.trainFcn property is set to 'trainbuwb'.
%
%    TRAINBUWB trains a network with weight and bias learning rules
%    with batch updates. The weights and biases are updated at the end of
%    an entire pass through the input data.
%
%    TRAINBUWB(NET,TR,TRAINV,VALV,TESTV) takes these inputs,
%      NET - Neural network.
%      TR  - Initial training record created by TRAIN.
%      TRAINV - Training data created by TRAIN.
%      VALV - Validation data created by TRAIN.
%      TESTV - Test data created by TRAIN.
%    and returns,
%      NET - Trained network.
%      TR  - Training record of various values over each epoch.
%
%    Each argument TRAINV, VALV and TESTV is a structure of these fields:
%      X  - NxTS cell array of inputs for N inputs and TS timesteps.
%           X{i,ts} is an RixQ matrix for ith input and ts timestep.
%      Xi - NxNid cell array of input delay states for N inputs and Nid delays.
%           Xi{i,j} is an RixQ matrix for ith input and jth state.
%      Pd - NxSxNid cell array of delayed input states.
%      T  - NoxTS cell array of targets for No outputs and TS timesteps.
%           T{i,ts} is an SixQ matrix for the ith output and ts timestep.
%      Tl - NlxTS cell array of targets for Nl layers and TS timesteps.
%           Tl{i,ts} is an SixQ matrix for the ith layer and ts timestep.
%      Ai - NlxTS cell array of layer delays states for Nl layers, TS timesteps.
%           Ai{i,j} is an SixQ matrix of delayed outputs for layer i, delay j.
%
%    Training occurs according to training parameters, with default values:
%      net.trainParam.epochs = 100, Maximum number of epochs to train
%      net.trainParam.show = 25, Epochs between displays
%      net.trainParam.showCommandLine = false, generate command line output
%      net.trainParam.showWindow = true, show training GUI
%      net.trainParam.show = 25,  Epochs between displays (NaN for no displays)
%      net.trainParam.time = inf,  Maximum time to train in seconds
%
%    Validation and test vectors have no impact on training for this
%    function, but act as independent measures of network generalization.
%
%    TRAINBUWB('info') returns useful information about this function.
%
%  Network Use
%
%    You can create a standard network that uses TRAINBUWB by calling
%    NEWSOM.
%
%    To prepare a custom network to be trained with TRAINB:
%    1) Set NET.trainFcn to 'trainbuwb'.
%       (This will set NET.trainParam to TRAINBUWB's default parameters.)
%    2) Set each NET.inputWeights{i,j}.learnFcn to a learning function.
%       Set each NET.layerWeights{i,j}.learnFcn to a learning function.
%       Set each NET.biases{i}.learnFcn to a learning function.
%       (Weight and bias learning parameters will automatically be
%       set to default values for the given learning function.)
%
%    To train the network:
%    1) Set NET.trainParam properties to desired values.
%    2) Set weight and bias learning parameters to desired values.
%    3) Call TRAIN.
%
%    See NEWSOM for training examples.
%
%  Algorithm
%
%    Each weight and bias updates according to its learning function
%    after each epoch (one pass through the entire set of input vectors).
%
%    Training stops when any of these conditions are met:
%    1) The maximum number of EPOCHS (repetitions) is reached.
%    2) Performance has been minimized to the GOAL.
%    3) The maximum amount of TIME has been exceeded.
%    4) Validation performance has increase more than MAX_FAIL times
%       since the last time it decreased (when using validation).
%
%  See also NEWSOM, TRAIN.

% Copyright 2007-2008 The MathWorks, Inc.
% $Revision: 1.1.6.3 $  $Date: 2008/03/13 17:33:23 $

%% Info
if strcmp(net,'info')
  info.function = mfilename;
  info.title = 'Batch Unsupervised Weight/Bias Training';
  info.type = 'Training';
  info.version = 6;
  info.training_mode = 'Unsupervised';
  info.gradient_mode = '';
  info.uses_validation = false;
  info.param_defaults.show = 25;
  info.param_defaults.showWindow = true;
  info.param_defaults.showCommandLine = false;
  info.param_defaults.epochs = 100;
  info.param_defaults.time = inf;
  info.training_states = [];
  net = info;
  return
end

%% NNET 5.1 Backward Compatibility
if ischar(net)
  switch (net)
    case 'name', info = feval(mfilename,'info'); net = info.title;
    case 'pnames', info = feval(mfilename,'info'); net = fieldnames(info.param_defaults);
    case 'pdefaults', info = feval(mfilename,'info'); net = info.param_defaults;
    case 'gdefaults', if tr ==0, net='calcgrad'; else net='calcgbtt'; end
    otherwise, error('NNET:Arguments','Unrecognized code.')
  end
  return
end

%% Initialize
epochs = net.trainParam.epochs;
max_time = net.trainParam.time;

% Parameter Checking
if (~isa(epochs,'double')) || (~isreal(epochs)) || (any(size(epochs)) ~= 1) || ...
  (epochs < 1) || (round(epochs) ~= epochs)
  error('NNET:Arguments','Epochs is not a positive integer.')
end
if (~isa(max_time,'double')) || (~isreal(max_time)) || (any(size(max_time)) ~= 1) || ...
  (max_time < 0)
  error('NNET:Arguments','Time is not zero or a positive real value.')
end

%% setup
numLayers = net.numLayers;
numInputs = net.numInputs;
numLayerDelays = net.numLayerDelays;

% Signals
BP = ones(1,trainV.Q);
gIW = cell(numLayers,numInputs,trainV.TS);
gLW = cell(numLayers,numLayers,trainV.TS);
gB = cell(net.numLayers,1,trainV.TS);
gA = cell(net.numLayers,trainV.TS);
IWLS = cell(numLayers,numInputs);
LWLS = cell(numLayers,numLayers);
BLS = cell(numLayers,1);

%% Initialize
startTime = clock;
original_net = net;

%% Training Record
tr.best_epoch = 0;
tr.goal = NaN;
tr.states = {'epoch','time'};

%% Status
status = ...
  [ ...
  training_status('Epoch','iterations','linear','discrete',0,epochs,0), ...
  training_status('Time','seconds','linear','discrete',0,max_time,0), ...
  ];
nn_train_feedback('start',net,status);

%% Train
for epoch=0:epochs

  % Performance
  [Ac,N,Zl,Zi,Zb] = calca(net,trainV.Pd,trainV.Ai,trainV.Q,trainV.TS);
  
  % Stopping Criteria
  time = etime(clock,startTime);
  [userStop,userCancel] = nntraintool('check');
  if userStop, tr.stop = 'User stop.';
  elseif userCancel, tr.stop = 'User cancel.'; net = original_net;
  elseif (epoch == epochs), tr.stop = 'Maximum epoch reached.';
  elseif (time > max_time), tr.stop = 'Maximum time elapsed.';
  end
  
  % Training record
  tr = tr_update(tr,[epoch time]);
  
  % Feedback
  nn_train_feedback('update',net,status,tr,{trainV valV testV},[epoch,time]);
  
  % Stop
  if ~isempty(tr.stop), break, end

  % Update with Weight and Bias Learning Functions
  for ts=1:trainV.TS
    for i=1:numLayers

      % Update Input Weight Values
      for j=find(net.inputConnect(i,:))
        learnFcn = net.inputWeights{i,j}.learnFcn;
        if ~isempty(learnFcn)
          [dw,IWLS{i,j}] = feval(learnFcn,net.IW{i,j}, ...
            trainV.Pd{i,j,ts},Zi{i,j},N{i},Ac{i,ts+numLayerDelays},trainV.Tl{i,ts},[],gIW{i,j,ts},...
            gA{i,ts},net.layers{i}.distances,net.inputWeights{i,j}.learnParam,IWLS{i,j});
          net.IW{i,j} = net.IW{i,j} + dw;
        end
      end
  
      % Update Layer Weight Values
      for j=find(net.layerConnect(i,:))
        learnFcn = net.layerWeights{i,j}.learnFcn;
        if ~isempty(learnFcn)
          Ad = cell2mat(Ac(j,ts+numLayerDelays-net.layerWeights{i,j}.delays)');
          [dw,LWLS{i,j}] = feval(learnFcn,net.LW{i,j}, ...
            Ad,Zl{i,j},N{i},Ac{i,ts+numLayerDelays},trainV.Tl{i,ts},El{i,ts},gLW{i,j,ts},...
            gA{i,ts},net.layers{i}.distances,net.layerWeights{i,j}.learnParam,LWLS{i,j});
          net.LW{i,j} = net.LW{i,j} + dw;
        end
      end

      % Update Bias Values
      if net.biasConnect(i)
        learnFcn = net.biases{i}.learnFcn;
        if ~isempty(learnFcn)
          [db,BLS{i}] = feval(learnFcn,net.b{i}, ...
            BP,Zb{i},N{i},Ac{i,ts+numLayerDelays},trainV.Tl{i,ts},El{i,ts},gB{i,ts},...
            gA{i,ts},net.layers{i}.distances,net.biases{i}.learnParam,BLS{i});
          net.b{i} = net.b{i} + db;
        end
      end
    end
  end
end

% Finish
tr = tr_clip(tr);
