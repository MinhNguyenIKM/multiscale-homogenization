function [net,tr]=trainc(net,tr,trainV,valV,testV,varargin)
%TRAINC Cyclical order weight/bias training.
%
%  Syntax
%  
%    [net,tr] = trainc(net,tr,trainV,valV,testV)
%    info = trainc('info')
%
%  Description
%
%    TRAINC is not called directly.  Instead it is called by TRAIN for
%    network's whose NET.trainFcn property is set to 'trainc'.
%
%    TRAINC trains a network with weight and bias learning rules with
%    incremental updates after each presentation of an input.  Inputs
%    are presented in cyclic order.
%
%    TRAINC(NET,TR,TRAINV,VALV,TESTV) takes these inputs,
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
%      net.trainParam.show     25  Epochs between displays
%      net.trainParam.showCommandLine false, generate command line output
%      net.trainParam.showWindow true, show training GUI
%      net.trainParam.epochs  100  Maximum number of epochs to train
%      net.trainParam.goal      0  Performance goal
%      net.trainParam.max_fail  5  Maximum validation failures
%      net.trainParam.time    inf  Maximum time to train in seconds
%
%
%    TRAINC('info') returns useful information about this function.
%
%  Network Use
%
%    You can create a standard network that uses TRAINC by calling
%    NEWP.
%
%    To prepare a custom network to be trained with TRAINC:
%    1) Set NET.trainFcn to 'trainc'.
%       (This will set NET.trainParam to TRAINC default parameters.)
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
%    See NEWP for training examples.
%
%  Algorithm
%
%    For each epoch, each vector (or sequence) is presented in order
%    to the network with the weight and bias values updated accordingly
%    after each individual presentation.
%
%    Training stops when any of these conditions are met:
%    1) The maximum number of EPOCHS (repetitions) is reached.
%    2) Performance has been minimized to the GOAL.
%    3) The maximum amount of TIME has been exceeded.
%
%  See also NEWP, NEWLIN, TRAIN.

% Mark Beale, 11-31-97
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.8 $  $Date: 2008/03/13 17:33:24 $

%% Info
if strcmp(net,'info')
  info.function = mfilename;
  info.title = 'Cyclical Order Weight/Bias Learning Rules';
  info.type = 'Training';
  info.version = 6;
  info.training_mode = 'Supervised';
  info.gradient_mode = '';
  info.uses_validation = false;
  
  info.param_defaults.show = 25;
  info.param_defaults.showWindow = true;
  info.param_defaults.showCommandLine = false;
  info.param_defaults.epochs = 100;
  info.param_defaults.goal = 0;
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

%% Parameters
epochs = net.trainParam.epochs;
goal = net.trainParam.goal;
time = net.trainParam.time;
show = net.trainParam.show;

% Parameter Checking
if (~isa(epochs,'double')) || (~isreal(epochs)) || (any(size(epochs)) ~= 1) || ...
  (epochs < 1) || (round(epochs) ~= epochs)
  error('NNET:Arguments','Epochs is not a positive integer.')
end
if (~isa(goal,'double')) || (~isreal(goal)) || (any(size(goal)) ~= 1) || ...
  (goal < 0)
  error('NNET:Arguments','Goal is not zero or a positive real value.')
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

numLayers = net.numLayers;
numInputs = net.numInputs;
numLayerDelays = net.numLayerDelays;
needGradient = net.hint.needGradient;
performFcn = net.performFcn;
if isempty(performFcn), performFcn = 'nullpf'; end

% Divide up batches
Pd_div = batchdiv(trainV.Pd,Q);
Tl_div = batchdiv(trainV.Tl,Q);
Ai_div = batchdiv(trainV.Ai,Q);

% Signals
BP = 1;
gIW = cell(numLayers,numInputs,TS);
gLW = cell(numLayers,numLayers,TS);
gB = cell(net.numLayers,1,TS);
gA = cell(net.numLayers,TS);
IWLS = cell(numLayers,numInputs);
LWLS = cell(numLayers,numLayers);
BLS = cell(numLayers,1);

% Initialize
vperf = NaN;
tperf = NaN;
startTime = clock;
X = getx(net);
original_net = net;
doValidation = ~isempty(valV.indices);
doTest = ~isempty(testV.indices);
[perf,El,trainV.Y] = calcperf2(net,X,trainV.Pd,trainV.Tl,trainV.Ai,Q,TS);

%% Training Record
tr.best_epoch = 0;
tr.goal = goal;
tr.states = {'epoch','time','perf','vperf','tperf'};

%% Status
status = ...
  [ ...
  training_status('Epoch','iterations','linear','discrete',0,epochs,0), ...
  training_status('Time','seconds','linear','discrete',0,time,0), ...
  training_status('Performance','','log','continuous',perf,goal,perf) ...
  ];
