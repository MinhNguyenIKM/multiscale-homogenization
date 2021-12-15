function [net,tr,Ac,El] = template_train(net,Pd,Tl,Ai,Q,TS,VV,TV)
%TEMPLATE_TRAIN Template train function.
%
%  This function is provided to help users who want to understand the
%  conventions of training functions, and as a template for creating
%  custom training functions.
%
%  WARNING - Future versions of the toolbox may introduce changes to
%  these conventions and require custom functions to be updated accordingly.
%
%  Directions for Customizing
%  1. Make a copy of this function with a new name.
%  2. Edit your new function according to the code comments marked ***
%  3. Type HELP NNSEARCH to see a list of other line search functions.
%
%  =====================================================================
%
%  Syntax
%
%    All training functions must support these calling conventions:
%  
%    [net,tr] = template_train(net,trainV,valV,testV,tr)
%    info = template_train('info')
%
%  Description
%
%    Here are the calling conventions in detail:
%
%    TEMPLATE_TRAIN(net,trainV,valV,testV,tr) takes these inputs, as provided
%    by the function TRAIN,
%      net - Neural network.
%      trainV  - Structure of training vectors.
%      valV  - Structure of validation vectors.
%      testV  - Structure of test vectors.
%      tr  - Training record structure.
%    and returns,
%      net - Trained network.
%      tr  - Training record structure.
%      Ac  - Collective layer outputs for last epoch.
%      El  - Layer errors for last epoch.
%
%    Structures trainV, valV and testV have these fields:
%      name - 'Train', 'Validation' or 'Test'
%      indices - Training, validiation or test vector indices.
%      X  - Inputs, NixTS cell, each X{i,ts} is RixQ matrix.
%      Xi - Delayed inputs, NixID cell, each Xi{i,ts} is RixQ matrix.
%      Pd - Processed combined inputs and delayed inputs,
%           NlxNixTS cell, each Pd{i,j,ts} is DijxQ matrix.
%      T  - Output targets, NoxTS cell, each T{i,ts} is WixQ matrix.
%      Tl - Layer targets, NlxTS cell, each Tl{i,ts} is VixQ matrix.
%      Ai - Delayed layer outputs, NlxLD cell, each Ai{i,k} is SixQ matrix.
%    Where
%      Ni = net.numInputs
%      Nl = net.numLayers
%      No = net.numOutputs
%      ID = new.numInputDelays
%      LD = net.numLayerDelays
%      Ri = net.inputs{i}.size
%      Si = net.layers{i}.size
%      Vi = net.targets{i}.size
%      Wi = size of ith output
%      Dij = Ri * length(net.inputWeights{i,j}.delays)
%
%    TEMPLATE_TRAIN('info) returns useful information about this training
%    function including at a minimum the following fields:
%      function - m-function name of this function.
%      title - human readable name for this function.
%      type = 'Training';
%      version = 6;
%      training_mode - 'Supervised' or 'Unsupervised'.
%      gradient_mode - 'Derivative', 'Jacobian', or 'None'.
%      uses_validation - 'Yes' or 'No'.
%      param_defaults - Structure of default training parameter values.
%
%  Network Use
%
%    To train use a particular training function, such as TEMPLATE_TRAIN:
%    1) Set NET.trainFcn to 'template_train'.
%    This will set NET.trainParam to TEMPLATE_TRAIN's default parameters.
%    2) Optionally, change NET.trainParam property values.
%    3) Call TRAIN with the network NET.
%    This will cause the network to be trained with TEMPLATE_TRAIN.

% Copyright 1992-2007 The MathWorks, Inc.

% FUNCTION INFO
% =============

