function net = newdtdnn(varargin)
%NEWDTDNN Create a distributed time delay neural network.
%
%  Syntax
%
%    net = newdtdnn(P,T,[S1...S(N-1)],{D1...DN},{TF1...TFN},
%      BTF,BLF,PF,IPF,OPF,DDF)
%
%  Description
%
%    NEWDTDNN(P,T,[S1...],{D1...},{TF1...},BTF,BLF,PF,IPF,OPF,DDF) takes,
%      P  - RxQ1 matrix of Q1 representative R-element input vectors.
%      T  - SNxQ2 matrix of Q2 representative SN-element target vectors.
%      Si  - Sizes of N-1 hidden layers, S1 to S(N-1), default = [].
%            (Output layer size SN is determined from T.)
%      Di  - Delay vector for the ith layer.
%      TFi - Transfer function of ith layer. Default is 'tansig' for
%            hidden layers, and 'purelin' for output layer.
%      BTF - Backprop network training function, default = 'trainlm'.
%      BLF - Backprop weight/bias learning function, default = 'learngdm'.
%      PF  - Performance function, default = 'mse'.
%      IPF - Row cell array of input processing functions.
%            Default is {'fixunknowns','remconstantrows','mapminmax'}.
%      OPF - Row cell array of output processing functions.
%            Default is {'remconstantrows','mapminmax'}.
%      DDF - Data division function, default = 'dividerand';
%    and returns an N layer distributed time delay neural network.
%
%    The transfer functions TFi can be any differentiable transfer
%    function such as TANSIG, LOGSIG, or PURELIN.
%
%    The training function BTF can be any of the backprop training
%    functions such as TRAINLM, TRAINBFG, TRAINRP, TRAINGD, etc.
%
%    *WARNING*: TRAINLM is the default training function because it
%    is very fast, but it requires a lot of memory to run.  If you get
%    an "out-of-memory" error when training try doing one of these:
%
%    (1) Slow TRAINLM training, but reduce memory requirements, by
%        setting NET.trainParam.mem_reduc to 2 or more. (See HELP TRAINLM.)
%    (2) Use TRAINBFG, which is slower but more memory efficient than TRAINLM.
%    (3) Use TRAINRP which is slower but more memory efficient than TRAINBFG.
%
%    The learning function BLF can be either of the backpropagation
%    learning functions such as LEARNGD, or LEARNGDM.
%
%    The performance function can be any of the differentiable performance
%    functions such as MSE or MSEREG.
%
%  Examples
%
%    Here is a problem consisting of an input sequence P and target
%    sequence T that can be solved by a network with one delay.
%
%      P = {1  0 0 1 1  0 1  0 0 0 0 1 1  0 0 1};
%      T = {1 -1 0 1 0 -1 1 -1 0 0 0 1 0 -1 0 1};
%
%    Here a network is created with one hidden layer of 5 neurons, and
%    delays of [0 1] for the hidden and output layers.
%
%      net = newdtdnn(P,T,5,{[0 1] [0 1]});
%
%    Here the network is simulated.
%
%      Y = sim(net,P)
%
%    Here the network is trained for 50 epochs.  Again the network's
%     output is calculated.
%
%      net.trainParam.epochs = 50;
%      net = train(net,P,T);
%      Y = sim(net,P)
%
%  Algorithm
%
%    Feed-forward networks consists of Nl layers using the DOTPROD
%    weight function, NETSUM net input function, and the specified
%    transfer functions.
%
%    The first layer has weights coming from the input with the
%    specified input delays.  Each subsequent layer has a weight coming
%    from the previous layer and specified layer delays.  All layers have
%    biases.  The last layer is the network output.
%    
%
%    Each layer's weights and biases are initialized with INITNW.
%
%    Adaption is done with TRAINS which updates weights with the
%    specified learning function. Training is done with the specified
%    training function. Performance is measured according to the specified
%    performance function.
%
%  See also NEWCF, NEWELM, SIM, INIT, ADAPT, TRAIN, TRAINS

% Orlando De Jesús, Martin Hagan, 7-20-05
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.6 $

if nargin < 2, error('NNET:Arguments','Not enough input arguments'), end