nn_train_feedback('start',net,status);

% Train
for epoch=0:epochs
  
  % Stopping Criteria
  current_time = etime(clock,startTime);
  [userStop,userCancel] = nntraintool('check');
  if userStop, tr.stop = 'User stop.';
  elseif userCancel, tr.stop = 'User cancel.'; net = original_net;
  elseif (perf <= goal), tr.stop = 'Performance goal met.';
  elseif (epoch == epochs), tr.stop = 'Maximum epoch reached.';
  elseif (current_time >= time), tr.stop = 'Maximum time elapsed.';
  end

  % Training record
  if doValidation
    [vperf,ignore,valV.Y] = calcperf2(net,X,valV.Pd,valV.Tl,valV.Ai,valV.Q,valV.TS);
  end
  if doTest
    [tperf,ignore,testV.Y] = calcperf2(net,X,testV.Pd,testV.Tl,testV.Ai,testV.Q,testV.TS);
  end
  tr = tr_update(tr,[epoch current_time perf vperf tperf]);

  % Feedback
  nn_train_feedback('update',net,status,tr,{trainV}, ...
    [epoch,current_time,perf]);
  
  % Stop
  if ~isempty(tr.stop), break, end

  % Each vector (or sequence of vectors) in order
  for q=1:Q

    % Select vectors
    Pd = Pd_div{q};
    Tl = Tl_div{q};
    Ai = Ai_div{q};

    % Performance
    [Ac,N,Zl,Zi,Zb] = calca(net,Pd,Ai,1,TS);
    Elq = calce(net,Ac,Tl,TS);
    X = getx(net);
    E = Elq(net.outputConnect,:);
    A = Ac(net.outputConnect,(net.numLayerDelays+1):end);
    Y = processoutputs(net,A);
    perfq = feval(performFcn,E,Y,X,net.performParam);
 
    % Gradient
    if (needGradient)
      gE = cell(net.numLayers,TS);
      gE(net.outputConnect,:) = feval(performFcn,'dy',E,Y,X,perfq,net.performParam);
      [gB,gIW,gLW,gA] = calcgrad(net,1,Pd,Zb,Zi,Zl,N,Ac,gE,TS);
    end
  
    % Update with Weight and Bias Learning Functions
    for ts=1:TS
      for i=1:numLayers

        % Update Input Weight Values
        for j=find(net.inputConnect(i,:))
          learnFcn = net.inputWeights{i,j}.learnFcn;
          if ~isempty(learnFcn)
            [dw,IWLS{i,j}] = feval(learnFcn,net.IW{i,j}, ...
              Pd{i,j,ts},Zi{i,j},N{i},Ac{i,ts+numLayerDelays},Tl{i,ts},Elq{i,ts},gIW{i,j,ts},...
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
              Ad,Zl{i,j},N{i},Ac{i,ts+numLayerDelays},Tl{i,ts},Elq{i,ts},gLW{i,j,ts},...
              gA{i,ts},net.layers{i}.distances,net.layerWeights{i,j}.learnParam,LWLS{i,j});
            net.LW{i,j} = net.LW{i,j} + dw;
          end
        end

        % Update Bias Values
        if net.biasConnect(i)
          learnFcn = net.biases{i}.learnFcn;
          if ~isempty(learnFcn)
           [db,BLS{i}] = feval(learnFcn,net.b{i}, ...
              BP,Zb{i},N{i},Ac{i,ts+numLayerDelays},Tl{i,ts},Elq{i,ts},gB{i,ts},...
              gA{i,ts},net.layers{i}.distances,net.biases{i}.learnParam,BLS{i});
            net.b{i} = net.b{i} + db;
          end
        end
      end
    end
  end
  
  X = getx(net);
  [perf,El,trainV.Y] = calcperf2(net,X,trainV.Pd,trainV.Tl,trainV.Ai,Q,TS);
end

%% Finish
tr = tr_clip(tr);

%===============================================================
function b_div = batchdiv(b,Q)

[rows,cols] = size(b);
b_div = cell(1,Q);
for q=1:Q
  b_div{q} = cell(rows,cols);
end

for i=1:rows
  for j=1:cols
  if ~isempty(b{i,j})
    for q=1:Q
      b_div{q}{i,j} = b{i,j}(:,q);
    end
  end
  end
end

%===============================================================
function b = batchinsert(b,bq,q)

[rows,cols] = size(bq);

for i=1:rows
  for j=1:cols
    if ~isempty(b{i,j})
      b{i,j}(:,q) = bq{i,j};
    end
  end
end

%===============================================================

