function net=newc(p,s,klr,clr)
%NEWC Create a competitive layer.
%
%  Syntax
%
%   net = newc(P,S,KLR,CLR)
%
%  Description
%
%    Competitive layers are used to solve classification
%    problems.
%
%    NET = NEWC(P,S,KLR,CLR) takes these inputs,
%      P  - RxQ matrix of Q input vectors.
%      S  - Number of neurons.
%      KLR - Kohonen learning rate, default = 0.01.
%      CLR - Conscience learning rate, default = 0.001.
%    Returns a new competitive layer.
%
%  Examples
%
%    Here is a set of four two-element vectors P.
%
%      P = [.1 .8  .1 .9; .2 .9 .1 .8];
%
%    To competitive layer can be used to divide these inputs
%    into two classes.  First a two neuron layer is created
%    with two input elements ranging from 0 to 1, then it
%    is trained.
%
%      net = newc(P,2);
%      net = train(net,P);
%
%    The resulting network can then be simulated and its
%    output vectors converted to class indices.
%
%      Y = sim(net,P)
%      Yc = vec2ind(Y)
%
%  Properties
%
%    Competitive layers consist of a single layer with the NEGDIST
%    weight function, NETSUM net input function, and the COMPET
%    transfer function.
%
%    The layer has a weight from the input, and a bias.
%
%    Weights and biases are initialized with MIDPOINT and INITCON.
%
%    Adaption and training are done with TRAINS and TRAINR,
%    which both update weight and bias values with the LEARNK
%    and LEARNCON learning functions.
%
%  See also SIM, INIT, ADAPT, TRAIN, TRAINS, TRAINR.

% Mark Beale, 11-31-97
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.7 $ $Date: 2008/01/10 21:11:29 $

if nargin < 2, error('NNET:Arguments','Not enough arguments.'); end

% Defaults
if nargin < 2, s = 20; end
if nargin < 3, klr = 0.01; end
if nargin < 4, clr = 0.001; end

% Format
if isa(p,'cell') && (size(p,1)==1), p = cell2mat(p); end

% Error Checking
if (~isa(p,'double')) || ~isreal(p)
  error('NNET:Arguments','Inputs are not a matrix or cell array with a single matrix.')
end
if (~isa(s,'double')) || ~isreal(s) || any(size(s) ~= 1) || (s<1) || (round(s) ~= s)
  error('NNET:Arguments','Number of neurons is not a positive integer.')
end
if (~isa(klr,'double')) || any(size(klr) ~= 1) || (klr < 0) || (klr > 1)
  error('NNET:Arguments','Kohonen learning rate is not a real value between 0.0 and 1.0.');
end
if (~isa(clr,'double')) || any(size(clr) ~= 1) || (clr < 0) || (clr > 1)
  error('NNET:Arguments','Conscience learning rate is not a real value between 0.0 and 1.0.');
end
if (clr > klr)
  error('NNET:Arguments','Conscience learning rate is greater than the Kohonen learning rate.');
end

% Architecture
net = network(1,1,1,1,0,1);

% Simulation
net.inputs{1}.exampleInput = p;
net.layers{1}.size = s;
net.inputWeights{1,1}.weightFcn = 'negdist';
net.layers{1}.transferFcn = 'compet';

% Learning
net.inputWeights{1,1}.learnFcn = 'learnk';
net.inputWeights{1,1}.learnParam.lr = klr;
net.biases{1}.learnFcn = 'learncon';
net.biases{1}.learnParam.lr = clr;

% Adaption
net.adaptFcn = 'trains';

% Training
net.trainFcn = 'trainr';

% Initialization
net.initFcn = 'initlay';
net.layers{1}.initFcn = 'initwb';
net.biases{1}.initFcn = 'initcon';
net.inputWeights{1,1}.initFcn = 'midpoint';
net = init(net);

