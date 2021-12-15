function net = newcf(varargin)
%NEWCF Create a cascade-forward backpropagation network.
%
%  Syntax
%
%   net = newcf(P,T,[S1 S2...S(N-1)],{TF1 TF2...TFN},BTF,BLF,PF,IPF,OPF,DDF)
%
%  Description
%
%    NEWCF(P,T,[S1 S2...S(N-1)],{TF1 TF2...TFN},BTF,BLF,PF,IPF,OPF,DDF) takes,
%      P  - RxQ1 matrix of Q1 representative R-element input vectors.
%      T  - SNxQ2 matrix of Q2 representative SN-element target vectors.
%      Si  - Sizes of N-1 hidden layers, S1 to S(N-1), default = [].
%            (Output layer size SN is determined from T.)
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
%    and returns an N layer cascade-forward backprop network.
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
%    Here is a problem consisting of inputs P and targets T that we would
%    like to solve with a network.
%
%      P = [0 1 2 3 4 5 6 7 8 9 10];
%      T = [0 1 2 3 4 3 2 1 2 3 4];
%
%    Here a network is created with a hidden layer with 5 neurons.
%
%      net = newcf(P,T,5);
%
%    Here the network is simulated and its output plotted against
%    the targets.
%
%      Y = sim(net,P);
%       plot(P,T,P,Y,'o')
%
%    Here the network is trained for 50 epochs.  Again the network's
%     output is plotted.
%
%      net.trainParam.epochs = 50;
%      net = train(net,P,T);
%      Y = sim(net,P);
%      plot(P,T,P,Y,'o')
%
%  Algorithm
%
%    Cascade-forward networks consists of Nl layers using the DOTPROD
%    weight function, NETSUM net input function, and the specified
%    transfer functions.
%
%    The first layer has weights coming from the input.  Each subsequent
%    layer has weights coming from the input and all previous layers.
%    All layers have biases.  The last layer is the network output.
%
%    Each layer's weights and biases are initialized with INITNW.
%
%    Adaption is done with TRAINS which updates weights with the
%    specified learning function. Training is done with the specified
%    training function. Performance is measured according to the specified
%    performance function.
%
%  See also NEWFF, NEWELM, SIM, INIT, ADAPT, TRAIN, TRAINS

% Mark Beale, 11-31-97
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.7 $ $Date: 2008/01/10 21:11:30 $

if nargin < 2, error('NNET:Arguments','Not enough input arguments'), end

v1 = varargin{1};
if isa(v1,'cell'), v1 = cell2mat(v1); end
v2 = varargin{2};
if nargin > 2, v3 = varargin{3}; end

if (nargin<= 6) && (size(v1,2)==2) && (~iscell(v2)) && (size(v2,1)==1) && ((nargin<3)||iscell(v3))
  nntobsu(mfilename,['See help for ' upper(mfilename) ' to update calls to the new argument list.']);
  net = new_5p0(varargin{:});
else
  net = new_5p1(varargin{:});
end

%================================================================
function net = new_5p1(p,t,s,tf,btf,blf,pf,ipf,tpf,ddf)

if nargin < 2, error('NNET:Arguments','Not enough arguments.'), end

% Defaults
if (nargin < 3), s = {}; end
if (nargin < 4), tf = {}; end
if (nargin < 5), btf = 'trainlm'; end
if (nargin < 6), blf = 'learngdm'; end
if (nargin < 7), pf = 'mse'; end
if (nargin < 8), ipf = {'fixunknowns','removeconstantrows','mapminmax'}; end
if (nargin < 9), tpf = {'removeconstantrows','mapminmax'}; end
if (nargin < 10), ddf = 'dividerand'; end

% Format
if isa(p,'cell'), p = cell2mat(p); end
if isa(t,'cell'), t = cell2mat(t); end

% Error checking
if (~isa(p,'double')) || ~isreal(p)
  error('NNET:Arguments','Inputs are not a matrix or cell array with a single matrix.')
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
Nl = length(s)+1;
net = network(1,Nl);
net.biasConnect = ones(Nl,1);
net.inputConnect = ones(Nl,1);
[j,i] = meshgrid(1:Nl,1:Nl);
net.layerConnect = (j < i);
net.outputConnect(Nl) = 1;

% Simulation
net.inputs{1}.exampleInput = p;
net.inputs{1}.processFcns = ipf;
for i=1:Nl
  if (i < Nl)
    net.layers{i}.size = s(i);
    if (Nl == 2)
      net.layers{i}.name = 'Hidden Layer';
    else
      net.layers{i}.name = ['Hidden Layer ' num2str(i)];
    end
  else
    net.layers{i}.name = 'Output Layer';
  end
  if (length(tf) < i) || all(isnan(tf{i}))
    if (i<Nl)
      net.layers{i}.transferFcn = 'tansig';
    else
      net.layers{i}.transferFcn = 'purelin';
    end
  else
    net.layers{i}.transferFcn = tf{i};
  end
end
net.outputs{Nl}.exampleOutput = t;
net.outputs{Nl}.processFcns = tpf;

% Adaption
net.adaptfcn = 'trains';
net.inputWeights{:,:}.learnFcn = blf;
net.biases{:}.learnFcn = blf;
net.layerWeights{:,:}.learnFcn = blf;

% Training
net.trainfcn = btf;
net.dividefcn = ddf;
net.performFcn = pf;

% Initialize
net.initFcn = 'initlay';
for i=1:Nl
  net.layers{i}.initFcn = 'initnw';
end
net = init(net);

% Plots
net.plotFcns = {'plotperform','plottrainstate','plotregression'};

%================================================================
function net = new_5p0(pr,s,tf,btf,blf,pf)
% Backward compatible to NNT 5.0

if nargin < 2, error('NNET:Arguments','Not enough arguments.'), end

% Defaults
Nl = length(s);
if nargin < 3, tf = {'tansig'}; tf = tf(ones(1,Nl)); end
if nargin < 4, btf = 'trainlm'; end
if nargin < 5, blf = 'learngdm'; end
if nargin < 6, pf = 'mse'; end

% Error checking
if (~isa(pr,'double')) | ~isreal(pr) | (size(pr,2) ~= 2)
  error('NNET:Arguments','Input ranges is not a two column matrix.')
end
if any(pr(:,1) > pr(:,2))
  error('NNET:Arguments','Input ranges has values in the second column larger in the values in the same row of the first column.')
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
net = network(1,Nl);
net.biasConnect = ones(Nl,1);
net.inputConnect = ones(Nl,1);
[j,i] = meshgrid(1:Nl,1:Nl);
net.layerConnect = (j < i);
net.outputConnect(Nl) = 1;

% Simulation
net.inputs{1}.range = pr;
for i=1:Nl
  net.layers{i}.size = s(i);
  net.layers{i}.transferFcn = tf{i};
end

% Performance
net.performFcn = pf;

% Adaption
net.adaptfcn = 'trains';
net.inputWeights{:,:}.learnFcn = blf;
net.biases{:}.learnFcn = blf;
net.layerWeights{:,:}.learnFcn = blf;

% Training
net.trainfcn = btf;
net.performFcn = pf;

% Initialize
net.initFcn = 'initlay';
for i=1:Nl
  net.layers{i}.initFcn = 'initnw';
end
net = init(net);

% Plots
net.plotFcns = {'plotperform','plottrainstate','plotregression'};
