function [net,tr] = trainoss(net,tr,trainV,valV,testV,varargin)
%TRAINOSS One step secant backpropagation.
%
%  Syntax
%  
%    [net,tr,Ac,El] = trainoss(net,tr,trainV,valV,testV)
%    info = trainoss('info')
%
%  Description
%
%    TRAINOSS is a network training function that updates weight and
%    bias values according to the one step secant method.
%
%    TRAINOSS(NET,TR,TRAINV,VALV,TESTV) takes these inputs,
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
%      net.trainParam.searchFcn 'srchcha'  Name of line search routine to use.
%
%    Parameters related to line search methods (not all used for all methods):
%      net.trainParam.scale_tol         20  Divide into delta to determine tolerance for linear search.
%      net.trainParam.alpha         0.001  Scale factor which determines sufficient reduction in perf.
%      net.trainParam.beta            0.1  Scale factor which determines sufficiently large step size.
%      net.trainParam.delta          0.01  Initial step size in interval location step.
%      net.trainParam.gama            0.1  Parameter to avoid small reductions in performance. Usually set
%                                           to 0.1. (See use in SRCH_CHA.)
%      net.trainParam.low_lim         0.1  Lower limit on change in step size.
%      net.trainParam.up_lim          0.5  Upper limit on change in step size.
%      net.trainParam.maxstep         100  Maximum step length.
%      net.trainParam.minstep      1.0e-6  Minimum step length.
%      net.trainParam.bmax             26  Maximum step size.
%
%    TRAINOSS('info') returns useful information about this function.
%
%  Network Use
%
%    You can create a standard network that uses TRAINOSS with
%    NEWFF, NEWCF, or NEWELM.
%
%    To prepare a custom network to be trained with TRAINOSS:
%    1) Set NET.trainFcn to 'trainoss'.
%       This will set NET.trainParam to TRAINCGP's default parameters.
%    2) Set NET.trainParam properties to desired values.
%
%    In either case, calling TRAIN with the resulting network will
%    train the network with TRAINOSS.
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
%    neurons, and the second layer has one LOGSIG neuron.  The TRAINOSS
%     network training function is to be used.
%
%      % Create and Test a Network
%      net = newff([0 5],[2 1],{'tansig','logsig'},'trainoss');
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
%    TRAINOSS can train any network as long as its weight, net input,
%    and transfer functions have derivative functions.
%
%     Backpropagation is used to calculate derivatives of performance
%    PERF with respect to the weight and bias variables X.  Each
%    variable is adjusted according to the following:
%
%       X = X + a*dX;
%
%     where dX is the search direction.  The parameter a is selected
%     to minimize the performance along the search direction.  The line
%     search function searchFcn is used to locate the minimum point.
%     The first search direction is the negative of the gradient of performance.
%     In succeeding iterations the search direction is computed from the new
%     gradient and the previous steps and gradients according to the following
%     formula:
%
%       dX = -gX + Ac*X_step + Bc*dgX;
%
%     where gX is the gradient, X_step is the change in the weights on the
%     previous iteration, and dgX is the change in the gradient from the
%     last iteration. 
%     See Battiti (Neural Computation, vol. 4, 1992, pp. 141-166) for
%     a more detailed discussion of the one step secant algorithm.
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
%           TRAINRP, TRAINCGF, TRAINCGB, TRAINSCG, TRAINCGP,
%           TRAINBFG.
%
%   References
%
%     Battiti, Neural Computation, vol. 4, 1992, pp. 141-166.

% Updated by Orlando De Jesús, Martin Hagan, Dynamic Training 7-20-05
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.10 $ $Date: 2008/10/31 06:23:33 $

% FUNCTION INFO
% =============

