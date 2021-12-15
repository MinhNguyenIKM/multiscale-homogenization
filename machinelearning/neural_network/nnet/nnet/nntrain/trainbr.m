function [net,tr] = trainbr(net,tr,trainV,valV,testV,varargin)
%TRAINBR Bayesian Regulation backpropagation.
%
%  Syntax
%  
%    [net,tr] = trainbr(net,tr,trainV,valV,testV)
%    info = trainbr('info')
%
%  Description
%
%    TRAINBR is a network training function that updates the weight and
%    bias values according to Levenberg-Marquardt optimization.  It
%     minimizes a combination of squared errors and weights
%     and, then determines the correct combination so as to produce a
%     network which generalizes well.  The process is called Bayesian
%     regularization.
%
%    TRAINBR(NET,TR,TRAINV,VALV,TESTV) takes these inputs,
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
%      net.trainParam.show        25  Epochs between displays
%      net.trainParam.showCommandLine 0 generate command line output
%      net.trainParam.showWindow   1 show training GUI
%      net.trainParam.epochs     100  Maximum number of epochs to train
%      net.trainParam.goal         0  Performance goal
%      net.trainParam.mu       0.005  Marquardt adjustment parameter
%      net.trainParam.mu_dec     0.1  Decrease factor for mu
%      net.trainParam.mu_inc      10  Increase factor for mu
%      net.trainParam.mu_max    1e10  Maximum value for mu
%      net.trainParam.max_fail     5  Maximum validation failures
%      net.trainParam.mem_reduc    1  Factor to use for memory/speed trade off.
%      net.trainParam.min_grad 1e-10  Minimum performance gradient
%      net.trainParam.time       inf  Maximum time to train in seconds
%
%    TRAINBR('info') returns useful information about this function.
%
%  Network Use
%
%    You can create a standard network that uses TRAINBR with
%    NEWFF, NEWCF, or NEWELM.
%
%    To prepare a custom network to be trained with TRAINBR:
%    1) Set NET.trainFcn to 'trainlm'.
%       This will set NET.trainParam to TRAINBR's default parameters.
%    2) Set NET.trainParam properties to desired values.
%
%    In either case, calling TRAIN with the resulting network will
%    train the network with TRAINBR.
%
%    See NEWFF, NEWCF, and NEWELM for examples.
%
%   Example
%
%     Here is a problem consisting of inputs p and targets t that we would
%     like to solve with a network.  It involves fitting a noisy sine wave.
%
%       p = [-1:.05:1];
%       t = sin(2*pi*p)+0.1*randn(size(p));
%
%     A feedforward network is created with a hidden layer of 2 neurons.
%
%      net = newff(p,t,2,{},'trainbr');
%      a = sim(net,p)
%
%    Here the network is trained and tested.
%
%      net = train(net,p,t);
%      a = sim(net,p)
%
%  Algorithm
%
%    TRAINBR can train any network as long as its weight, net input,
%    and transfer functions have derivative functions.
%
%     Bayesian regularization minimizes a linear combination of squared
%     errors and weights.  It also modifies the linear combination
%     so that at the end of training the resulting network has good
%     generalization qualities.
%     See MacKay (Neural Computation, vol. 4, no. 3, 1992, pp. 415-447)
%     and Foresee and Hagan (Proceedings of the International Joint
%     Conference on Neural Networks, June, 1997) for more detailed
%     discussions of Bayesian regularization.
%
%     This Bayesian regularization takes place within the Levenberg-Marquardt
%     algorithm. Backpropagation is used to calculate the Jacobian jX of
%    performance PERF with respect to the weight and bias variables X. 
%    Each variable is adjusted according to Levenberg-Marquardt,
%
%      jj = jX * jX
%      je = jX * E
%      dX = -(jj+I*mu) \ je
%
%    where E is all errors and I is the identity matrix.
%
%    The adaptive value MU is increased by MU_INC until the change shown above
%    results in a reduced performance value.  The change is then made to
%    the network and mu is decreased by MU_DEC.
%
%    The parameter MEM_REDUC indicates how to use memory and speed to
%    calculate the Jacobian jX.  If MEM_REDUC is 1, then TRAINLM runs
%    the fastest, but can require a lot of memory. Increasing MEM_REDUC
%    to 2 cuts some of the memory required by a factor of two, but
%    slows TRAINLM somewhat.  Higher values continue to decrease the
%    amount of memory needed and increase the training times.
%
%    Training stops when any of these conditions occur:
%
%    1) The maximum number of EPOCHS (repetitions) is reached.
%    2) The maximum amount of TIME has been exceeded.
%    3) Performance has been minimized to the GOAL.
%    4) The performance gradient falls below MINGRAD.
%    5) MU exceeds MU_MAX.
%    6) Validation performance has increase more than MAX_FAIL times
%       since the last time it decreased (when using validation).
%
%  See also NEWFF, NEWCF, TRAINGDM, TRAINGDA, TRAINGDX, TRAINLM,
%           TRAINRP, TRAINCGF, TRAINCGB, TRAINSCG, TRAINCGP,
%           TRAINBFG.
%
%   References
%
%     MacKay, Neural Computation, vol. 4, no. 3, 1992, pp. 415-447.
%
%     Foresee and Hagan, Proceedings of the International Joint 
%     Conference on Neural Networks, June, 1997.

% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.11 $ $Date: 2008/12/01 07:20:38 $

% FUNCTION INFO
% =============

%% Info
if strcmp(net,'info')
  info.function = mfilename;
  info.title = 'Bayesian Regulation';
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
  info.param_defaults.mem_reduc = 1;
  info.param_defaults.min_grad = 1e-10;
  info.param_defaults.mu = 0.005;
  info.param_defaults.mu_dec = 0.1;
  info.param_defaults.mu_inc = 10;
  info.param_defaults.mu_max = 1e10;
  info.training_states = ...
    [ ...
    training_state_info('gradient','Gradient','continuous','log') ...
    training_state_info('mu','Mu','continuous','log') ...
    training_state_info('val_fail','Validation Checks','discrete','linear') ...
    training_state_info('gamk','Num Parameters','continuous','linear') ...
    training_state_info('ssX','Sum Squared Param','continuous','log') ...
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
    case 'gdefaults', if (tr==0), net='calcjx'; else net='calcjxbt'; end
    otherwise, error('NNET:Arguments','Unrecognized code.')
  end
  return
end

% CALCULATION
% ===========

% Constants
epochs = net.trainParam.epochs;
goal = net.trainParam.goal;
max_fail = net.trainParam.max_fail;
mem_reduc = net.trainParam.mem_reduc;
min_grad = net.trainParam.min_grad;
mu = net.trainParam.mu;
mu_inc = net.trainParam.mu_inc;
mu_dec = net.trainParam.mu_dec;
mu_max = net.trainParam.mu_max;
show = net.trainParam.show;
max_time = net.trainParam.time;
net.performFcn = 'sse';

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
if (~isa(mem_reduc,'double')) || (~isreal(mem_reduc)) || (any(size(mem_reduc)) ~= 1) || ...
  (mem_reduc < 1) || (round(mem_reduc) ~= mem_reduc)
  error('NNET:Arguments','Mem_reduc is not a positive integer.')
end
if (~isa(min_grad,'double')) || (~isreal(min_grad)) || (any(size(min_grad)) ~= 1) || ...
  (min_grad < 0)
  error('NNET:Arguments','Min_grad is not zero or a positive real value.')
end
if (~isa(mu,'double')) || (~isreal(mu)) || (any(size(mu)) ~= 1) || ...
  (mu <= 0)
  error('NNET:Arguments','Mu is not a positive real value.')
end
if (~isa(mu_dec,'double')) || (~isreal(mu_dec)) || (any(size(mu_dec)) ~= 1) || ...
  (mu_dec < 0) || (mu_dec > 1)
  error('NNET:Arguments','Mu_dec is not a real value between 0 and 1.')
end
if (~isa(mu_inc,'double')) || (~isreal(mu_inc)) || (any(size(mu_inc)) ~= 1) || ...
  (mu_inc < 1)
  error('NNET:Arguments','Mu_inc is not a real value greater than 1.')
end
if (~isa(mu_max,'double')) || (~isreal(mu_max)) || (any(size(mu_max)) ~= 1) || ...
  (mu_max <= 0)
  error('NNET:Arguments','Mu_max is not a positive real value.')
end
if (mu > mu_max)
  error('NNET:Arguments','Mu is greater than Mu_max.')
end
if (~isa(show,'double')) || (~isreal(show)) || (any(size(show)) ~= 1) || ...
  (isfinite(show) && ((show < 1) || (round(show) ~= show)))
  error('NNET:Arguments','Show is not ''NaN'' or a positive integer.')
end
if (~isa(max_time,'double')) || (~isreal(max_time)) || (any(size(max_time)) ~= 1) || ...
  (max_time < 0)
  error('NNET:Arguments','Time is not zero or a positive real value.')
end

% Initialize
Q = trainV.Q;
TS = trainV.TS;
vperf = NaN;
tperf = NaN;
val_fail = 0;
startTime = clock;
X = getx(net);
numParameters = length(X);
ii = sparse(1:numParameters,1:numParameters,ones(1,numParameters));

% Initialize Performance
original_net = net;
best_net = net;
doValidation = ~isempty(valV.indices);
doTest = ~isempty(testV.indices);
[ssE,El,trainV.Y,Ac,N,Zb,Zi,Zl] = calcperf2(net,X,trainV.Pd,trainV.Tl,trainV.Ai,Q,TS);

% Initialize regularization parameters
numErrors = 0;
for i=1:size(El,1)
  for j=1:size(El,2)
    numErrors = numErrors + numel(El{i,j});
  end
end
gamk = numParameters;
if ssE == 0,
  beta = 1;
else
  beta = (numErrors - gamk)/(2*ssE);
end
if beta<=0,
  beta=1;
end
ssX = X'*X;
alph = gamk/(2*ssX);
perf = beta*ssE + alph*ssX;

best_perf = ssE;
if (doValidation)
  [vperf,ignore,valV.Y] = calcperf2(net,X,valV.Pd,valV.Tl,valV.Ai,valV.Q,valV.TS);
  best_vperf = vperf;
end

%% Training Record
tr.best_epoch = 0;
tr.goal = goal;
tr.states = {'epoch','time','perf','vperf','tperf','mu','gradient','val_fail','gamk','ssX'};

%% Status
status = ...
  [ ...
  training_status('Epoch','iterations','linear','discrete',0,epochs,0), ...
  training_status('Time','seconds','linear','discrete',0,max_time,0), ...
  training_status('Performance','','log','continuous',best_perf,goal,best_perf) ...
  training_status('Gradient','','log','continuous',1,min_grad,1) ...
  training_status('Mu','','log','continuous',mu,mu_max,mu) ...
  training_status('Validation Checks','','linear','discrete',0,max_fail,0) ...
  training_status('Num Parameters','','linear','continuous',gamk,NaN,NaN) ...
  training_status('Sum Squared Param','','log','continuous',ssX,NaN,NaN) ...
  ];
nn_train_feedback('start',net,status);

% Train
for epoch=0:epochs

  % Jacobian
  [je,jj,gradient] = calcjejj(net,trainV.Pd,Zb,Zi,Zl,N,Ac,El,Q,TS,mem_reduc);
  
  % Stopping Criteria
  current_time = etime(clock,startTime);
  [userStop,userCancel] = nntraintool('check');
  if userStop, tr.stop = 'User stop.'; net = best_net;
  elseif userCancel, tr.stop = 'User cancel.'; net = original_net;
  elseif (ssE <= goal), tr.stop = 'Performance goal met.'; net = best_net;
  elseif (epoch == epochs), tr.stop = 'Maximum epoch reached.';
    net = best_net;
  elseif (current_time >= max_time), tr.stop = 'Maximum time elapsed.'; net = best_net;
  elseif (gradient <= min_grad), tr.stop = 'Minimum gradient reached.'; net = best_net;
  elseif (mu >= mu_max), tr.stop = 'Maximum MU reached.'; net = best_net;
  elseif (doValidation) && (val_fail >= max_fail), tr.stop = 'Validation stop.'; net = best_net;
  end
  
    % Training record
  if doTest
    [tperf,ignore,testV.Y]=calcperf2(net,X,testV.Pd,testV.Tl,testV.Ai,testV.Q,testV.TS);
  end
  tr = tr_update(tr,[epoch current_time ssE vperf tperf mu gradient val_fail gamk ssX]);
  
  % Feedback
  nn_train_feedback('update',net,status,tr,{trainV valV testV}, ...
    [epoch,current_time,best_perf,gradient,mu,val_fail,gamk,ssX]);
  
  % Stop
  if ~isempty(tr.stop), break, end

  % APPLY LEVENBERG MARQUARDT: INCREASE MU TILL ERRORS DECREASE
  while (mu <= mu_max)
    % CHECK FOR SINGULAR MATRIX
    [msgstr,msgid] = lastwarn;
    lastwarn('MATLAB:nothing','MATLAB:nothing')
    warnstate = warning('off','all');
    dX = -(beta*jj + ii*(mu+alph)) \ (beta*je + alph*X);
    [msgstr1,msgid1] = lastwarn;
    flag_inv = isequal(msgid1,'MATLAB:nothing');
    if flag_inv, lastwarn(msgstr,msgid); end;
    warning(warnstate);
    X2 = X + dX;
    ssX2 = X2'*X2;
    net2 = setx(net,X2);
  
    [ssE2,E2,Y2,Ac2,N2,Zb2,Zi2,Zl2] = calcperf2(net2,X2,trainV.Pd,trainV.Tl,trainV.Ai,Q,TS);
   
    perf2 = beta*ssE2 + alph*ssX2;
   
    if (perf2 < perf) && ( ( sum(isinf(dX)) + sum(isnan(dX)) ) == 0 ) && flag_inv
      X = X2; net = net2; Zb = Zb2; Zi = Zi2; Zl = Zl2;
      N = N2; Ac = Ac2; trainV.Y = Y2; El = E2; ssE = ssE2;
      ssX = ssX2;
      mu = mu * mu_dec;
      perf = perf2;
      if (mu < 1e-20), mu = 1e-20; end
      break
    end
    mu = mu * mu_inc;
  end
  
  if (mu <= mu_max)
    % Update regularization parameters and performance function
    warnstate = warning('off','all');
    gamk = numParameters - alph*trace(inv(beta*jj+ii*alph));
    warning(warnstate);
    if ssX==0,
      alph = 1;
    else
      alph = gamk/(2*(ssX));
    end
    if ssE==0,
      beta = 1;
    else
      beta = (numErrors - gamk)/(2*ssE);
    end
    perf = beta*ssE + alph*ssX;

    % Validation
    if (doValidation)
      [vperf,ignore,valV.Y] = calcperf2(net,X,valV.Pd,valV.Tl,valV.Ai,valV.Q,valV.TS);
      if (vperf < best_vperf)
        best_net = net;
        best_perf = ssE;
        best_vperf = vperf;
        tr.best_epoch = epoch+1;
        val_fail = 0;
      elseif (vperf > best_vperf)
        val_fail = val_fail + 1;
      end
    elseif (ssE < best_perf)
      best_net = net;
      best_perf = ssE;
      tr.best_epoch = epoch+1;
    end
  end
end

% Finish
tr = tr_clip(tr);
