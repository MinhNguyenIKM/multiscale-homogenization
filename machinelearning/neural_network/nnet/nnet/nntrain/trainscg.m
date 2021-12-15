function [net,tr] = trainscg(net,tr,trainV,valV,testV)
%TRAINSCG Scaled conjugate gradient backpropagation.
%
%  Syntax
%  
%    [net,tr,Ac,El] = trainscg(net,tr,trainV,valV,testV)
%    info = trainscg('info')
%
%  Description
%
%    TRAINSCG is a network training function that updates weight and
%    bias values according to the scaled conjugate gradient method.
%
%    TRAINSCG(NET,TR,TRAINV,VALV,TESTV) takes these inputs,
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
%      net.trainParam.show             25  Epochs between displays
%      net.trainParam.showCommandLine   0 generate command line output
%      net.trainParam.showWindow        1 show training GUI
%      net.trainParam.epochs          100  Maximum number of epochs to train
%      net.trainParam.goal              0  Performance goal
%      net.trainParam.time            inf  Maximum time to train in seconds
%      net.trainParam.min_grad       1e-6  Minimum performance gradient
%      net.trainParam.max_fail          5  Maximum validation failures
%      net.trainParam.sigma        5.0e-5  Determines change in weight for second derivative approximation.
%      net.trainParam.lambda       5.0e-7  Parameter for regulating the indefiniteness of the Hessian.
%
%    TRAINSCG('info') returns useful information about this function.
%
%  Network Use
%
%    You can create a standard network that uses TRAINSCG with
%    NEWFF, NEWCF, or NEWELM.
%
%    To prepare a custom network to be trained with TRAINSCG:
%    1) Set NET.trainFcn to 'trainscg'.
%       This will set NET.trainParam to TRAINSCG's default parameters.
%    2) Set NET.trainParam properties to desired values.
%
%    In either case, calling TRAIN with the resulting network will
%    train the network with TRAINSCG.
%
%
%  Examples
%
%    Here is a problem consisting of inputs P and targets T that we would
%    like to solve with a network.
%
%      p = [0 1 2 3 4 5];
%      t = [0 0 0 1 1 1];
%
%    Here a two-layer feed-forward network is created.  The network's
%    input ranges from [0 to 10].  The first layer has two TANSIG
%    neurons, and the second layer has one LOGSIG neuron.  The TRAINSCG
%     network training function is to be used.
%
%      % Create and Test a Network
%      net = newff([0 5],[2 1],{'tansig','logsig'},'trainscg');
%      a = sim(net,p)
%
%      % Train and Retest the Network
%      net.trainParam.epochs = 50;
%      net.trainParam.show = 10;
%      net.trainParam.goal = 0.1;
%      net = train(net,p,t);
%      a = sim(net,p)
%
%    See NEWFF, NEWCF, and NEWELM for other examples.
%
%  Algorithm
%
%    TRAINSCG can train any network as long as its weight, net input,
%    and transfer functions have derivative functions.
%     Backpropagation is used to calculate derivatives of performance
%    PERF with respect to the weight and bias variables X.
%
%    The scaled conjugate gradient algorithm is based on conjugate 
%     directions, as in TRAINCGP, TRAINCGF and TRAINCGB, but this 
%     algorithm does not perform a line search at each iteration.
%    See Moller (Neural Networks, vol. 6, 1993, pp. 525-533) for a more
%     detailed discussion of the scaled conjugate gradient algorithm.
%
%    Training stops when any of these conditions occur:
%    1) The maximum number of EPOCHS (repetitions) is reached.
%    2) The maximum amount of TIME has been exceeded.
%    3) Performance has been minimized to the GOAL.
%    4) The performance gradient falls below MINGRAD.
%    5) Validation performance has increased more than MAX_FAIL times
%       since the last time it decreased (when using validation).
%
%  See also NEWFF, NEWCF, TRAINGDM, TRAINGDA, TRAINGDX, TRAINLM,
%           TRAINRP, TRAINCGF, TRAINCGB, TRAINBFG, TRAINCGP,
%           TRAINOSS.
%
%   References
%
%     Moller, Neural Networks, vol. 6, 1993, pp. 525-533.

% Updated by Orlando De Jesús, Martin Hagan, Dynamic Training 7-20-05
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.9 $ $Date: 2008/03/13 17:33:38 $

% FUNCTION INFO
% =============

