function net=newp(varargin)
%NEWP Create a perceptron.
%
%  Syntax
%
%    net = newp(p,t,tf,lf)
%
%  Description
%
%    Perceptrons are used to solve simple (i.e. linearly
%    separable) classification problems.
%
%    NET = NEWP(P,T,TF,LF) takes these inputs,
%      P  - RxQ matrix of Q1 representative input vectors.
%      T  - SxQ matrix of Q2 representative target vectors.
%      TF - Transfer function, default = 'hardlim'.
%      LF - Learning function, default = 'learnp'.
%    Returns a new perceptron.
%
%    The transfer function TF can be HARDLIM or HARDLIMS.
%    The learning function LF can be LEARNP or LEARNPN.
%
%  Examples
%
%    This code creates a perceptron layer with one 2-element
%    input (ranges [0 1] and [-2 2]) and one neuron. (Supplying
%    only two arguments to NEWP results in the default perceptron
%    learning function LEARNP being used.)
%
%      net = newp([0 1; -2 2],1);
%
%    Now we define a problem, an OR gate, with a set of four
%    2-element input vectors  P and the corresponding four
%    1-element targets T.
%
%      P = [0 0 1 1; 0 1 0 1];
%      T = [0 1 1 1];
%
%    Here we simulate the network's output, train for a
%    maximum of 20 epochs, and then simulate it again.
%
%      Y = sim(net,P)
%      net.trainParam.epochs = 20;
%      net = train(net,P,T);
%      Y = sim(net,P)
%
%  Notes
%
%    Perceptrons can classify linearly separable classes in a
%    finite amount of time. If input vectors have a large variance
%    in their lengths, the LEARNPN can be faster than LEARNP.
%
%  Properties
%
%    Perceptrons consist of a single layer with the DOTPROD
%    weight function, the NETSUM net input function, and the specified
%    transfer function.
%
%    The layer has a weight from the input and a bias.
%
%    Weights and biases are initialized with INITZERO.
%
%    Adaption and training are done with TRAINS and TRAINC,
%    which both update weight and bias values with the specified
%    learning function.  Performance is measured with MAE.
%
%  See also SIM, INIT, ADAPT, TRAIN, HARDLIM, HARDLIMS, LEARNP, LEARNPN, TRAINB, TRAINS.

% Mark Beale, 11-31-97
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.7 $ $Date: 2008/01/10 21:11:40 $

if nargin < 1, error('NNET:Arguments','Not enough input arguments'); end

v2 = varargin{2};

if (~iscell(v2)) && (numel(v2)==1)
  net = new_5p1_size(varargin{:});
else
  net = new_5p1_targets(varargin{:});
end

%=============================================================
function net = new_5p1_targets(p,t,tf,lf,ipf,tpf,ddf)

if nargin < 2, error('NNET:Arguments','Not enough input arguments'), end

% Defaults
if (nargin < 3), tf = 'hardlim'; end
if (nargin < 2), t = feval(tf,'output'); end
if (nargin < 4), lf = 'learnp'; end
if (nargin < 5), ipf = {}; end
if (nargin < 6), tpf = {}; end
if (nargin < 7), ddf = ''; end

% Format
if isa(p,'cell'), p = cell2mat(p); end
if isa(t,'cell'), t = cell2mat(t); end

% Error Checking
if (~isa(p,'double')) || ~isreal(p)
  error('NNET:Arguments','Inputs are not a matrix or cell array with a single matrix.')
end
if (~isa(t,'double')) || ~isreal(t)
  error('NNET:Arguments','Targets are not a matrix or cell array with a single matrix.')
end

% Architecture
net = network(1,1,1,1,0,1);

% Simulation
net.inputs{1}.exampleInput = p;
net.inputs{1}.processFcns = ipf;
net.layers{1}.transferFcn = tf;
net.outputs{1}.exampleOutput = t;
net.outputs{1}.processFcns = tpf;

% Learning (Adaption and Training)
net.inputWeights{1,1}.learnFcn = lf;
net.biases{1}.learnFcn = lf;

% Adaption
net.adaptFcn = 'trains';

% Training
net.trainFcn = 'trainc';
net.divideFcn = ddf;
net.performFcn = 'mae';

% Initialization
net.initFcn = 'initlay';
net.layers{1}.initFcn = 'initwb';
net.biases{1}.initFcn = 'initzero';
net.inputWeights{1,1}.initFcn = 'initzero';
net = init(net);

% Plots
net.plotFcns = {'plotperform','plottrainstate'};

%================================================================
function net = new_5p1_size(pr,s,TF,LF)
% Backward compatible to NNT 5.0

if nargin < 1, error('NNET:Arguments','Not enough input arguments'), end

% Defaults
if nargin < 2, s = 1; end
if nargin < 3, TF = 'hardlim'; end
if nargin < 4, LF = 'learnp'; end

% Error Checking
if (~isa(pr,'double')) || ~isreal(pr) || (size(pr,2) ~= 2)
  error('NNET:Arguments','Input ranges is not a two column matrix.')
end
if any(pr(:,1) > pr(:,2))
  error('NNET:Arguments','Input ranges has values in the second column larger in the values in the same row of the first column.')
end
if (~isa(s,'double')) || ~isreal(s) || any(size(s) ~= 1) || (s<1) || (round(s) ~= s)
  error('NNET:Arguments','Number of neurons is not a positive integer.')
end

% Architecture
net = network(1,1,1,1,0,1,1);

% Simulation
net.inputs{1}.range = pr;
net.layers{1}.size = s;
net.layers{1}.transferFcn = TF;

% Performance
net.performFcn = 'mae';

% Learning (Adaption and Training)
net.inputWeights{1,1}.learnFcn = LF;
net.biases{1}.learnFcn = LF;

% Adaption
net.adaptFcn = 'trains';

% Training
net.trainFcn = 'trainc';

% Initialization
net.initFcn = 'initlay';
net.layers{1}.initFcn = 'initwb';
net.biases{1}.initFcn = 'initzero';
net.inputWeights{1,1}.initFcn = 'initzero';
net = init(net);

% Plots
net.plotFcns = {'plotperform','plottrainstate'};
