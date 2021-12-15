function [net,tr,Y,E,Xf,Af]=train(net,X,T,Xi,Ai,arg6,arg7)
%TRAIN Train a neural network.
%
%  Syntax
%
%    [net,tr] = train(NET,X,T,Pi,Ai)
%
%  Description
%
%    TRAIN trains a network NET according to NET.trainFcn and
%    NET.trainParam.
%
%    TRAIN(NET,X,T,Xi,Ai) takes,
%      NET - Network.
%      X   - Network inputs.
%      T   - Network targets, default = zeros.
%      Xi  - Initial input delay conditions, default = zeros.
%      Ai  - Initial layer delay conditions, default = zeros.
%    and returns,
%      NET - New network.
%      TR  - Training record (epoch and perf).
%
%    Note that T is optional and need only be used for networks
%    that require targets.  Xi and Xf are also optional and need
%    only be used for networks that have input or layer delays.
%    Optional arguments VV and TV are described below.
%
%    TRAIN's signal arguments can have two formats: cell array or matrix.
%    
%    The cell array format is easiest to describe.  It is most
%    convenient for networks with multiple inputs and outputs,
%    and allows sequences of inputs to be presented:
%      X  - NixTS cell array, each element P{i,ts} is an RixQ matrix.
%      T  - NtxTS cell array, each element P{i,ts} is an VixQ matrix.
%      Xi - NixID cell array, each element Xi{i,k} is an RixQ matrix.
%      Ai - NlxLD cell array, each element Ai{i,k} is an SixQ matrix.
%      Y  - NOxTS cell array, each element Y{i,ts} is an UixQ matrix.
%      E  - NtxTS cell array, each element X{i,ts} is an VixQ matrix.
%      Xf - NixID cell array, each element Pf{i,k} is an RixQ matrix.
%      Af - NlxLD cell array, each element Af{i,k} is an SixQ matrix.
%    Where:
%      Ni = net.numInputs
%      Nl = net.numLayers
%      Nt = net.numOutputs
%      ID = net.numInputDelays
%      LD = net.numLayerDelays
%      TS = number of time steps
%      Q  = batch size
%      Ri = net.inputs{i}.size
%      Si = net.layers{i}.size
%      Vi = net.outputs{i}.size
%
%    The columns of Xi, Xf, Ai, and Af are ordered from the oldest delay
%    condition to most recent:
%      Xi{i,k} = input i at time ts=k-ID.
%      Xf{i,k} = input i at time ts=TS+k-ID.
%      Ai{i,k} = layer output i at time ts=k-LD.
%      Af{i,k} = layer output i at time ts=TS+k-LD.
%
%    The matrix format can be used if only one time step is to be
%    simulated (TS = 1).  It is convenient for network's with
%     only one input and output, but can be used with networks that
%     have more.
%
%    Each matrix argument is found by storing the elements of
%    the corresponding cell array argument into a single matrix:
%      P  - (sum of Ri)xQ matrix
%      T  - (sum of Vi)xQ matrix
%      Xi - (sum of Ri)x(ID*Q) matrix.
%      Ai - (sum of Si)x(LD*Q) matrix.
%      Y  - (sum of Ui)xQ matrix.
%      E  - (sum of Vi)xQ matrix
%      Xf - (sum of Ri)x(ID*Q) matrix.
%      Af - (sum of Si)x(LD*Q) matrix.
%
%  Examples
%
%    Here input P and targets T define a simple function which
%    we can plot:
%
%      p = [0 1 2 3 4 5 6 7 8];
%      t = [0 0.84 0.91 0.14 -0.77 -0.96 -0.28 0.66 0.99];
%      plot(p,t,'o')
%
%    Here NEWFF is used to create a two layer feed forward network.
%    The network will have a single hidden layer of 10 neurons.
%
%      net = newff(p,t,10);
%      y1 = sim(net,p)
%      plot(p,t,'o',p,y1,'x')
%
%    Here the network is trained for up to 50 epochs to a error goal of
%    0.01, and then resimulated.
%
%      net.trainParam.epochs = 50;
%      net.trainParam.goal = 0.01;
%      net = train(net,p,t);
%      y2 = sim(net,p)
%      plot(p,t,'o',p,y1,'x',p,y2,'*')
%      
%  Algorithm
%
%    TRAIN calls the function indicated by NET.trainFcn, using the
%    training parameter values indicated by NET.trainParam.
%
%    Typically one epoch of training is defined as a single presentation
%    of all input vectors to the network.  The network is then updated
%    according to the results of all those presentations.
%
%    Training occurs until a maximum number of epochs occurs, the
%    performance goal is met, or any other stopping condition of the
%    function NET.trainFcn occurs.
%
%    Some training functions depart from this norm by presenting only
%    one input vector (or sequence) each epoch. An input vector (or sequence)
%    is chosen randomly each epoch from concurrent input vectors (or sequences).
%    NEWC and NEWSOM return networks that use TRAINR, a training function
%    that does this.
%
%  See also INIT, REVERT, SIM, ADAPT

