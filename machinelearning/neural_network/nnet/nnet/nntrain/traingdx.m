function [net,tr] = traingdx(net,tr,trainV,valV,testV,varargin)
%TRAINGDX Gradient descent w/momentum & adaptive lr backpropagation.
%
%  Syntax
%  
%    [net,tr] = traingdx(net,tr,trainV,valV,testV)
%    info = traingdx('info')
%
%  Description
%
%    TRAINGDX is a network training function that updates weight and
%    bias values according to gradient descent momentum and an
%    adaptive learning rate.
%
%    TRAINGDX(NET,TR,TRAINV,VALV,TESTV) takes these inputs,
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
%      net.trainParam.show           25  Epochs between displays
%      net.trainParam.showCommandLine 0 generate command line output
%      net.trainParam.showWindow      1 show training GUI
%      net.trainParam.epochs         10  Maximum number of epochs to train
%      net.trainParam.goal            0  Performance goal
%      net.trainParam.lr           0.01  Learning rate
%      net.trainParam.lr_inc       1.05  Ratio to increase learning rate
%      net.trainParam.lr_dec        0.7  Ratio to decrease learning rate
%      net.trainParam.max_fail        5  Maximum validation failures
%      net.trainParam.max_perf_inc 1.04  Maximum performance increase
%      net.trainParam.mc            0.9  Momentum constant.
%      net.trainParam.min_grad    1e-10  Minimum performance gradient
%      net.trainParam.time          inf  Maximum time to train in seconds
%
%    TRAINGDX('info') returns useful information about this function.
%
%  Network Use
%
%    You can create a standard network that uses TRAINGDX with
%    NEWFF, NEWCF, or NEWELM.
%
%    To prepare a custom network to be trained with TRAINGDX:
%    1) Set NET.trainFcn to 'traingdx'.
%       This will set NET.trainParam to TRAINGDX's default parameters.
%    2) Set NET.trainParam properties to desired values.
%
%    In either case, calling TRAIN with the resulting network will
%    train the network with TRAINGDX.
%
%    See NEWFF, NEWCF, and NEWELM for examples.
%
%  Algorithm
%
%    TRAINGDX can train any network as long as its weight, net input,
%    and transfer functions have derivative functions.
%
%    Backpropagation is used to calculate derivatives of performance
%    PERF with respect to the weight and bias variables X.  Each
%    variable is adjusted according to the gradient descent
%    with momentum.
%
%      dX = mc*dXprev + lr*mc*dperf/dX
%
%    where dXprev is the previous change to the weight or bias.
%
%    For each epoch, if performance decreases toward the goal, then
%    the learning rate is increased by the factor lr_inc.  If
%    performance increases by more than the factor max_perf_inc,
%    the learning rate is adjusted by the factor lr_dec and the
%    change, which increased the performance, is not made.
%
%    Training stops when any of these conditions occur:
%    1) The maximum number of EPOCHS (repetitions) is reached.
%    2) The maximum amount of TIME has been exceeded.
%    3) Performance has been minimized to the GOAL.
%    4) The performance gradient falls below MINGRAD.
%    5) Validation performance has increase more than MAX_FAIL times
%       since the last time it decreased (when using validation).
%
%  See also NEWFF, NEWCF, TRAINGD, TRAINGDM, TRAINGDA, TRAINLM.

% Updated by Orlando De Jesús, Martin Hagan, 7-20-05
% Mark Beale, 11-31-97
% ODJ, 11/20/98, added support for user stopping.
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.9 $ $Date: 2008/04/06 19:17:04 $

