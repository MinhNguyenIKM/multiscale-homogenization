function [net,tr]=newrb(p,t,goal,spread,mn,df)
%NEWRB Design a radial basis network.
%
%  Synopsis
%
%    [net,tr] = newrb(P,T,GOAL,SPREAD,MN,DF)
%
%  Description
%
%    Radial basis networks can be used to approximate
%    functions.  NEWRB adds neurons to the hidden
%    layer of a radial basis network until it meets
%    the specified mean squared error goal.
%
%   NEWRB(P,T,GOAL,SPREAD,MN,DF) takes these arguments,
%     P      - RxQ matrix of Q input vectors.
%     T      - SxQ matrix of Q target class vectors.
%     GOAL   - Mean squared error goal, default = 0.0.
%     SPREAD - Spread of radial basis functions, default = 1.0.
%     MN     - Maximum number of neurons, default is Q.
%     DF     - Number of neurons to add between displays, default = 25.
%   and returns a new radial basis network.
%
%   The larger that SPREAD is the smoother the function approximation
%   will be.  Too large a spread means a lot of neurons will be
%   required to fit a fast changing function.  Too small a spread
%   means many neurons will be required to fit a smooth function,
%   and the network may not generalize well.  Call NEWRB with
%   different spreads to find the best value for a given problem.
%
%  Examples
%
%    Here we design a radial basis network given inputs P
%    and targets T.
%
%      P = [1 2 3];
%      T = [2.0 4.1 5.9];
%      net = newrb(P,T);
%
%    Here the network is simulated for a new input.
%
%      P = 1.5;
%      Y = sim(net,P)
%
%  Algorithm
%
%    NEWRB creates a two layer network. The first layer has RADBAS
%    neurons, and calculates its weighted inputs with DIST, and
%    its net input with NETPROD.  The second layer has PURELIN neurons,
%    calculates its weighted input with DOTPROD and its net inputs with
%    NETSUM. Both layers have biases.
%
%    Initially the RADBAS layer has no neurons.  The following steps
%    are repeated until the network's mean squared error falls below GOAL
%   or the maximum number of neurons are reached:
%    1) The network is simulated
%    2) The input vector with the greatest error is found
%    3) A RADBAS neuron is added with weights equal to that vector.
%    4) The PURELIN layer weights are redesigned to minimize error.
%
%  See also SIM, NEWRBE, NEWGRNN, NEWPNN.

% Mark Beale, 11-31-97
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.6 $ $Date: 2007/11/09 20:51:06 $

if nargin < 2, error('NNET:Arguments','Not enough input arguments'), end

% Defaults
if nargin < 3, goal = 0; end
if nargin < 4, spread = 1; end
if nargin < 6, df = 25; end

% Format
if isa(p,'cell'), p = cell2mat(p); end
if isa(t,'cell'), t = cell2mat(t); end

% Error checks
if (~isa(p,'double')) | (~isreal(p)) | (length(p) == 0)
  error('NNET:Arguments','Inputs are not a non-empty real matrix.')
end
if (~isa(t,'double')) | (~isreal(t)) | (length(t) == 0)
  error('NNET:Arguments','Targets are not a non-empty real matrix.')
end
if (size(p,2) ~= size(t,2))
  error('NNET:Arguments','Inputs and Targets have different numbers of columns.')
end
if (~isa(goal,'double')) | ~isreal(goal) | any(size(goal) ~= 1) | (goal < 0)
  error('NNET:Arguments','Performance goal is not a positive or zero real value.')
end
if (~isa(spread,'double')) | ~isreal(spread) | any(size(spread) ~= 1) | (spread < 0)
  error('NNET:Arguments','Spread is not a positive or zero real value.')
end
if (~isa(df,'double')) | ~isreal(df) | any(size(df) ~= 1) | (df < 1) | (round(df) ~= df)
  error('NNET:Arguments','Display frequency is not a positive integer.')
end

% More defaults
Q = size(p,2);
if nargin < 5, mn = Q; end

% More error checking
if (~isa(mn,'double')) | ~isreal(mn) | any(size(mn) ~= 1) | (mn < 1) | (round(mn) ~= mn)
  error('NNET:Arguments','Maximum neurons is not a positive integer.')
end


% Dimensions
R = size(p,1);
S2 = size(t,1);