%  Mark Beale, 11-31-97
%  Copyright 1992-2008 The MathWorks, Inc.
%  $Revision: 1.11.4.9 $ $Date: 2008/06/20 08:04:29 $

%% ARGUMENT CHECKS
if nargin < 2, error('NNET:Arguments','Not enough input arguments.'); end
if ~isa(net,'network'), error('NNET:Arguments','First argument is not a network.'); end
if net.hint.zeroDelay, error('NNET:Arguments','Network contains a zero-delay loop.'); end
if isempty(net.trainFcn), error('NNET:Arguments','Network "trainFcn" is undefined.'); end

%% NNT 5.0 Compatibility
switch nargin
  case 6, [net,tr,Y,E,Xf,Af] = v51_train_arg6(net,X,T,Xi,Ai,arg6); return
  case 7,[net,tr,Y,E,Xf,Af] = v51_train_arg7(net,X,T,Xi,Ai,arg6,arg7); return
end

%% DATA CHECKS AND FORMATTING
net = struct(net); % Network to struct, for efficiency
switch nargin
  case 2, [err,X,T,Xi,Ai,Q,TS,matrixForm] = trainargs(net,X,[],[],[]);
  case 3, [err,X,T,Xi,Ai,Q,TS,matrixForm] = trainargs(net,X,T,[],[]);
  case 4, [err,X,T,Xi,Ai,Q,TS,matrixForm] = trainargs(net,X,T,Xi,[]);
  case 5, [err,X,T,Xi,Ai,Q,TS,matrixForm] = trainargs(net,X,T,Xi,Ai);
end
if ~isempty(err), error('NNET:Arguments',err), end

%% Process Inputs
Xc = [Xi X];
Pc = processinputs(net,Xc);
Pd = calcpd(net,TS,Q,Pc);

%% Expand targets
Tl = cellmat_expand_cell_rows(T,net.hint.outputInd,net.numLayers);

%% Data division
divideFcn = net.divideFcn;
if isempty(divideFcn), divideFcn = 'dividenull'; end

trainV.name = 'Training';
valV.name = 'Validation';
testV.name = 'Test';

[trainV.indices,valV.indices,testV.indices] = feval(divideFcn,1:Q,net.divideParam);
[trainV.X,valV.X,testV.X] = divideind(X,trainV.indices,valV.indices,testV.indices);
[trainV.Xi,valV.Xi,testV.Xi] = divideind(Xi,trainV.indices,valV.indices,testV.indices);
[trainV.Pd,valV.Pd,testV.Pd] = divideind(Pd,trainV.indices,valV.indices,testV.indices);
[trainV.T,valV.T,testV.T] = divideind(T,trainV.indices,valV.indices,testV.indices);
[trainV.Tl,valV.Tl,testV.Tl] = divideind(Tl,trainV.indices,valV.indices,testV.indices);
[trainV.Ai,valV.Ai,testV.Ai] = divideind(Ai,trainV.indices,valV.indices,testV.indices);
[trainV.Y,valV.Y,testV.Y] = deal({[],[],[]});
trainV.Q = length(trainV.indices);
valV.Q = length(valV.indices);
testV.Q = length(testV.indices);
trainV.TS = TS;
valV.TS = TS;
testV.TS = TS;

