function net = newnarxsp(varargin)
%NEWNARXSP Create an NARX network in series-parallel arrangement.
%
%  Syntax
%
%    net = newnarxsp(P,T,ID,OD,[S1 S2...SNl],{TF1 TF2...TFNl},BTF,BLF,PF,IPF,OPF,DDF)
%
%  Description
%
%    NEWNARXSP(P,T,ID,OD,[S1 S2...SNl],{TF1 TF2...TFNl},BTF,BLF,PF,IPF,OPF,DDF) takes,
%      P  - RxQ matrix of Q representative input vectors.
%      T  - SxQ matrix of Q representative target vectors.
%      ID  - Input delay vector.
%      OD  - Output delay vector.
%      Si  - Sizes of N-1 hidden layers, S1 to S(N-1), default = [].
%            (Output layer size SN is determined from T.)
%      TFi - Transfer function of ith layer. Default is 'tansig' for
%            hidden layers, and 'purelin' for output layer.
%      BTF - Backprop network training function, default = 'trainlm'.
%      BLF - Backprop weight/bias learning function, default = 'learngdm'.
%      PF  - Performance function, default = 'mse'.
%      IPF - Row cell array of input processing functions.
%            Default is {'remconstantrows','mapminmax'}.
%      OPF - Row cell array of output processing functions.
%            Default is {'remconstantrows','mapminmax'}.
%      DDF - Data division function, default = 'dividerand';
%    and returns an N layer feed-forward backprop network with external feedback.
%
%    The transfer functions TFi can be any differentiable transfer
%    function such as TANSIG, LOGSIG, or PURELIN.
%
%    The d delays from output to input FBD must be integer values greater than
%    zero placed in a row vector.
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
%    Here is a problem consisting of sequences of inputs P and targets T
%    that we would like to solve with a network.
%
%      P = {[0] [1] [1] [0] [-1] [-1] [0] [1] [1] [0] [-1]};
%      T = {[0] [1] [2] [2]  [1]  [0] [1] [2] [1] [0]  [1]};
%      PT = [P; T];
%      
%    Here a two-layer feed-forward network with a two-delay input
%    and two-delay feedback is created. The hidden layer has five neurons.
%
%      net = newnarxsp(P,T,[1 2],[1 2],5);
%
%    Here the network is simulated and its output plotted against
%    the targets.
%
%       Y = sim(net,PT);
%       plot(1:11,[T{:}],1:11,[Y{:}],'o')
%
%    Here the network is trained for 50 epochs.  Again the network's
%     output is plotted.
%
%      net = train(net,PT,T);
%      Yf = sim(net,PT);
%      plot(1:11,[T{:}],1:11,[Y{:}],'o',1:11,[Yf{:}],'+')
%
%  Algorithm
%
%    Feed-forward networks consist of Nl layers using the DOTPROD
%    weight function, NETSUM net input function, and the specified
%    transfer functions.
%
%    The first layer has weights coming from the input.  Each subsequent
%    layer has a weight coming from the previous layer.  All layers
%    have biases.  The last layer is the network output.
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
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.9 $

if nargin < 2, error('NNET:Arguments','Not enough input arguments'), end

v1 = varargin{1};
if (nargin<=8) && iscell(v1) && all(size(v1)==[1 2]) && (size(v1{1},2)==2) && (size(v1{2},2)==2)
  nntobsu(mfilename,['See help for ' upper(mfilename) ' to update calls to the new argument list.']);
  net = new_5p0(varargin{:});
else
  net = new_5p1(varargin{:});
end

% Plots
net.plotFcns = {'plotperform','plottrainstate'};

%=============================================================
function net = new_5p1(p,t,id,od,s,tf,btf,blf,pf,ipf,tpf,ddf)

if nargin < 2, error('NNET:Arguments','Not enough arguments.'); end

% Defaults
if (nargin < 3), id = 0:2; end
if (nargin < 4), od = 1:2; end
if (nargin < 5), s = []; end
if (nargin < 6), tf = {}; end
if (nargin < 7), btf = 'trainlm'; end
if (nargin < 8), blf = 'learngdm'; end
if (nargin < 9), pf = 'mse'; end
if (nargin < 10), ipf = {'removeconstantrows','mapminmax'}; end
if (nargin < 11), tpf = {'removeconstantrows','mapminmax'}; end
if (nargin < 12), ddf = 'dividerand'; end

% Format
if isa(p,'cell'), p = cell2mat(p); end
if isa(t,'cell'), t = cell2mat(t); end

% We create a feedforward NN before creating the second input connection
net = newff(p,t,s,tf,btf,blf,pf,ipf,tpf,ddf);

% Add the second input
Nl = length(s)+1;
net.numInputs=2;
net.inputConnect(1,2) = 1;
net.inputs{2}.exampleInput = t;
net.inputs{2}.processFcns = tpf;

% Delays are placed
net.inputWeights{1,1}.delays=id;
net.inputWeights{1,2}.delays=od;

% Weights are initialized
net = init(net);

%================================================================
function net = new_5p0(pr,id,od,s,tf,btf,blf,pf)
% Backward compatible to NNT 5.0

Nl = length(s);

% Defaults
if nargin < 5, tf = {'tansig'}; tf = [tf(ones(1,Nl))]; end
if nargin < 6, btf = 'trainlm'; end
if nargin < 7, blf = 'learngdm'; end
if nargin < 8, pf = 'mse'; end

% We create a feedforward NN before creating the second input connection
net = newff(pr{1},s,tf,btf,blf,pf);

% Add the second input
net.numInputs=2;
net.inputConnect(1,2) = 1;
net.inputs{2}.range = pr{2};

% Delays are placed
net.inputWeights{1,1}.delays=id;
net.inputWeights{1,2}.delays=od;

% Weights are initialized
net = init(net);

% Plots
net.plotFcns = {'plotperform','plottrainstate'};