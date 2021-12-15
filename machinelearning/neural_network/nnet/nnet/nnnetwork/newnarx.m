function net = newnarx(varargin)
%NEWNARX Create a feed-forward backpropagation network with feedback from output to input.
%
%  Syntax
%
%    net = newnarx(P,T,ID,OD,[S1...S(N-1)],{TF1...TFN},BTF,BLF,PF,IPF,OPF,DDF)
%
%  Description
%
%    NEWNARX(P,T,ID,OD,[S1...S(N-1)],{TF1...TFN},BTF,BLF,PF,IPF,OPF,DDF) takes,
%      P  - RxQ matrix of Q representative input vectors.
%      T  - SxQ matrix of Q representative target vectors.
%      ID  - Input delay vector, default = [0 1].
%      OD  - Output delay vector, default = [1 2].
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
%
%    Here a two-layer feed-forward network with a two-delay input
%    and two-delay feedback is created.  The hidden layer has 5 neurons.
%
%      net = newnarx(P,T,[0 1],[1 2],5);
%
%    Here the network is simulated and its output plotted against
%    the targets.
%
%       Y = sim(net,P);
%       plot(1:11,[T{:}],1:11,[Y{:}],'o')
%
%    Here the network is trained for 50 epochs.  Again the network's
%     output is plotted.
%
%      net = train(net,P,T);
%      Yf = sim(net,P);
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
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.7 $

if nargin < 2, error('NNET:Arguments','Not enough input arguments'), end

v1 = varargin{1};
if isa(v1,'cell'), v1 = cell2mat(v1); end
v2 = varargin{2};
if nargin > 4, v5 = varargin{5}; end

if (nargin<= 8) && (size(v1,2)==2) && (~iscell(v2)) && (size(v2,1)==1) && ((nargin<5)||iscell(v5))
  nntobsu(mfilename,['See help for ' upper(mfilename) ' to update calls to the new argument list.']);
  net = new_5p0(varargin{:});
else
  net = new_5p1(varargin{:});
end

%=============================================================
function net = new_5p1(p,t,id,od,s,tf,btf,blf,pf,ipf,tpf,ddf)

if nargin < 2, error('NNET:Arguments','Not enough arguments.'); end

% Defaults
if (nargin < 3), id = 0:1; end
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

% We create a feedforward NN before creating the feedback connection
net = newff(p,t,s,tf,btf,blf,pf,ipf,tpf,ddf);

% Feedback connection is made
Nl = length(s)+1;
net.layerConnect(1,Nl)=1;

% Delays are placed
net.inputWeights{1,1}.delays=id;
net.layerWeights{1,Nl}.delays=od;

% Weights are initialized
net = init(net);

% Plots
net.plotFcns = {'plotperform','plottrainstate'};
%================================================================
function net = new_5p0(pr,id,od,s,tf,btf,blf,pf)
% Backward compatible to NNT 5.0

if nargin < 2, error('NNET:Arguments','Not enough arguments.'); end

Nl = length(s);

% Defaults
if nargin < 5, tf = {'tansig'}; tf = [tf(ones(1,Nl))]; end
if nargin < 6, btf = 'trainlm'; end
if nargin < 7, blf = 'learngdm'; end
if nargin < 8, pf = 'mse'; end

% We create a feedforward NN before creating the feedback connection 
net = newff(pr,s,tf,btf,blf,pf);

% Feedback connection is made
net.layerConnect(1,Nl)=1;

% Delays are placed
net.layerWeights{1,Nl}.delays=od;
net.inputWeights{1,1}.delays=id;

% Weights are initialized
net = init(net);

% Plots
net.plotFcns = {'plotperform','plottrainstate'};