%% Info
if strcmp(net,'info')
  info.function = mfilename;
  info.title = 'Scaled Conjugate Gradient';
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
  info.param_defaults.min_grad = 1e-6;
  info.param_defaults.sigma = 5.0e-5;
  info.param_defaults.lambda = 5.0e-7;
  info.training_states = ...
    [ ...
    training_state_info('gradient','Gradient','continuous','log') ...
    training_state_info('val_fail','Validation Checks','discrete','linear') ...
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

% USEFUL VALUES
tp = net.trainParam;
epochs = tp.epochs;
show = tp.show;
goal = tp.goal;
min_grad = tp.min_grad;
max_fail = tp.max_fail;
sigma = tp.sigma;
lambda = tp.lambda;
gradientFcn = net.gradientFcn;
show = tp.show;
max_time = tp.time;

% Parameter Checking
if (~isa(epochs,'double')) || (~isreal(epochs)) || (any(size(epochs)) ~= 1) || ...
  (epochs < 1) || (round(epochs) ~= epochs)
  error('NNET:Arguments','Epochs is not a positive integer.')
end
if (~isa(show,'double') && ~isa(show,'logical')) || (~isreal(show)) || (any(size(show)) ~= 1)
  error('NNET:Arguments','Show is not a logical.')
end
if (~isa(goal,'double')) || (~isreal(goal)) || (any(size(goal)) ~= 1) || ...
  (goal < 0)
  error('NNET:Arguments','Goal is not zero or a positive real value.')
end
if (~isa(max_time,'double')) || (~isreal(max_time)) || (any(size(max_time)) ~= 1) || ...
  (max_time < 0)
  error('NNET:Arguments','Time is not zero or a positive real value.')
end
if (~isa(min_grad,'double')) || (~isreal(min_grad)) || (any(size(min_grad)) ~= 1) || ...
  (min_grad < 0)
  error('NNET:Arguments','Min_grad is not zero or a positive real value.')
end
if (~isa(max_fail,'double')) || (~isreal(max_fail)) || (any(size(max_fail)) ~= 1) || ...
  (max_fail < 1) || (round(max_fail) ~= max_fail)
  error('NNET:Arguments','Max_fail is not a positive integer.')
end
if (~isa(sigma,'double')) || (~isreal(sigma)) || (any(size(sigma)) ~= 1) || ...
  (sigma <= 0)
  error('NNET:Arguments','Sigma is not a positive real value.')
end
if (~isa(lambda,'double')) || (~isreal(lambda)) || (any(size(lambda)) ~= 1) || ...
  (lambda <= 0)
  error('NNET:Arguments','Lambda is not a positive real value.')
end

% Initialize
Q = trainV.Q;
TS = trainV.TS;
vperf = NaN;
tperf = NaN;
val_fail = 0;
startTime = clock;
X = getx(net);
lengthX = length(X);

% Initial Performance
original_net = net;
best_net = net;
doValidation = ~isempty(valV.indices);
doTest = ~isempty(testV.indices);
[perf,El,trainV.Y,Ac,N,Zb,Zi,Zl] = calcperf2(net,X,trainV.Pd,trainV.Tl,trainV.Ai,trainV.Q,trainV.TS);
best_perf = perf;
if (doValidation)
  [vperf,ignore,valV.Y] = calcperf2(net,X,valV.Pd,valV.Tl,valV.Ai,valV.Q,valV.TS);
  best_vperf = vperf;
end

% Initial gradient
gX = -calcgx(net,X,trainV.Pd,Zb,Zi,Zl,N,Ac,El,perf,Q,TS);
gradient = sqrt(gX'*gX);
gX_old = gX;

% Initial search direction and norm
dX = -gX;
nrmsqr_dX = dX'*dX;
norm_dX = sqrt(nrmsqr_dX);

% Initial training parameters and flag
success = 1;
lambdab = 0;
lambdak = lambda;
    
% Training Record
tr.best_epoch = 0;
tr.goal = goal;
tr.states = {'epoch','time','perf','vperf','tperf','gradient','val_fail'};

%% Status
status = ...
  [ ...
  training_status('Epoch','iterations','linear','discrete',0,epochs,0), ...
  training_status('Time','seconds','linear','discrete',0,max_time,0), ...
  training_status('Performance','','log','continuous',best_perf,goal,best_perf) ...
  training_status('Gradient','','log','continuous',1,min_grad,1) ...
  training_status('Validation Checks','','linear','discrete',0,max_fail,0) ...
  ];
nn_train_feedback('start',net,status);

% Train
for epoch=0:epochs

  [perf,El,trainV.Y,Ac,N,Zb,Zi,Zl] = calcperf2(net,X,trainV.Pd,trainV.Tl,trainV.Ai,trainV.Q,trainV.TS);

  % Stopping Criteria
  current_time = etime(clock,startTime);
  [userStop,userCancel] = nntraintool('check');
  if userStop, tr.stop = 'User stop.'; net = best_net;
  elseif userCancel, tr.stop = 'User cancel.'; net = original_net;
  elseif (perf <= goal), tr.stop = 'Performance goal met.'; net = best_net;
  elseif (epoch == epochs), tr.stop = 'Maximum epoch reached.'; net = best_net;
  elseif (current_time >= max_time), tr.stop = 'Maximum time elapsed.'; net = best_net;
  elseif (gradient <= min_grad), tr.stop = 'Minimum gradient reached.'; net = best_net;
  elseif (doValidation) && (val_fail >= max_fail), tr.stop = 'Validation stop.'; net = best_net;
  end
  
  % Training record
  if doTest, [tperf,tEl,testV.Y] = calcperf2(net,X,testV.Pd,testV.Tl,testV.Ai,testV.Q,testV.TS); end
  tr = tr_update(tr,[epoch current_time perf vperf tperf gradient val_fail]);
 
  % Feedback
  nn_train_feedback('update',net,status,tr,{trainV valV testV}, ...
    [epoch,current_time,best_perf,gradient,val_fail]);
  
  % Stop
  if ~isempty(tr.stop), break, end

  % If success is true, calculate second order information
  if (success == 1)
    sigmak = sigma/norm_dX;
    X_temp = X + sigmak*dX;
    net_temp = setx(net,X_temp);
    [perf_temp,El,Y,Ac,N,Zb,Zi,Zl] = ...
      calcperf2(net_temp,X_temp,trainV.Pd,trainV.Tl,trainV.Ai,trainV.Q,trainV.TS);
    gX_temp = -calcgx(net_temp,X_temp,trainV.Pd,Zb,Zi,Zl,N,Ac,El,perf_temp,Q,TS);
    sk = (gX_temp - gX)/sigmak;
    deltak = dX'*sk;
  end

  % Scale deltak
  deltak = deltak + (lambdak - lambdab)*nrmsqr_dX;

  % IF deltak <= 0 then make the Hessian matrix positive definite
  if (deltak <= 0)
    lambdab = 2*(lambdak - deltak/nrmsqr_dX);
    deltak = -deltak + lambdak*nrmsqr_dX;
    lambdak = lambdab;
  end

  % Calculate step size
  muk = -dX'*gX;
  alphak = muk/deltak;

  % Calculate the comparison parameter
  X_temp = X + alphak*dX;
  net_temp = setx(net,X_temp);
  [perf_temp,El,Y,Ac,N,Zb,Zi,Zl] = ...
    calcperf2(net_temp,X_temp,trainV.Pd,trainV.Tl,trainV.Ai,trainV.Q,trainV.TS);
  difk = 2*deltak*(perf - perf_temp)/(muk^2);

  % If difk >= 0 then a successful reduction in error can be made
  if (difk >= 0)
    gX_old = gX;
    X = X_temp;
    net = net_temp;
    gX = -calcgx(net,X,trainV.Pd,Zb,Zi,Zl,N,Ac,El,perf_temp,Q,TS);
    gradient = sqrt(gX'*gX);
    lambdab = 0;
    success = 1;
    perf = perf_temp;
    TrainV.Y = Y;

    % Restart the algorithm every lengthX iterations
    if rem(epoch,lengthX)==0
      dX = -gX;
    else
      betak = (gX'*gX - gX'*gX_old)/muk;
      dX = -gX + betak*dX;
    end

    nrmsqr_dX = dX'*dX;
    norm_dX = sqrt(nrmsqr_dX);

    % If difk >= 0.75, then reduce the scale parameter
    if (difk >= 0.75)
      lambdak = 0.25*lambdak;
    end

  else

    lambdab = lambdak;
    success = 0;

  end

  % If difk < 0.25, then increase the scale parameter
  if (difk < 0.25) && nrmsqr_dX~=0, 
      lambdak = lambdak + deltak*(1 - difk)/nrmsqr_dX;
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
  else
    if (perf < best_perf)
      best_net = net;
      best_perf = perf;
      tr.best_epoch = epoch+1;
    end
  end
end

%% Finish
tr = tr_clip(tr);
