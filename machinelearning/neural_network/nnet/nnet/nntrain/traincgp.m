function [net,tr] = traincgp(net,tr,trainV,valV,testV,varargin)
%TRAINCGP Conjugate gradient backpropagation with Polak-Ribiere updates.
%
%  Syntax
%  
%    [net,tr] = traincgp(net,tr,trainV,valV,testV)
%    info = traincgp('info')
%
%  Description
%
%    TRAINCGP is a network training function that updates weight and
%    bias values according to the conjugate gradient backpropagation
%     with Polak-Ribiere updates.
%
%    TRAINCGP(NET,TR,TRAINV,VALV,TESTV) takes these inputs,
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
%   Parameters related to line search methods (not all used for all methods):
%      net.trainParam.scal_tol         20  Divide into delta to determine tolerance for linear search.
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
%    TRAINCGP('info') returns useful information about this function.
%
%  Network Use
%
%    You can create a standard network that uses TRAINCGP with
%    NEWFF, NEWCF, or NEWELM.
%
%    To prepare a custom network to be trained with TRAINCGP:
%    1) Set NET.trainFcn to 'traincgp'.
%       This will set NET.trainParam to TRAINCGP's default parameters.
%    2) Set NET.trainParam properties to desired values.
%
%    In either case, calling TRAIN with the resulting network will
%    train the network with TRAINCGP.
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
%    A feedforward network is created with a hidden layer of 2 neurons.
%
%      net = newff([0 5],[2 1],{'tansig','logsig'},'traincgp');
%      a = sim(net,p)
%
%    Here the network is trained and tested.
%
%      net = train(net,p,t);
%      a = sim(net,p)
%
%  Algorithm
%
%    TRAINCGP can train any network as long as its weight, net input,
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
%     gradient and the previous search direction according to the
%     formula:
%
%       dX = -gX + dX_old*Z;
%
%     where gX is the gradient. The parameter Z can be computed in several 
%     different ways.  For the Polak-Ribiere variation of conjugate gradient
%     it is computed according to:
%
%      Z = ((gX - gX_old)'*gX)/norm_sqr;
%
%     where norm_sqr is the norm square of the previous gradient and
%     gX_old is the gradient on the previous iteration.
%    See page 78 of Scales (Introduction to Non-Linear Optimization 1985) for
%     a more detailed discussion of the algorithm.
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
%           TRAINRP, TRAINCGF, TRAINCGB, TRAINSCG, TRAINOSS,
%           TRAINBFG.
%
%   References
%
%     Scales, Introduction to Non-Linear Optimization, 1985.

% Updated by Orlando De Jesús, Martin Hagan, 7-20-05
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.11 $ $Date: 2008/10/31 06:23:32 $

% FUNCTION INFO
% =============

%% Info
if strcmp(net,'info')
  info.function = mfilename;
  info.title = 'Conjugate Gradient with Polak-Ribiere Restarts';
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
  info.param_defaults.searchFcn = 'srchcha';
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
    training_state_info('a','Step Size','continuous','log') ...
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
tp = net.trainParam;
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
a=1;

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
tr.states = {'epoch','time','perf','vperf','tperf','gradient','val_fail','a'};

%% Status
status = ...
  [ ...
  training_status('Epoch','iterations','linear','discrete',0,epochs,0), ...
  training_status('Time','seconds','linear','discrete',0,time,0), ...
  training_status('Performance','','log','continuous',best_perf,goal,best_perf) ...
  training_status('Gradient','','log','continuous',1,min_grad,1) ...
  training_status('Validation Checks','','linear','discrete',0,max_fail,0) ...
  training_status('Step Size','','log','continuous',tp.maxstep,tp.minstep,a) ...
  ];
nn_train_feedback('start',net,status);

%% Train
for epoch=0:epochs

  if (epoch == 0)
    % First Iteration
  
    % Initial performance
    [perf,El,trainV.Y,Ac,N,Zb,Zi,Zl] = calcperf2(net,X,trainV.Pd,trainV.Tl,trainV.Ai,Q,TS);
    perf_old = perf;
    ch_perf = perf;
    sum1 = 0; sum2 = 0;

    % Initial gradient and norm of gradient
    gX = -calcgx(net,X,trainV.Pd,Zb,Zi,Zl,N,Ac,El,perf,Q,TS);
    norm_sqr = gX'*gX;
    gradient = sqrt(norm_sqr);
    dX_old = -gX;
    gX_old = gX;

    % Initial search direction and initial slope
    if gradient==0,
      dX = -gX;
    else 
      dX = -gX/gradient;
    end
    dperf = gX'*dX;

  else

    % After first iteration

    % Calculate change in performance and norm of gradient
    normnew_sqr = gX'*gX;
    gradient = sqrt(normnew_sqr);
    ch_perf = perf - perf_old;

    % Calculate search direction modification parameter
    if rem(epoch,num_X)==0 || norm_sqr==0,
      Z=0;
    else
      Z = ((gX - gX_old)'*gX)/norm_sqr;
    end

    % Calculate new search direction
    dX = -gX + dX_old*Z;

    % Save new directions and norm of gradient
    gX_old = gX;
    dX_old = dX;
    norm_sqr = normnew_sqr;
    perf_old = perf;
  
    % Normalize search direction
    norm_dX = norm(dX);
    if norm_dX~=0, dX = dX/norm_dX; end;
  
    % Check for a descent direction
    dperf = gX'*dX;
    if (dperf >= -0.001*gradient)
      if gradient==0,
        dX = -gX;
      else
        dX = -gX/gradient;
      end
      dX_old = -gX;
      dperf = gX'*dX;
    end

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
  elseif (a == 0), tr.stop = 'Minimum step size reached.';
  end
  
  % Training record
  if doTest
    [tperf,ignore,testV.Y] = calcperf2(net,X,testV.Pd,testV.Tl,testV.Ai,testV.Q,testV.TS);
  end
  tr = tr_update(tr,[epoch current_time perf vperf tperf gradient val_fail a]);
  
  % Feedback
  nn_train_feedback('update',net,status,tr,{trainV valV testV}, ...
    [epoch,current_time,best_perf,gradient,val_fail,a]);
  
  % Stop
  if ~isempty(tr.stop), break, end

  % Minimize the performance along the search direction
  [a,gX,perf,retcode,delta,tol] = feval(searchFcn,net,X,trainV.Pd,trainV.Tl,trainV.Ai,Q,TS, ...
    dX,gX,perf,dperf,delta,tol,ch_perf);

  % Keep track of the number of function evaluations
  sum1 = sum1 + retcode(1);
  sum2 = sum2 + retcode(2);
  
  % Update X
  X = X + a*dX;
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