%% Info
if strcmp(net,'info')
  info.function = mfilename;
  info.title = 'Gradient Descent Backpropagation with Adaptive Learning Rate.';
  info.type = 'Training';
  info.version = 6;
  info.training_mode = 'Supervised';
  info.gradient_mode = 'Gradient';
  info.uses_validation = true;
  info.param_defaults.show = 25;
  info.param_defaults.showWindow = true;
  info.param_defaults.showCommandLine = false;
  info.param_defaults.epochs = 1000;
  info.param_defaults.time = inf;
  info.param_defaults.goal = 0;
  
  info.param_defaults.max_fail = 6;
  info.param_defaults.lr = 0.01;
  info.param_defaults.lr_inc = 1.05;
  info.param_defaults.lr_dec = 0.7;
  info.param_defaults.max_perf_inc = 1.04;
  info.param_defaults.mc = 0.9;
  info.param_defaults.min_grad = 1e-10;
    
  info.training_states = ...
    [ ...
    training_state_info('gradient','Gradient','continuous','log') ...
    training_state_info('val_fail','Validation Checks','discrete','linear') ...
    training_state_info('lr','Learning Rate','continuous','linear') ...
    ];
  net = info;
  return
end

%% NNET 5.1 Backward Compatibility
if ischar(net)
  switch (net)
    case 'name', info = feval(mfilename,'info'); net = info.title;
    case 'pnames', info = feval(mfilename,'info'); net = fieldnames(info.param_defaults);
    case 'pdefaults', info = feval(mfilename,'info'); net = info.param_defaults;
    case 'gdefaults', if (tr==0), net='calcgrad'; else net='calcgbtt'; end
    otherwise, error('NNET:Arguments','Unrecognized code.')
  end
  return
end

% CALCULATION
% ===========

% Parameters
epochs = net.trainParam.epochs;
goal = net.trainParam.goal;
lr = net.trainParam.lr;
lr_inc = net.trainParam.lr_inc;
lr_dec = net.trainParam.lr_dec;
max_fail = net.trainParam.max_fail;
max_perf_inc = net.trainParam.max_perf_inc;
mc = net.trainParam.mc;
min_grad = net.trainParam.min_grad;
show = net.trainParam.show;
time = net.trainParam.time;
% We get gradient function
gradientFcn = net.gradientFcn;

% Parameter Checking
if (~isa(epochs,'double')) || (~isreal(epochs)) || (any(size(epochs)) ~= 1) || ...
  (epochs < 1) || (round(epochs) ~= epochs)
  error('NNET:Arguments','Epochs is not a positive integer.')
end
if (~isa(goal,'double')) || (~isreal(goal)) || (any(size(goal)) ~= 1) || ...
  (goal < 0)
  error('NNET:Arguments','Goal is not zero or a positive real value.')
end
if (~isa(lr,'double')) || (~isreal(lr)) || (any(size(lr)) ~= 1) || ...
  (lr < 0)
  error('NNET:Arguments','Learning rate is not zero or a positive real value.')
end
if (~isa(lr_inc,'double')) || (~isreal(lr_inc)) || (any(size(lr_inc)) ~= 1) || ...
  (lr_inc < 1)
  error('NNET:Arguments','LR_inc is not a positive real value greater or equal to 1.0.')
end
if (~isa(lr_dec,'double')) || (~isreal(lr_dec)) || (any(size(lr_dec)) ~= 1) || ...
  (lr_dec < 0) || (lr_dec > 1)
  error('NNET:Arguments','LR_dec is not a positive real value greater or between 0.0 and 1.0.')
end
if (~isa(max_fail,'double')) || (~isreal(max_fail)) || (any(size(max_fail)) ~= 1) || ...
  (max_fail < 1) || (round(max_fail) ~= max_fail)
  error('NNET:Arguments','Max_fail is not a positive integer.')
end
if (~isa(max_perf_inc,'double')) || (~isreal(max_perf_inc)) || (any(size(max_perf_inc)) ~= 1) || ...
  (max_perf_inc < 1)
  error('NNET:Arguments','Max_perf_inc is not a positive real value greater or equal to 1.0.')
end
if (~isa(mc,'double')) || (~isreal(mc)) || (any(size(mc)) ~= 1) || ...
  (mc < 0) || (mc > 1)
  error('NNET:Arguments','MC is not real value between 0.0 and 1.0.')
end
if (~isa(min_grad,'double')) || (~isreal(min_grad)) || (any(size(min_grad)) ~= 1) || ...
  (min_grad < 0)
  error('NNET:Arguments','Min_grad is not zero or a positive real value.')
