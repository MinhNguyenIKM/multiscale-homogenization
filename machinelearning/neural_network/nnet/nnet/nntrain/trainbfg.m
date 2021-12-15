function [net,tr] = trainbfg(net,tr,trainV,valV,testV,varargin)
%TRAINBFG BFGS quasi-Newton backpropagation.
%
%  Syntax
%  
%    [net,tr] = trainbfg(net,tr,trainV,valV,testV)
%    info = trainbfg('info')
%
%  Description
%
%    TRAINBFG is a network training function that updates weight and
%    bias values according to the BFGS quasi-Newton method.
%
%    TRAINBFG(NET,TR,TRAINV,VALV,TESTV) takes these inputs,
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
%      net.trainParam.epochs          100  Maximum number of epochs to train
%      net.trainParam.show             25  Epochs between displays
%      net.trainParam.showCommandLine   0 generate command line output
%      net.trainParam.showWindow        1 show training GUI
%      net.trainParam.goal              0  Performance goal
%      net.trainParam.time            inf  Maximum time to train in seconds
%      net.trainParam.min_grad       1e-6  Minimum performance gradient
%      net.trainParam.max_fail          5  Maximum validation failures
%       net.trainParam.searchFcn 'srchcha'  Name of line search routine to use.
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
%      net.trainParam.batch_frag        0  In case of multiple batches they are considered independent.
%                                           Any non zero value implies a fragmented batch, so final layers
%                                           conditions of a previous trained epoch are used as initial 
%                                           conditions for next epoch.
%
%    TRAINBFG('info') returns useful information about this function.
%
%  Network Use
%
%    You can create a standard network that uses TRAINBFG with
%    NEWFF, NEWCF, or NEWELM.
%
%    To prepare a custom network to be trained with TRAINBFG:
%    1) Set NET.trainFcn to 'trainbfg'.
%       This will set NET.trainParam to TRAINBFG's default parameters.
%    2) Set NET.trainParam properties to desired values.
%
%    In either case, calling TRAIN with the resulting network will
%    train the network with TRAINBFG.
%
%
%  Examples
%
%    Here is a problem consisting of inputs P and targets T that we would
%    like to solve with a network.
%
%      P = [0 1 2 3 4 5];
%      T = [0 0 0 1 1 1];
%
%    Here a feed-forward network is created with one hidden layer of 2 neurons.
%
%      net = newff(P,T,2,{},'trainbfg');
%      a = sim(net,P)
%
%    Here the network is trained and tested.
%
%      net = train(net,P,T);
%      a = sim(net,P)
%
%  Algorithm
%
%    TRAINBFG can train any network as long as its weight, net input,
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
%     In succeeding iterations the search direction is computed 
%     according to the following formula:
%
%       dX = -H\gX;
%
%     where gX is the gradient and H is an approximate Hessian matrix.
%    See page 119 of Gill, Murray & Wright (Practical Optimization  1981) for
%     a more detailed discussion of the BFGS quasi-Newton method.
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
%           TRAINOSS.
%
%   References
%
%     Gill, Murray & Wright, Practical Optimization, 1981.

% Updated by Orlando De Jesús, Martin Hagan, 7-20-05
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.11 $ $Date: 2008/10/31 06:23:25 $

%% Info
if strcmp(net,'info')
  info.function = mfilename;
  info.title = 'BFGS Quasi-Newton';
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
  info.param_defaults.min_grad = 1e-6;
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
  info.param_defaults.batch_frag = 0;
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
% We get gradient function
gradientFcn = net.gradientFcn;
% We get batch flag
batch_frag = net.trainParam.batch_frag;
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

% Initialize
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
tr.states = {'epoch','time','perf','vperf','tperf','gradient','val_fail','dperf','tol','delta','a'};

%% Status
status = ...
  [ ...
  training_status('Epoch','iterations','linear','discrete',0,epochs,0), ...
  training_status('Time','seconds','linear','discrete',0,time,0), ...
  training_status('Performance','','log','continuous',best_perf,goal,best_perf) ...
  training_status('Gradient','','log','continuous',1,min_grad,1) ...
  ];
nn_train_feedback('start',net,status);

