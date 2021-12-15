function [net,tr,o3,o4,o5,o6,o7,o8] = trainlm(net,tr,trainV,valV,testV,varargin)
%TRAINLM Levenberg-Marquardt backpropagation.
%
%  Syntax
%  
%    [net,tr] = trainlm(net,tr,trainV,valV,testV)
%    info = trainlm('info')
%
%  Description
%
%    TRAINLM is a network training function that updates weight and
%    bias states according to Levenberg-Marquardt optimization.
%
%    TRAINLM is often the fastest backpropagation algorithm in the toolbox,
%    and is highly recommended as a first choice supervised algorithm,
%    although it does require more memory than other algorithms.
%
%    TRAINLM(NET,TR,TRAINV,VALV,TESTV) takes these inputs,
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
%      net.trainParam.max_fail     5  Maximum validation failures
%      net.trainParam.mem_reduc    1  Factor to use for memory/speed trade off.
%      net.trainParam.min_grad 1e-10  Minimum performance gradient
%      net.trainParam.mu       0.001  Initial Mu
%      net.trainParam.mu_dec     0.1  Mu decrease factor
%      net.trainParam.mu_inc      10  Mu increase factor
%      net.trainParam.mu_max    1e10  Maximum Mu
%      net.trainParam.time       inf  Maximum time to train in seconds
%
%
%    TRAINLM is the default training function for several network creation
%    functions including NEWFF, NEWCF, NEWTD, NEWDTDNN and NEWNARX.
%
%    TRAINLM('info') returns useful information about this function.
%
%  Algorithm
%
%    TRAINLM supports training with validation and test vectors if the
%    network's NET.divideFcn property is set to a data division function.
%    Validation vectors are used to stop training early if the network
%    performance on the validation vectors fails to improve or remains
%    the same for MAX_FAIL epochs in a row.  Test vectors are used as
%    a further check that the network is generalizing well, but do not
%    have any effect on training.
%
%    TRAINLM can train any network as long as its weight, net input,
%    and transfer functions have derivative functions.
%
%    Backpropagation is used to calculate the Jacobian jX of performance
%    PERF with respect to the weight and bias variables X.  Each
%    variable is adjusted according to Levenberg-Marquardt,
%
%      jj = jX * jX
%      je = jX * E
%      dX = -(jj+I*mu) \ je
%
%    where E is all errors and I is the identity matrix.
%
%    The adaptive value MU is increased by MU_INC until the change above
%    results in a reduced performance value.  The change is then made to
%    the network and mu is decreased by MU_DEC.
%
%    The parameter MEM_REDUC indicates how to use memory and speed to
%    calculate the Jacobian jX.  If MEM_REDUC is 1, then TRAINLM runs
%    the fastest, but can require a lot of memory. Increasing MEM_REDUC
%    to 2, cuts some of the memory required by a factor of two, but
%    slows TRAINLM somewhat.  Higher states continue to decrease the
%    amount of memory needed and increase training times.
%
%    Training stops when any of these conditions occurs:
%    1) The maximum number of EPOCHS (repetitions) is reached.
%    2) The maximum amount of TIME has been exceeded.
%    3) Performance has been minimized to the GOAL.
%    4) The performance gradient falls below MINGRAD.
%    5) MU exceeds MU_MAX.
%    6) Validation performance has increased more than MAX_FAIL times
%       since the last time it decreased (when using validation).
%
%  See also TEMPLATE_TRAIN, NEWFF, NEWCF, NEWTD, NEWDTDNN and NEWNARX.

% Mark Beale, 11-31-97, ODJ 11/20/98
% Updated by Orlando De Jesús, Martin Hagan, Dynamic Training 7-20-05
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.8 $ $Date: 2008/04/06 19:17:05 $

if nargin < 1, error('NNET:Arguments','Not enough input arguments.'); end

% NNT2 Backward Compatibility
if ~isa(net,'struct') && ~isa(net,'char')
  nntobsu('trainlm','Use NNT2FF and TRAIN to update and train your network.')
  switch(nargin)
  case 5, [net,tr,o3,o4] = tlm1(net,tr,trainV,valV,testV,tr); return
  case 6, [net,tr,o3,o4] = tlm1(net,tr,trainV,valV,testV,varargin{:}); return
  case 8, [net,tr,o3,o4,o6,o6] = tlm2(net,tr,trainV,valV,testV,varargin{:}); return
  case 9, [net,tr,o3,o4,o5,o6] = tlm2(net,tr,trainV,valV,testV,varargin{:}); return
  case 11, [net,tr,o3,o4,o5,o6,o7,o8] = tlm3(net,tr,trainV,valV,testV,varargin{:}); return
  case 12, [net,tr,o3,o4,o5,o6,o7,o8] = tlm3(net,tr,trainV,valV,testV,varargin{:}); return
  end
end

%% Info
if strcmp(net,'info')
  info.function = mfilename;
  info.title = 'Levenberg-Marquardt';
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
  info.param_defaults.mu = 0.001;
  info.param_defaults.mu_dec = 0.1;
  info.param_defaults.mu_inc = 10;
  info.param_defaults.mu_max = 1e10;
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
    case 'gdefaults', if (tr==0), else net='calcjxfp'; end
    otherwise, error('NNET:Arguments','Unrecognized code.')
  end
  return