if isstr(net)
  switch (net)
    case 'pnames',
      
      % *** CUSTOMIZE HERE
      % *** This functions parameter names,  if any
      net = {'epochs','goal','max_fail','show','time'};
      % ***
      
    case 'pdefaults',
      net = struct;
      
      % *** CUSTOMIZE HERE
      % *** This functions default parameter values,  if any
      net.epochs = 100;
      net.goal = 0;
      net.max_fail = 5;
      net.show = 25;
      net.time = inf;
      % ***
      
    case 'gdefaults',
       % Pd contains information about a dynamic (~=0) or static (==0) network
       if Pd ==0

         % *** CUSTOMIZE HERE
         % *** Return default gradient function for static networks
         net='calcgrad';
         % ***
         
       else

         % *** CUSTOMIZE HERE
         % *** Return default gradient function for dynamic networks
         net='calcgbtt';
         % ***
         
       end
    otherwise,
    error('NNET:Arguments','Unrecognized code.')
  end
  return
end

% *** CUSTOMIZE HERE
% *** Replace the following training algorithm with your own

% Parameters
epochs = net.trainParam.epochs;
goal = net.trainParam.goal;
max_fail = net.trainParam.max_fail;
show = net.trainParam.show;
time = net.trainParam.time;

% Parameter Checking
if (~isa(epochs,'double')) | (~isreal(epochs)) | (any(size(epochs)) ~= 1) | ...
  (epochs < 1) | (round(epochs) ~= epochs)
  error('NNET:Arguments','Epochs is not a positive integer.')
end
if (~isa(goal,'double')) | (~isreal(goal)) | (any(size(goal)) ~= 1) | ...
  (goal < 0)
  error('NNET:Arguments','Goal is not zero or a positive real value.')
end
if (~isa(max_fail,'double')) | (~isreal(max_fail)) | (any(size(max_fail)) ~= 1) | ...
  (max_fail < 1) | (round(max_fail) ~= max_fail)
  error('NNET:Arguments','Max_fail is not a positive integer.')
end
if (~isa(show,'double')) | (~isreal(show)) | (any(size(show)) ~= 1) | ...
  (isfinite(show) & ((show < 1) | (round(show) ~= show)))
  error('NNET:Arguments','Show is not ''NaN'' or a positive integer.')
end
if (~isa(time,'double')) | (~isreal(time)) | (any(size(time)) ~= 1) | ...
  (time < 0)
  error('NNET:Arguments','Time is not zero or a positive real value.')
end

% Constants
this = 'TRAINB';
numLayers = net.numLayers;
numInputs = net.numInputs;
numLayerDelays = net.numLayerDelays;
needGradient = net.hint.needGradient;
performFcn = net.performFcn;
doValidation = ~isempty(VV);
doTest = ~isempty(TV);

% Signals
BP = ones(1,Q);
gIW = cell(numLayers,numInputs,TS);
gLW = cell(numLayers,numLayers,TS);
gB = cell(net.numLayers,1,TS);
gA = cell(net.numLayers,TS);
IWLS = cell(numLayers,numInputs);
LWLS = cell(numLayers,numLayers);
BLS = cell(numLayers,1);

% Initialize
flag_stop=0;
stop = '';
startTime = clock;
X = getx(net);
if (doValidation)
  VV.net = net;
  vperf = calcperf(net,X,VV.Pd,VV.Tl,VV.Ai,VV.Q,VV.TS);
  VV.perf = vperf;
  VV.numFail = 0;
end
tr = newtr(epochs,'perf','vperf','tperf');

