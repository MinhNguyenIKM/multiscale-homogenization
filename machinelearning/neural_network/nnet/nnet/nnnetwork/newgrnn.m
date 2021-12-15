function net=newgrnn(p,t,spread)
%NEWGRNN Design a generalized regression neural network.
%
%  Synopsis
%
%    net = newgrnn(P,T,SPREAD)
%
%  Description
%
%    Generalized regression neural networks are a kind
%    of radial basis network that is often used for function
%    approximation.  GRNNs can be designed very quickly.
%
%    NEWGRNN(P,T,SPREAD) takes these inputs,
%      P      - RxQ1 matrix of Q1 input vectors.
%      T      - SxQ2 matrix of Q2 target class vectors.
%      SPREAD - Spread of radial basis functions, default = 1.0.
%    and returns a new generalized regression neural network.
%
%    The larger SPREAD is, the smoother the function approximation
%    will be.  To fit data closely, use a SPREAD smaller than the
%    typical distance between input vectors.  To fit the data more
%    smoothly use a larger SPREAD.
%
%  Examples
%
%    Here we design a radial basis network given inputs P
%    and targets T.
%
%      P = [1 2 3];
%      T = [2.0 4.1 5.9];
%      net = newgrnn(P,T);
%
%    Here the network is simulated for a new input.
%
%      P = 1.5;
%      Y = sim(net,P)
%
%  Properties
%
%    NEWGRNN creates a two layer network. The first layer has
%    has RADBAS neurons, calculates weighted inputs with DIST and
%    net input with NETPROD.  The second layer has PURELIN neurons,
%    calculates weighted input with NORMPROD and net inputs with NETSUM.
%    Only the first layer has biases.
%
%    NEWGRNN sets the first layer weights to P', and the first
%    layer biases are all set to 0.8326/SPREAD, resulting in
%    radial basis functions that cross 0.5 at weighted inputs
%    of +/- SPREAD. The second layer weights W2 are set to T.
%
%  References:
%
%    P.D. Wasserman, Advanced Methods in Neural Computing, New York:
%      Van Nostrand Reinhold, pp. 155-61, 1993.
%
%  See also SIM, NEWRB, NEWGRNN, NEWPNN.

% Mark Beale, 11-31-97
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.6 $ $Date: 2007/11/09 20:50:49 $

if nargin < 2, error('NNET:Arguments','Not enough input arguments'); end

% Defaults
if nargin < 3, spread = 1; end

% Format
if isa(p,'cell'), p = cell2mat(p); end
if isa(t,'cell'), t = cell2mat(t); end

% Error checks
if (~isa(p,'double')) || (~isreal(p)) || isempty(p)
  error('NNET:Arguments','Inputs are not a non-empty real matrix.')
end
if (~isa(t,'double')) || (~isreal(t)) || isempty(t)
  error('NNET:Arguments','Targets are not a non-empty real matrix.')
end
if (size(p,2) ~= size(t,2))
  error('NNET:Arguments','Inputs and Targets have different numbers of columns.')
end
if (~isa(spread,'double')) || ~isreal(spread) || any(size(spread) ~= 1) || (spread < 0)
  error('NNET:Arguments','Spread is not a positive or zero real value.')
end

% Dimensions
[R,Q] = size(p);
[S,Q] = size(t);

% Architecture
net = network(1,2,[1;0],[1;0],[0 0;1 0],[0 1]);

% Simulation
net.inputs{1}.size = R;
net.layers{1}.size = Q;
net.inputWeights{1,1}.weightFcn = 'dist';
net.layers{1}.netInputFcn = 'netprod';
net.layers{1}.transferFcn = 'radbas';
net.layers{2}.size = S;
net.layerWeights{2,1}.weightFcn = 'normprod';

% Weight and Bias Values
net.b{1} = zeros(Q,1)+sqrt(-log(.5))/spread;
net.iw{1,1} = p';
net.lw{2,1} = t;