end

%% Parameters
tp = net.trainParam;
epochs = tp.epochs;
goal = tp.goal;
max_fail = tp.max_fail;
mem_reduc = tp.mem_reduc;
min_grad = tp.min_grad;
mu = tp.mu;
mu_inc = tp.mu_inc;
mu_dec = tp.mu_dec;
mu_max = tp.mu_max;
time = tp.time;
showWindow = tp.showWindow;
showCommandLine = tp.showCommandLine;

% Parameter Checking
if (~isa(epochs,'double')) || (~isreal(epochs)) || (any(size(epochs)) ~= 1) || ...
  (epochs < 1) || (round(epochs) ~= epochs)
  error('NNET:Arguments','Epochs is not a positive integer.')
end
if ~nn_is_scalar_binary(showWindow)
  error('NNET:Arguments','''showWindow'' is not a scalar logical, 1 or 0.')
end
if ~nn_is_scalar_binary(showCommandLine)
  error('NNET:Arguments','''showCommandLine'' is not a scalar logical, 1 or 0.')
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
if (~isa(time,'double')) || (~isreal(time)) || (any(size(time)) ~= 1) || (time < 0)
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
lengthX = length(X);
ii = sparse(1:lengthX,1:lengthX,ones(1,lengthX));

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

% Test (Test may need updating)
if (0), test_trainlm_gradient, end

%% Training Record
tr.best_epoch = 0;
tr.goal = goal;
tr.states = {'epoch','time','perf','vperf','tperf','mu','gradient','val_fail'};

%% Status
status = ...
  [ ...
  training_status('Epoch','iterations','linear','discrete',0,epochs,0), ...
  training_status('Time','seconds','linear','discrete',0,time,0), ...
  training_status('Performance','','log','continuous',best_perf,goal,best_perf) ...
  training_status('Gradient','','log','continuous',1,min_grad,1) ...
  training_status('Mu','','log','continuous',mu,mu_max,mu) ...
  training_status('Validation Checks','','linear','discrete',0,max_fail,0) ...
  ];
nn_train_feedback('start',net,status);

%% Train
for epoch = 0:epochs
    
  % Jacobian
  [je,jj,gradient] = calcjejj(net,trainV.Pd,Zb,Zi,Zl,N,Ac,El,Q,TS,mem_reduc);
  
  % Stopping Criteria
  current_time = etime(clock,startTime);
  [userStop,userCancel] = nntraintool('check');
  if userStop, tr.stop = 'User stop.'; net = best_net;
  elseif userCancel, tr.stop = 'User cancel.'; net = original_net;
  elseif (perf <= goal), tr.stop = 'Performance goal met.'; net = best_net;
  elseif (epoch == epochs), tr.stop = 'Maximum epoch reached.'; net = best_net;
  elseif (current_time >= time), tr.stop = 'Maximum time elapsed.'; net = best_net;
  elseif (gradient <= min_grad), tr.stop = 'Minimum gradient reached.'; net = best_net;
  elseif (mu >= mu_max), tr.stop = 'Maximum MU reached.'; net = best_net;
  elseif (doValidation) && (val_fail >= max_fail), tr.stop = 'Validation stop.'; net = best_net;
  end
  
  % Training record
  if doTest
    [tperf,ignore,testV.Y] = calcperf2(net,X,testV.Pd,testV.Tl,testV.Ai,testV.Q,testV.TS);
  end
  tr = tr_update(tr,[epoch current_time perf vperf tperf mu gradient val_fail]);
  
  % Feedback
  nn_train_feedback('update',net,status,tr,{trainV valV testV}, ...
    [epoch,current_time,best_perf,gradient,mu,val_fail]);
  
  % Stop
  if ~isempty(tr.stop), break, end

  % Levenberg Marquardt
  while (mu <= mu_max)
    % CHECK FOR SINGULAR MATRIX
    [msgstr,msgid] = lastwarn;
    lastwarn('MATLAB:nothing','MATLAB:nothing')
    warnstate = warning('off','all');
    dX = -(jj+ii*mu) \ je;
    [msgstr1,msgid1] = lastwarn;
    flag_inv = isequal(msgid1,'MATLAB:nothing');
    if flag_inv, lastwarn(msgstr,msgid); end;
    warning(warnstate)
    X2 = X + dX;
    net2 = setx(net,X2);
    [perf2,El2,Y2,Ac2,N2,Zb2,Zi2,Zl2] = calcperf2(net2,X2,trainV.Pd,trainV.Tl,trainV.Ai,Q,TS);
    
    if (perf2 < perf) && flag_inv
      X = X2; net = net2; Zb = Zb2; Zi = Zi2; Zl = Zl2;
      N = N2; Ac = Ac2; trainV.Y = Y2; El = El2; perf = perf2;
      mu = mu * mu_dec;
      if (mu < 1e-20), mu = 1e-20; end
      break
    end
    mu = mu * mu_inc;
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

%% Finish
tr = tr_clip(tr);