end
if (~isa(show,'double')) || (~isreal(show)) || (any(size(show)) ~= 1) || ...
  (isfinite(show) && ((show < 1) || (round(show) ~= show)))
  error('NNET:Arguments','Show is not ''NaN'' or a positive integer.')
end
if (~isa(time,'double')) || (~isreal(time)) || (any(size(time)) ~= 1) || ...
  (time < 0)
  error('NNET:Arguments','Time is not zero or a positive real value.')
end

% Initialize
Q = trainV.Q;
TS = trainV.TS;
val_fail = 0;
startTime = clock;
X = getx(net);

% Initialize Performance
vperf = NaN;
tperf = NaN;
original_net = net;
best_net = net;
doValidation = ~isempty(valV.indices);
doTest = ~isempty(testV.indices);
[perf,El,trainV.Y,Ac,N,Zb,Zi,Zl] = calcperf2(net,X,trainV.Pd,trainV.Tl,trainV.Ai,Q,TS);
[gX,gradient] = calcgx(net,X,trainV.Pd,Zb,Zi,Zl,N,Ac,El,perf,Q,TS);
best_perf = perf;
if (doValidation)
  [vperf,ignore,valV.Y] = calcperf2(net,X,valV.Pd,valV.Tl,valV.Ai,valV.Q,valV.TS);
  best_vperf = vperf;
end

%% Training Record
tr.best_epoch = 0;
tr.goal = goal;
tr.states = {'epoch','time','perf','vperf','tperf','gradient','val_fail','lr'};

%% Status
status = ...
  [ ...
  training_status('Epoch','iterations','linear','discrete',0,epochs,0), ...
  training_status('Time','seconds','linear','discrete',0,time,0), ...
  training_status('Performance','','log','continuous',best_perf,goal,best_perf) ...
  training_status('Gradient','','log','continuous',1,min_grad,1) ...
  training_status('Validation Checks','','linear','discrete',0,max_fail,0) ...
  ];
nn_train_feedback('start',net,status);

% Train
dX = lr*gX;
for epoch=0:epochs
  
  % Stopping Criteria
  current_time = etime(clock,startTime);
  [userStop,userCancel] = nntraintool('check');
  if userStop, tr.stop = 'User stop.'; net = best_net;
  elseif userCancel, tr.stop = 'User cancel.'; net = original_net;
  elseif (perf <= goal), tr.stop = 'Performance goal met.'; net = best_net;
  elseif (epoch == epochs), tr.stop = 'Maximum epoch reached.'; net = best_net;
  elseif (current_time >= time), tr.stop = 'Maximum time elapsed.'; net = best_net;
  elseif (gradient <= min_grad), tr.stop = 'Minimum gradient reached.'; net = best_net;
  elseif (doValidation) && (val_fail >= max_fail), tr.stop = 'Validation stop.'; net = best_net;
  end

  % Training record
  if doTest
    [tperf,ignore,testV.Y] = calcperf2(net,X,testV.Pd,testV.Tl,testV.Ai,testV.Q,testV.TS);
  end
  tr = tr_update(tr,[epoch current_time perf vperf tperf gradient val_fail lr]);
  
  % Feedback
  nn_train_feedback('update',net,status,tr,{trainV valV testV}, ...
    [epoch,current_time,best_perf,gradient,val_fail lr]);
  
  % Stop
  if ~isempty(tr.stop), break, end
  
  % Gradient Descent with Momentum and Adaptive Learning Rate
  dX = mc*dX + (1-mc)*lr*gX;
  X2 = X + dX;
  net2 = setx(net,X2);
  [perf2,El,Y2,Ac,N,Zb,Zi,Zl] = calcperf2(net2,X,trainV.Pd,trainV.Tl,trainV.Ai,Q,TS);
  if (perf2/perf) > max_perf_inc
    lr = lr*lr_dec;
    dX = lr*gX;
  else
    if (perf2 < perf), lr = lr*lr_inc; end
    X = X2;
    net = net2;
    perf = perf2;
    trainV.Y = Y2;
    [gX,gradient] = calcgx(net,X,trainV.Pd,Zb,Zi,Zl,N,Ac,El,perf,Q,TS);
  end
  
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

% Finish
tr = tr_clip(tr);