%% Train
a=0;
cons_a0=0; % Variable to count multiple cases of a == 0
for epoch=0:epochs

  % Performance, Gradient and Search Direction
  % If a is smaller that tolerance we restart algorithm
  if (epoch == 0) || (a <= tol)

    if epoch~=0
	    if batch_frag
        if Q > 1
           Aisize=size(Ai);
           Acsize=size(Ac,2);
           for k1=1:Aisize(1)
             for k2=1:Aisize(2)
               Ai{k1,k2}(:,2:Q)=Ac{k1,Acsize-Aisize(2)+k2}(:,1:Q-1);
             end
          end
        end
      end
    end
    % First iteration

    % Initial performance
    [perf,El,trainV.Y,Ac,N,Zb,Zi,Zl] = calcperf2(net,X,trainV.Pd,trainV.Tl,trainV.Ai,Q,TS);
    perf_old = perf;
    ch_perf = perf;
    sum1 = 0; sum2 = 0;

    % Initial gradient and norm of gradient
    gX = -calcgx(net,X,trainV.Pd,Zb,Zi,Zl,N,Ac,El,perf,Q,TS);
    gradient = sqrt(gX'*gX);
    gX_old = gX;

% Testing gradient calculation for accuracy with numerical gradient
if 0, % If this flag is zero, no test will be done
  if (epoch==0)
      [gX11] = approxGrad(net,trainV.Pd,trainV.Tl,trainV.Ai,Q,TS,1e-8);
      sseg = sumsqr(gX-gX11);
      den_perc = max(abs(gX11));
      if den_perc~=0,
        gXperc = 100*abs((gX-gX11))./den_perc; 
      else
        den_perc2 = max(abs(gX));
        if den_perc2~=0,
          gXperc = 100*abs((gX-gX11))./den_perc2;
        else
          gXperc = zeros(size(gX));
        end
      end
      rmseg = sqrt(sseg/length(gXperc));
      if(any(gXperc>1e-1)&&(rmseg>1e-4))
        fprintf(['error in gradient'  '\n'])
        zzz=clock;
        fname = cat(2,'grad_err',num2str(zzz(6)));
        fname = strrep(fname,'.','_');
        fprintf(['file name for saved data is ' fname '\n\n'])
        save(fname)
      end
  end
end
%end gradient test

    % Initial search direction and initial slope
    II = eye(num_X);
    H = II;
    dX  = -gX;
    dperf = gX'*dX;

  else
    % After first iteration

    % Calculate change in gradient
    dgX = gX - gX_old;

    % Calculate change in performance and save old performance
    ch_perf = perf - perf_old;
    perf_old = perf;
  
    % Calculate new Hessian approximation
    % If H is rank defficient, use previous H matrix.
    H_ant=H;
    den1 = gX_old'*dX;
    den2 = dgX'*X_step;
    if den1~=0, H = H + gX_old*gX_old'/den1; end
    if den2~=0, H = H + dgX*dgX'/den2; end        
    if any(isnan(H(:)))
       H=H_ant;
    elseif rank(H) ~= num_X
       H=H_ant;
    end

    % Calculate new search direction
    dX = -H\gX;

    % Check for a descent direction
    dperf = gX'*dX;
    if dperf>0
      H = II;
      dX = -gX;
      dperf = gX'*dX;
    end

    % Save old gradient and norm of gradient
    gradient = sqrt(gX'*gX);
    gX_old = gX;
  end
  
  if (a==0) && (epoch>1)
    cons_a0 = cons_a0 + 1;
  elseif (a~=0)   
    cons_a0 = 0;
  end

  % Stopping Criteria
  current_time = etime(clock,startTime);
  [userStop,userCancel] = nntraintool('check');
  if userStop, tr.stop = 'User stop.'; net = best_net;
  elseif userCancel, tr.stop = 'User cancel.'; net = original_net;
  elseif (perf <= goal), tr.stop = 'Performance goal met.';
  elseif (epoch == epochs), tr.stop = 'Maximum epoch reached.'; net = best_net;
  elseif (current_time >= time), tr.stop = 'Maximum time elapsed.'; net = best_net;
  elseif (gradient <= min_grad), tr.stop = 'Minimum gradient reached.'; net = best_net;
  elseif (doValidation) && (val_fail >= max_fail), tr.stop = 'Validation stop.'; net = best_net;
  elseif(any(isnan(dX))||any(isinf(dX))), tr.stop = 'Precision problems in matrix inversion.'; net = best_net;
  elseif (cons_a0 > 3), tr.stop = 'Line Search did not find new minimum.'; net = best_net;
  end
  
  % Training record
  if doTest
    [tperf,ignore,testV.Y] = calcperf2(net,X,testV.Pd,testV.Tl,testV.Ai,testV.Q,testV.TS);
  end
  tr = tr_update(tr,[epoch current_time perf vperf tperf gradient val_fail dperf tol delta a]);
  
  % Feedback
  nn_train_feedback('update',net,status,tr,{trainV valV testV}, ...
    [epoch,current_time,best_perf,gradient,val_fail]);
  
  % Stop
  if ~isempty(tr.stop), break, end

  % We include management for ratio of regularization
  if strcmp('msereg',net.performFcn)
     if (1-net.performParam.ratio) > perf
        net.performParam.ratio = 1-perf;
     end
  end

  % Minimize the performance along the search direction
  % We use previous delta for next line search
  %delta = 1;
  [a,gX,perf,retcode,delta,tol] = ...
    feval(searchFcn,net,X,trainV.Pd,trainV.Tl,trainV.Ai,Q,TS,dX,gX,perf,dperf,delta,tol,ch_perf);

  if batch_frag
  % Temporal Q movement. ****
    Ai = cell(Aisize(1),Aisize(2));
    if Q > 1
      Aisize=size(Ai);
      Acsize=size(Ac,2);
      for k1=1:Aisize(1)
        for k2=1:Aisize(2)
          Ai{k1,k2}(:,2:Q)=Ac{k1,Acsize-Aisize(2)+k2}(:,1:Q-1);
        end
      end
    end
  end
  
  % Keep track of the number of function evaluations
  sum1 = sum1 + retcode(1);
  sum2 = sum2 + retcode(2);
  
  % Update X
  X_step = a*dX;
  X = X + X_step;
  net = setx(net,X);
 
  if batch_frag
     % We recalculate perf for new initial conditions.
     [perf,El,trainV.Y,Ac,N,Zb,Zi,Zl] = calcperf2(net,X,trainV.Pd,trainV.Tl,Ai,Q,TS);
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