v1 = varargin{1};
if isa(v1,'cell'), v1 = cell2mat(v1); end
v2 = varargin{2};
if nargin > 3,v4 = varargin{4}; end

if (nargin<=7)...
  && (size(v1,2)==2) ...
  && iscell(v2) && (size(v2,1)==1) ...
  && (size(cell2mat(v2),1)==1) ...
  && ((nargin<4) || (numel(v4)==0) || ischar(v4{1}))
  nntobsu(mfilename,['See help for ' upper(mfilename) ' to update calls to the new argument list.']);
  net = new_5p0(varargin{:});
else
  net = new_5p1(varargin{:});
end

%================================================================
function net = new_5p1(p,t,s,d,tf,btf,blf,pf,ipf,tpf,ddf)

if nargin < 2, error('NNET:Arguments','Not enough arguments.'), end

% Defaults
if (nargin < 3), s = []; end
if (nargin < 4), d = {}; end
if (nargin < 5), tf = {}; end
if (nargin < 6), btf = 'trainlm'; end
if (nargin < 7), blf = 'learngdm'; end
if (nargin < 8), pf = 'mse'; end
if (nargin < 9), ipf = {'fixunknowns','removeconstantrows','mapminmax'}; end
if (nargin < 10), tpf = {'removeconstantrows','mapminmax'}; end
if (nargin < 11), ddf = 'dividerand'; end

% Format
if isa(p,'cell'), p = cell2mat(p); end
if isa(t,'cell'), t = cell2mat(t); end

% Error checking
if (~isa(p,'double')) || ~isreal(p)
  error('NNET:Arguments','Inputs are not a matrix or cell array with a single matrix.')
end
if isa(d,'cell')
  if (size(d,1) > 1)
    error('NNET:Arguments','Delay is not a cell row vector of delay vectors.')
  end
  for i=1:length(d)
    id = d{i};
    if (~isa(id,'double')) || ~isreal(id) || (size(id,1) ~= 1) || any(id ~= round(id)) || any(diff(id) <= 0)
      error('NNET:Arguments','Input delays is not a row vector of increasing zero or positive integers.');
    end
  end
else
  error('NNET:Arguments','Delay is not a cell array.')
end

if isa(s,'cell')
  if (size(s,1) ~= 1)
    error('NNET:Arguments','Layer sizes is not a row vector of positive integers.')
  end
  for i=1:length(s)
    si = s{i};
    if ~isa(si,'double') || ~isreal(si) || any(size(si) ~= 1) || any(si<1) || any(round(si) ~= si)
      error('NNET:Arguments','Layer sizes is not a row vector of positive integers.')
    end
  end
  s = cell2mat(s);
end
if (~isa(s,'double')) || ~isreal(s) || (size(s,1) ~= 1) || any(s<1) || any(round(s) ~= s)
  error('NNET:Arguments','Layer sizes is not a row vector of positive integers.')
end

% Architecture
Nl = length(s) + 1;
net = network(1,Nl);
net.biasConnect = ones(Nl,1);
net.inputConnect(1,1) = 1;
[j,i] = meshgrid(1:Nl,1:Nl);
net.layerConnect = (j == (i-1));
net.outputConnect(Nl) = 1;

% Simulation
net.inputs{1}.exampleInput = p;
net.inputs{1}.processFcns = ipf;
net.layers{1}.size = s(1);
if (length(tf) < 1) || any(isnan(tf{1}))
  net.layers{1}.transferFcn = 'tansig';
else
  net.layers{1}.transferFcn = tf{1};
end
if (length(d) < 1) || any(isnan(d{1}))
  net.inputWeights{1,1}.delays = 0:2;
else
  net.inputWeights{1,1}.delays = d{1};
end
for i=2:Nl
  if (i<Nl), net.layers{i}.size = s(i); end
  if (length(tf) < i) || any(isnan(tf{i}))
    if (i<Nl)
      net.layers{i}.transferFcn = 'tansig';
    else
      net.layers{i}.transferFcn = 'purelin';
    end
  else
    net.layers{i}.transferFcn = tf{1};
  end
  if (length(d) < i) || any(isnan(d{i}))
    net.layerWeights{i,i-1}.delays = 0:2;
  else
    net.layerWeights{i,i-1}.delays = d{i};
  end