%% Flatten time series, for networks with no input delays
trainFcn = net.trainFcn;
time_flattened = (net.numLayerDelays == 0) && (TS > 1) && (~strcmp(trainFcn,'trains'));
if time_flattened
  trainV = flatten_time(trainV);
  valV = flatten_time(valV);
  testV = flatten_time(testV);
end

%% Training record
tr.trainFcn = trainFcn;
tr.trainParam = net.trainParam;
tr.performFcn = net.performFcn;
tr.performParam = net.performParam;
tr.divideFcn = net.divideFcn;
tr.divideParam = net.divideParam;
tr.trainInd = trainV.indices;
tr.valInd = valV.indices;
tr.testInd = testV.indices;
tr.stop = '';
tr.num_epochs = -1;

%% Train
try
  trainInfo = feval(trainFcn,'info');
catch
  trainInfo.version = 5.1;
end
if trainInfo.version < 6
  if valV.Q == 0
    valV = [];
    testV = [];
  end
  [net,tr2] = feval(trainFcn,net,trainV.Pd,trainV.Tl,trainV.Ai,trainV.Q,trainV.TS,valV,testV);
  values1 = struct2cell(tr); fields1 = fieldnames(tr);
  values2 = struct2cell(tr2); fields2 = fieldnames(tr2);
  tr = cell2struct([values1; values2],[fields1; fields2]);
else
  [net,tr] = feval(net.trainFcn,net,tr,trainV,valV,testV);
end
net = network(net);

%% NNT 5.1 Compatibility
if nargout > 2
  [Y,Xf,Af,E] = sim(net,trainV.X,trainV.Xi,trainV.Ai,trainV.T);
  if (matrixForm)
    Y = cell2mat(Y);
    E = cell2mat(E);
    Xf = cell2mat(Xf);
    Af = cell2mat(Af);
  end
end

%% ============================================================
function [err,P,T,Pi,Ai,Q,TS,matrixForm] = trainargs(net,P,T,Pi,Ai)

% Check signals: all matrices or all cell arrays
% Change empty matrices/arrays to proper form
switch class(P)
  case 'cell', matrixForm = 0; name = 'cell array'; default = {};
  case {'double','logical'}, matrixForm = 1; name = 'matrix'; default = [];
  otherwise, err = 'X must be a matrix or cell array.'; return
end

if isempty(T), T = default; end
if isempty(Pi), Pi = default; end
if isempty(Ai), Ai = default; end

if ((isnumeric(T) | islogical(T)) ~= matrixForm)
  err = ['X is a ' name ', so T must be a ' name ' too.']; return
end
if ((isnumeric(Pi)|islogical(Pi)) ~= matrixForm)
  err = ['X is a ' name ', so Xi must be a ' name ' too.']; return
end
if ((isnumeric(Ai)|islogical(Ai)) ~= matrixForm)
  err = ['X is a ' name ', so Ai must be a ' name ' too.']; return
end

% Check Matrices, Matrices -> Cell Arrays
if (matrixForm)
  Q = size(P,2);
  TS = 1;
  [err,P] = formatp(net,P,Q); if ~isempty(err), return, end
  [err,T] = formatt(net,T,Q,TS); if ~isempty(err), return, end
  [err,Pi] = formatpi(net,Pi,Q); if ~isempty(err), return, end
  [err,Ai] = formatai(net,Ai,Q); if ~isempty(err), return, end
  
% Check Cell Arrays
else
  TS = size(P,2);
  Q = size(P{1,1},2);
  [err] = checkp(net,P,Q,TS); if ~isempty(err), return, end
  [err,T] = checkt(net,T,Q,TS); if ~isempty(err), return, end
  [err,Pi] = checkpi(net,Pi,Q); if ~isempty(err), return, end
  [err,Ai] = checkai(net,Ai,Q); if ~isempty(err), return, end
end
err = '';

% ============================================================
function signals = flatten_time(signals)

signals.unflattend_Q = signals.Q;
signals.unflattend_TS = signals.TS;

signals.Pd = seq2con(signals.Pd);
signals.Tl = seq2con(signals.Tl);
signals.Q = signals.Q * signals.TS;
signals.TS = 1;