% Train
for epoch=0:epochs

  % Performance
  [Ac,N,Zl,Zi,Zb] = calca(net,Pd,Ai,Q,TS);
  El = calce(net,Ac,Tl,TS);
  E = El(net.outputConnect,:);
  Y = Ac(net.outputConnect,(net.numLayerDelays+1):end);
  perf = feval(performFcn,E,Y,X,net.performParam);

  % Training Record
  epochPlus1 = epoch+1;
  tr.perf(epochPlus1) = perf;
  if (doValidation)
    tr.vperf(epochPlus1) = vperf;
  end
  if (doTest)
    tr.tperf(epochPlus1) = calcperf(net,X,TV.Pd,TV.Tl,TV.Ai,TV.Q,TV.TS);
  end
  
  % Stopping Criteria
  currentTime = etime(clock,startTime);
  if (epoch == epochs)
    stop = 'Maximum epoch reached.';
  elseif (perf <= goal)
    stop = 'Performance goal met.';
  elseif (currentTime > time)
    stop = 'Maximum time elapsed.';
  elseif (doValidation) & (VV.numFail > max_fail)
    stop = 'Validation stop.';
  elseif flag_stop
    stop = 'User stop.';
  end
  
  % Progress
  if isfinite(show) & (~rem(epoch,show) | length(stop))
    fprintf(this);
    if isfinite(epochs) fprintf(', Epoch %g/%g',epoch, epochs); end
  if isfinite(time) fprintf(', Time %g%%',currentTime/time*100); end
  if isfinite(goal) fprintf(', %s %g/%g.',upper(net.performFcn),perf,goal); end
  fprintf('\n')
  flag_stop=plotperf(tr,goal,this,epoch);
    if length(stop), fprintf('%s, %s\n\n',this,stop); end
  end
 
  % Stop when criteria indicate its time
  if length(stop)
    if (doValidation)
      net = VV.net;
    end
      break
  end

  % Gradient
  if (needGradient)
    E = El(net.outputConnect,:);
    Y = Ac(net.outputConnect,(net.numLayerDelays+1):end);
    gE = cell(net.numLayers,TS);
    gE(net.outputConnect,:) = feval(performFcn,'dy',E,Y,X,perf,net.performParam);
    [gB,gIW,gLW,gA] = calcgrad(net,Q,Pd,Zb,Zi,Zl,N,Ac,gE,TS);
  end
  
  % Update with Weight and Bias Learning Functions
  for ts=1:TS
    for i=1:numLayers

      % Update Input Weight Values
      for j=find(net.inputConnect(i,:))
        learnFcn = net.inputWeights{i,j}.learnFcn;
        if length(learnFcn)
          [dw,IWLS{i,j}] = feval(learnFcn,net.IW{i,j}, ...
            Pd{i,j,ts},Zi{i,j},N{i},Ac{i,ts+numLayerDelays},Tl{i,ts},El{i,ts},gIW{i,j,ts},...
            gA{i,ts},net.layers{i}.distances,net.inputWeights{i,j}.learnParam,IWLS{i,j});
          net.IW{i,j} = net.IW{i,j} + dw;
        end
      end
  
      % Update Layer Weight Values
      for j=find(net.layerConnect(i,:))
        learnFcn = net.layerWeights{i,j}.learnFcn;
        if length(learnFcn)
          Ad = cell2mat(Ac(j,ts+numLayerDelays-net.layerWeights{i,j}.delays)');
          [dw,LWLS{i,j}] = feval(learnFcn,net.LW{i,j}, ...
            Ad,Zl{i,j},N{i},Ac{i,ts+numLayerDelays},Tl{i,ts},El{i,ts},gLW{i,j,ts},...
            gA{i,ts},net.layers{i}.distances,net.layerWeights{i,j}.learnParam,LWLS{i,j});
          net.LW{i,j} = net.LW{i,j} + dw;
        end
      end

      % Update Bias Values
      if net.biasConnect(i)
        learnFcn = net.biases{i}.learnFcn;
        if length(learnFcn)
          [db,BLS{i}] = feval(learnFcn,net.b{i}, ...
            BP,Zb{i},N{i},Ac{i,ts+numLayerDelays},Tl{i,ts},El{i,ts},gB{i,ts},...
            gA{i,ts},net.layers{i}.distances,net.biases{i}.learnParam,BLS{i});
          net.b{i} = net.b{i} + db;
        end
      end
    end
  end
  X = getx(net);

  % Validation
  if (doValidation)
    vperf = calcperf(net,X,VV.Pd,VV.Tl,VV.Ai,VV.Q,VV.TS);
  if (vperf < VV.perf)
    VV.perf = vperf; VV.net = net; VV.numFail = 0;
  elseif (vperf > VV.perf)
      VV.numFail = VV.numFail + 1;
  end
  end
end

% Finish
tr = cliptr(tr,epoch);

% ***