% Architecture
net = network(1,2,[1;1],[1; 0],[0 0;1 0],[0 1]);

% Simulation
net.inputs{1}.size = R;
net.layers{1}.size = 0;
net.inputWeights{1,1}.weightFcn = 'dist';
net.layers{1}.netInputFcn = 'netprod';
net.layers{1}.transferFcn = 'radbas';
net.layers{2}.size = S2;
net.outputs{2}.exampleOutput = t;

% Performance
net.performFcn = 'mse';

% Design Weights and Bias Values
warn1 = warning('off','MATLAB:rankDeficientMatrix');
warn2 = warning('off','MATLAB:nearlySingularMatrix');
[w1,b1,w2,b2,tr] = designrb(p,t,goal,spread,mn,df);
warning(warn1.state,warn1.identifier);
warning(warn2.state,warn2.identifier);

net.layers{1}.size = length(b1);
net.b{1} = b1;
net.iw{1,1} = w1;
net.b{2} = b2;
net.lw{2,1} = w2;

%======================================================
function [w1,b1,w2,b2,tr] = designrb(p,t,eg,sp,mn,df)

[r,q] = size(p);
[s2,q] = size(t);
b = sqrt(-log(.5))/sp;

% RADIAL BASIS LAYER OUTPUTS
P = radbas(dist(p',p)*b);
PP = sum(P.*P)';
d = t';
dd = sum(d.*d)';

% CALCULATE "ERRORS" ASSOCIATED WITH VECTORS
e = ((P' * d)' .^ 2) ./ (dd * PP');

% PICK VECTOR WITH MOST "ERROR"
pick = findLargeColumn(e);
used = [];
left = 1:q;
W = P(:,pick);
P(:,pick) = []; PP(pick,:) = [];
e(:,pick) = [];
used = [used left(pick)];
left(pick) = [];

% CALCULATE ACTUAL ERROR
w1 = p(:,used)';
a1 = radbas(dist(w1,p)*b);
[w2,b2] = solvelin2(a1,t);
a2 = w2*a1 + b2*ones(1,q);
MSE = mse(t-a2);

% Start
tr = newtr(mn,'perf');
tr.perf(1) = mse(t-repmat(mean(t,2),1,q));
tr.perf(2) = MSE;
if isfinite(df)
  fprintf('NEWRB, neurons = 0, MSE = %g\n',tr.perf(1));
end
flag_stop = 0;

iterations = min(mn,q);
for k = 2:iterations
  
  % CALCULATE "ERRORS" ASSOCIATED WITH VECTORS
  wj = W(:,k-1);
  a = wj' * P / (wj'*wj);
  P = P - wj * a;
  PP = sum(P.*P)';
  e = ((P' * d)' .^ 2) ./ (dd * PP');

  % PICK VECTOR WITH MOST "ERROR"
  pick = findLargeColumn(e);
  W = [W, P(:,pick)];
  P(:,pick) = []; PP(pick,:) = [];
  e(:,pick) = [];
  used = [used left(pick)];
  left(pick) = [];

  % CALCULATE ACTUAL ERROR
  w1 = p(:,used)';
  a1 = radbas(dist(w1,p)*b);
  [w2,b2] = solvelin2(a1,t);
  a2 = w2*a1 + b2*ones(1,q);
  MSE = mse(t-a2);
  
  % PROGRESS
  tr.perf(k+1) = MSE;
  
  % DISPLAY
  if isfinite(df) & (~rem(k,df))
    fprintf('NEWRB, neurons = %g, MSE = %g\n',k,MSE);
    flag_stop=plotperf(tr,eg,'NEWRB',k);
  end
  
  % CHECK ERROR
  if (MSE < eg), break, end
  if (flag_stop), break, end

end

[S1,R] = size(w1);
b1 = ones(S1,1)*b;

% Finish
tr = cliptr(tr,k);

%======================================================
function i = findLargeColumn(m)

replace = find(isnan(m));
m(replace) = zeros(size(replace));

m = sum(m .^ 2,1);
i = find(m == max(m));
i = i(1);

%======================================================

function [w,b] = solvelin2(p,t)

if nargout <= 1
  w= t/p;
else
  [pr,pc] = size(p);
  x = t/[p; ones(1,pc)];
  w = x(:,1:pr);
  b = x(:,pr+1);
end

%======================================================