%% Info
if strcmp(net,'info')
  info.function = mfilename;
  info.title = 'One Step Secant';
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
  info.param_defaults.min_grad = 1e-10;
  info.param_defaults.searchFcn = 'srchbac';
  info.param_defaults.scale_tol = 20;
  info.param_defaults.alpha = 0.001;
  info.param_defaults.beta = 0.1;
  info.param_defaults.delta = 0.01;
  info.param_defaults.gama = 0.1;
  info.param_defaults.low_lim = 0.1;
  info.param_defaults.up_lim = 0.5;
  info.param_defaults.maxstep = 100;
  info.param_defaults.minstep = 1.0e-6;
  info.param_defaults.bmax = 26;
    
  info.training_states = ...
    [ ...
    training_state_info('gradient','Gradient','continuous','log') ...
    training_state_info('mu','Mu','continuous','log') ...
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
    case 'gdefaults', if (tr==0), 'calcgrad'; else net='calcgbtt'; end
    otherwise, error('NNET:Arguments','Unrecognized code.')
  end
  return
end

%% Parameters
epochs = net.trainParam.epochs;
show = net.trainParam.show;
goal = net.trainParam.goal;
time = net.trainParam.time;
min_grad = net.trainParam.min_grad;
max_fail = net.trainParam.max_fail;
scale_tol = net.trainParam.scale_tol;
delta = net.trainParam.delta;
searchFcn = net.trainParam.searchFcn;
gradientFcn = net.gradientFcn;
tol = delta/scale_tol;

% Parameter Checking
if (~isa(epochs,'double')) || (~isreal(epochs)) || (any(size(epochs)) ~= 1) || ...
  (epochs < 1) || (round(epochs) ~= epochs)
  error('NNET:Arguments','Epochs is not a positive integer.')
end
if (~isa(show,'double')) || (~isreal(show)) || (any(size(show)) ~= 1) || ...
  (isfinite(show) && ((show < 1) || (round(show) ~= show)))
  error('NNET:Arguments','Show is not ''NaN'' or a positive integer.')
end
if (~isa(goal,'double')) || (~isreal(goal)) || (any(size(goal)) ~= 1) || ...
  (goal < 0)
  error('NNET:Arguments','Goal is not zero or a positive real value.')
end
if (~isa(time,'double')) || (~isreal(time)) || (any(size(time)) ~= 1) || ...
  (time < 0)
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
if(ischar(searchFcn))
  exist_search = exist(searchFcn,'file');
  if (exist_search<2) || (exist_search>3)
    error('NNET:Arguments','SearchFcn is not a valid search function.')
  end
else
  error('NNET:Arguments','SearchFcn is not a character string')
end
if (~isa(scale_tol,'double')) || (~isreal(scale_tol)) || (any(size(scale_tol)) ~= 1) || ...
  (scale_tol <= 0)
  error('NNET:Arguments','Scale_tol is not a positive real value.')
end
if (~isa(delta,'double')) || (~isreal(delta)) || (any(size(delta)) ~= 1) || ...
  (delta <= 0)
  error('NNET:Arguments','Delta is not a positive real value.')
end

%% Initialize
Q = trainV.Q;
TS = trainV.TS;
vperf = NaN;
tperf = NaN;
val_fail = 0;
startTime = clock;
X = getx(net);
num_X = length(X);

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
tr.states = {'epoch','time','perf','vperf','tperf','gradient','val_fail'};

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

%% Train
for epoch=0:epochs

  % Performance, Gradient and Search Direction

  if (epoch == 0)

    % First iteration

    % Initial performance
    [perf,El,trainV.Y,Ac,N,Zb,Zi,Zl] = calcperf2(net,X,trainV.Pd,trainV.Tl,trainV.Ai,Q,TS);
    perf_old = perf;
    ch_perf = perf;
    sum1 = 0; sum2 = 0;

    % Initial gradient and norm of gradient
    gX = -calcgx(net,X,trainV.Pd,Zb,Zi,Zl,N,Ac,El,perf,Q,TS);
    gX_old = gX;
    gradient = sqrt(gX'*gX);

    % Initial search direction and initial slope
    dX = -gX;
    dperf = gX'*dX;

  else

    % After first iteration

    % Calculate change in gradient and save old gradient
    dgX = gX - gX_old;
    gX_old = gX;
    gradient = sqrt(gX'*gX);

    % Calculate change in performance and save old performance
    ch_perf = perf - perf_old;
    perf_old = perf;
  
    % Calculate search direction modification parameters
    den = X_step'*dgX;
    num = X_step'*gX;

    % Calculate new search direction
    if rem(epoch,num_X)==0  || den==0,
      dX = -gX;
    else
      Bc = num/den;
      Ac = -(1 + dgX'*dgX/den)*Bc + dgX'*gX/den;
      dX = -gX + Ac*X_step + Bc*dgX;
    end

    % Check for a descent direction
    dperf = gX'*dX;
    if dperf>0
      dX = -gX;
      dperf = gX'*dX;
    end

    % Update norm of step
    norm_dX = sqrt(dX'*dX);

  end

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
  tr = tr_update(tr,[epoch current_time perf vperf tperf gradient val_fail]);
  
  % Feedback
  nn_train_feedback('update',net,status,tr,{trainV valV testV}, ...
    [epoch,current_time,best_perf,gradient,val_fail]);
  
  % Stop
  if ~isempty(tr.stop), break, end

  % Minimize the performance along the search direction
  [a,gX,perf,retcode,delta,tol] = feval(searchFcn,net,X,trainV.Pd,trainV.Tl,trainV.Ai,Q,TS, ...
    dX,gX,perf,dperf,delta,tol,ch_perf);

  % Keep track of the number of function evaluations
  sum1 = sum1 + retcode(1);
  sum2 = sum2 + retcode(2);
  
  % Update X
  X_step = a*dX;
  X = X + X_step;
  net = setx(net,X);
 
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
