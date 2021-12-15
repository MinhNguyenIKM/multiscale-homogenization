function [net,tr]=trainb(net,tr,trainV,valV,testV,varargin)
%TRAINB Batch training with weight & bias learning rules.
%
%  Syntax
%  
%    [net,tr] = trainb(net,tr,trainV,valV,testV)
%    info = trainb('info')
%
%  Description
%
%    TRAINB is not called directly.  Instead it is called by TRAIN for
%    network's whose NET.trainFcn property is set to 'trainb'.
%
%    TRAINB trains a network with weight and bias learning rules
%    with batch updates. The weights and biases are updated at the end of
%    an entire pass through the input data.
%
%    TRAINB(NET,TR,TRAINV,VALV,TESTV) takes these inputs,
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
%      net.trainParam.epochs  100  Maximum number of epochs to train
%      net.trainParam.goal      0  Performance goal
%      net.trainParam.max_fail  5  Maximum validation failures
%      net.trainParam.show     25  Epochs between displays
%      net.trainParam.showCommandLine false, generate command line output
%      net.trainParam.showWindow true, show training GUI
%      net.trainParam.time    inf  Maximum time to train in seconds
%
%    TRAINB('info') returns useful information about this function.
%
%  Network Use
%
%    You can create a standard network that uses TRAINB by calling
%    NEWLIN.
%
%    To prepare a custom network to be trained with TRAINB:
%    1) Set NET.trainFcn to 'trainb'.
%       (This will set NET.trainParam to TRAINB's default parameters.)
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
%    See NEWLIN for training examples.
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
%  See also NEWP, NEWLIN, TRAIN.

% Mark Beale, 11-31-97
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.9 $  $Date: 2008/12/01 07:20:37 $

%% Info
if strcmp(net,'info')
  info.function = mfilename;
  info.title = 'Batch Weight/Bias Learning Rules';
  info.type = 'Training';
  info.version = 6;
  info.training_mode = 'Supervised';
  info.gradient_mode = 'Jacobian';
  info.uses_validation = true;
  
  info.param_defaults.show = 25;
  info.param_defaults.showWindow = true;
  info.param_defaults.showCommandLine = false;
  info.param_defaults.epochs = 1000;
  info.param_defaults.time = inf;
  info.param_defaults.goal = 0;
  info.param_defaults.max_fail = 6;
  
  info.training_states = ...
    training_state_info('val_fail','Validation Checks','discrete','linear');
  net = info;
  return
end

%% NNET 5.1 Backward Compatibility
if ischar(net)
  switch (net)
    case 'name', info = feval(mfilename,'info'); net = info.title;
    case 'pnames', info = feval(mfilename,'info'); net = fieldnames(info.param_defaults);
    case 'pdefaults', info = feval(mfilename,'info'); net = info.param_defaults;
    case 'gdefaults', if (tr==0), net = 'calcgrad'; else net='calcgbtt'; end
    otherwise, error('NNET:Arguments','Unrecognized code.')
  end
  return
end

% CALCULATION
% ===========

% Parameters
epochs = net.trainParam.epochs;
goal = net.trainParam.goal;
max_fail = net.trainParam.max_fail;
show = net.trainParam.show;
time = net.trainParam.time;

% Parameter Checking
if (~isa(epochs,'double')) || (~isreal(epochs)) || (any(size(epochs)) ~= 1) || ...
  (epochs < 1) || (round(epochs) ~= epochs)
  error('NNET:Arguments','Epochs is not a positive integer.')
end
if (~isa(goal,'double')) || (~isreal(goal)) || (any(size(goal)) ~= 1) || ...
  (goal < 0)
  error('NNET:Arguments','Goal is not zero or a positive real value.')
end
if (~isa(max_fail,'double')) || (~isreal(max_fail)) || (any(size(max_fail)) ~= 1) || ...
  (max_fail < 1) || (round(max_fail) ~= max_fail)
  error('NNET:Arguments','Max_fail is not a positive integer.')
end
if (~isa(show,'double')) || (~isreal(show)) || (any(size(show)) ~= 1) || ...
  (isfinite(show) && ((show < 1) || (round(show) ~= show)))
  error('NNET:Arguments','Show is not ''NaN'' or a positive integer.')
end
if (~isa(time,'double')) || (~isreal(time)) || (any(size(time)) ~= 1) || ...
  (time < 0)
  error('NNET:Arguments','Time is not zero or a positive real value.')
end

%% Initialize
Q = trainV.Q;
TS = trainV.TS;
vperf = NaN;
tperf = NaN;
val_fail = 0;
startTime = clock;
X = getx(net);

% Constants
numLayers = net.numLayers;
numInputs = net.numInputs;
numLayerDelays = net.numLayerDelays;
needGradient = net.hint.needGradient;
performFcn = net.performFcn;
if isempty(performFcn), performFcn = 'nullpf'; end

% Signals
BP = ones(1,Q);
gIW = cell(numLayers,numInputs,TS);
gLW = cell(numLayers,numLayers,TS);
gB = cell(net.numLayers,1,TS);
gA = cell(net.numLayers,TS);
IWLS = cell(numLayers,numInputs);
LWLS = cell(numLayers,numLayers);
BLS = cell(numLayers,1);

% Initialize Performance
original_net = net;
best_net = net;
doValidation = ~isempty(valV.indices);
doTest = ~isempty(testV.indices);
[perf,El,trainV.Y,Ac,N,Zb,Zi,Zl] = calcperf2(net,X,trainV.Pd,trainV.Tl,trainV.Ai,Q,TS);
best_perf = perf;
if (doValidation)
  [vperf,ignore,valV.Y] = calcperf2(net,X,valV.Pd,valV.Tl,valV.Ai,valV.Q,valV.TS);
  best_vperf = vperf;
end

%% Training Record
tr.best_epoch = 0;
tr.goal = goal;
tr.states = {'epoch','time','perf','vperf','tperf','val_fail'};

%% Status
status = ...
  [ ...
  training_status('Epoch','iterations','linear','discrete',0,epochs,0), ...
  training_status('Time','seconds','linear','discrete',0,time,0), ...
  training_status('Performance','','log','continuous',best_perf,goal,best_perf) ...
  training_status('Validation Checks','','linear','discrete',0,max_fail,0) ...
  ];
nn_train_feedback('start',net,status);

% Train
for epoch=0:epochs
  
  % Stopping Criteria
  current_time = etime(clock,startTime);
  [userStop,userCancel] = nntraintool('check');
  if userStop, tr.stop = 'User stop.'; net = best_net;
  elseif userCancel, tr.stop = 'User cancel.'; net = original_net;
  elseif (perf <= goal), tr.stop = 'Performance goal met.'; net = best_net;
  elseif (epoch == epochs), tr.stop = 'Maximum epoch reached.'; net = best_net;
  elseif (current_time >= time), tr.stop = 'Maximum time elapsed.'; net = best_net;
  elseif (doValidation) && (val_fail >= max_fail), tr.stop = 'Validation stop.'; net = best_net;
  end

  % Training record
  if doTest
    [tperf,ignore,testV.Y] = calcperf2(net,X,testV.Pd,testV.Tl,testV.Ai,testV.Q,testV.TS);
  end
  tr = tr_update(tr,[epoch current_time perf vperf tperf val_fail]);
  
  % Feedback
  nn_train_feedback('update',net,status,tr,{trainV valV testV}, ...
    [epoch,current_time,best_perf,val_fail]);
  
  % Stop
  if ~isempty(tr.stop), break, end
  
  % Performance
  E = El(net.outputConnect,:);
  perf = feval(performFcn,E,trainV.Y,X,net.performParam);

  % Gradient
  if (needGradient)
    gE = cell(net.numLayers,TS);
    gE(net.outputConnect,:) = feval(performFcn,'dy',E,trainV.Y,X,perf,net.performParam);
    [gB,gIW,gLW,gA] = calcgrad(net,Q,trainV.Pd,Zb,Zi,Zl,N,Ac,gE,TS);
  end
  
  % Update with Weight and Bias Learning Functions
  for ts=1:TS
    for i=1:numLayers

      % Update Input Weight Values
      for j=find(net.inputConnect(i,:))
        learnFcn = net.inputWeights{i,j}.learnFcn;
        if ~isempty(learnFcn)
          [dw,IWLS{i,j}] = feval(learnFcn,net.IW{i,j}, ...
            trainV.Pd{i,j,ts},Zi{i,j},N{i},Ac{i,ts+numLayerDelays},trainV.Tl{i,ts},El{i,ts},gIW{i,j,ts},...
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
  X = getx(net);
  [perf,El,trainV.Y,Ac,N,Zb,Zi,Zl] = calcperf2(net,X,trainV.Pd,trainV.Tl,trainV.Ai,Q,TS);
  
  % Validation
  if (doValidation)
    [vperf,ignore,valV.Y] = calcperf2(net,X,valV.Pd,valV.Tl,valV.Ai,valV.Q,valV.TS);
    if (vperf < best_vperf)
      best_net = net;
      best_perf = perf;
      best_vperf = vperf;
      tr.best_epoch = epoch+1;
      val_fail = 0;
    elseif (vperf > best_vperf)
      val_fail = val_fail + 1;
    end
  elseif (perf < best_perf)
    best_net = net;
    best_perf = perf;
    tr.best_epoch = epoch+1;
  end
end

%% Finish
tr = tr_clip(tr);