end
net.outputs{Nl}.exampleOutput = t;
net.outputs{Nl}.processFcns = tpf;

% Adaption
net.adaptfcn = 'trains';
net.inputWeights{1,1}.learnFcn = blf;
for i=1:Nl
  net.biases{i}.learnFcn = blf;
  net.layerWeights{i,:}.learnFcn = blf;
end

% Training
net.trainfcn = btf;
net.dividefcn = ddf;
net.performFcn = pf;

% Initialization
net.initFcn = 'initlay';
for i=1:Nl
  net.layers{i}.initFcn = 'initnw';
end
net = init(net);

% Plots
net.plotFcns = {'plotperform','plottrainstate'};

%================================================================
function net = new_5p0(pr,d,s,tf,btf,blf,pf)
% Backward compatible to NNT 5.0

if nargin < 3, error('NNET:Arguments','Not enough arguments.'); end

% Defaults
if nargin < 4, s = 1; end
if nargin < 5, btf = 'trainlm'; end
if nargin < 6, blf = 'learngdm'; end
if nargin < 7, pf = 'mse'; end

% Error checking
if isa(pr,'cell') && all(size(pr)==[1 1]), pr = pr{1,1}; end
if (~isa(pr,'double')) | ~isreal(pr) | (size(pr,2) ~= 2)
  error('NNET:Arguments','Input ranges is not a two-column matrix, or cell array with a single two-column matrix.')
end
if any(pr(:,1) > pr(:,2))
  error('NNET:Arguments','Input ranges has values in the second column larger in the values in the same row of the first column.')
end
if isa(d,'cell')
  if (size(d,1) ~= 1)
    error('NNET:Arguments','Delay is not a cell row vector of delay vectors.')
  end
  for i=1:length(d)
    id = d{i};
    if (~isa(id,'double')) | ~isreal(id) | (size(id,1) ~= 1) | any(id ~= round(id)) | any(diff(id) <= 0)
      error('NNET:Arguments','Input delays is not a row vector of increasing zero or positive integers.');
    end
  end
else
  error('NNET:Arguments','Delay is not a cell array.')
end

if isa(s,'cell')
  if (size(s,1) ~= 1)
    error('NNET:Arguments','Layer sizes is not a row vector of positive integers.')
  end
  for i=1:length(s)
    si = s{i};
    if ~isa(si,'double') | ~isreal(si) | any(size(si) ~= 1) | any(si<1) | any(round(si) ~= si)
      error('NNET:Arguments','Layer sizes is not a row vector of positive integers.')
    end
  end
  s = cell2mat(s);
end
if (~isa(s,'double')) | ~isreal(s) | (size(s,1) ~= 1) | any(s<1) | any(round(s) ~= s)
  error('NNET:Arguments','Layer sizes is not a row vector of positive integers.')
end

% More defaults
Nl = length(s);
if nargin < 4, tf = {'tansig'}; tf = [tf(ones(1,Nl))]; end

% Architecture
net = network(1,Nl);
net.biasConnect = ones(Nl,1);
net.inputConnect(1,1) = 1;
[j,i] = meshgrid(1:Nl,1:Nl);
net.layerConnect = (j == (i-1));
net.outputConnect(Nl) = 1;

% Simulation
net.inputs{1}.range = pr;
net.inputWeights{1,1}.delays = d{1};
net.layers{i}.size = s(1);
net.layers{i}.transferFcn = tf{1};
if Nl>1
  for i=2:Nl
    net.layers{i}.size = s(i);
    net.layers{i}.transferFcn = tf{i};
    net.layerWeights{i,i-1}.delays = d{i};
  end
end
% Performance
net.performFcn = pf;

% Adaption
net.adaptfcn = 'trains';
net.inputWeights{1,1}.learnFcn = blf;
for i=1:Nl
  net.biases{i}.learnFcn = blf;
  net.layerWeights{i,:}.learnFcn = blf;
end

% Training
net.trainfcn = btf;

% Initialization
net.initFcn = 'initlay';
for i=1:Nl
  net.layers{i}.initFcn = 'initnw';
end
net = init(net);

% Plots
net.plotFcns = {'plotperform','plottrainstate'};
