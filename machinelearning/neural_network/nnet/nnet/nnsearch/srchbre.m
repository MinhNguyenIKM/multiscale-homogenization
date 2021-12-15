function [a,gX, perf,retcode,delta,tol] = srchbre(net,X,Pd,Tl,Ai,Q,TS,dX,gX,perf,dperf,delta,tol,ch_perf)
%SRCHBRE One-dimensional interval location using Brent's method.
%
%  Syntax
%  
%    [a,gX,perf,retcode,delta,tol] = srchbre(net,X,Pd,Tl,Ai,Q,TS,dX,gX,perf,dperf,delta,tol,ch_perf)
%
%  Description
%
%    SRCHBRE is a linear search routine.  It searches in a given direction
%     to locate the minimum of the performance function in that direction.
%     It uses a technique called Brent's method.
%
%  SRCHBRE(NET,X,Pd,Tl,Ai,Q,TS,dX,gX,PERF,DPERF,DELTA,TOL,CH_PERF) takes these inputs,
%      NET     - Neural network.
%      X       - Vector containing current values of weights and biases.
%      Pd      - Delayed input vectors.
%      Tl      - Layer target vectors.
%      Ai      - Initial input delay conditions.
%      Q       - Batch size.
%      TS      - Time steps.
%      dX      - Search direction vector.
%      gX      - Gradient vector.
%      PERF    - Performance value at current X.
%      DPERF   - Slope of performance value at current X in direction of dX.
%      DELTA   - Initial step size.
%      TOL     - Tolerance on search.
%      CH_PERF - Change in performance on previous step.
%    and returns,
%      A       - Step size which minimizes performance.
%      gX      - Gradient at new minimum point.
%      PERF    - Performance value at new minimum point.
%      RETCODE - Return code which has three elements. The first two elements correspond to
%                 the number of function evaluations in the two stages of the search
%                The third element is a return code. These will have different meanings
%                 for different search algorithms. Some may not be used in this function.
%                   0 - normal; 1 - minimum step taken; 2 - maximum step taken;
%                   3 - beta condition not met.
%      DELTA   - New initial step size. Based on the current step size.
%      TOL     - New tolerance on search.
%
%     Parameters used for the brent algorithm are:
%      alpha     - Scale factor which determines sufficient reduction in perf.
%      beta      - Scale factor which determines sufficiently large step size.
%      bmax      - Largest step size.
%      scale_tol - Parameter which relates the tolerance tol to the initial step
%                   size delta. Usually set to 20.
%     The defaults for these parameters are set in the training function which
%     calls it.  See TRAINCGF, TRAINCGB, TRAINCGP, TRAINBFG, TRAINOSS
%
%    Dimensions for these variables are:
%      Pd - NoxNixTS cell array, each element P{i,j,ts} is a DijxQ matrix.
%      Tl - NlxTS cell array, each element P{i,ts} is an VixQ matrix.
%    Ai - NlxLD cell array, each element Ai{i,k} is an SixQ matrix.
%    Where
%      Ni = net.numInputs
%    Nl = net.numLayers
%    LD = net.numLayerDelays
%      Ri = net.inputs{i}.size
%      Si = net.layers{i}.size
%      Vi = net.targets{i}.size
%      Dij = Ri * length(net.inputWeights{i,j}.delays)
%
%  Network Use
%
%    You can create a standard network that uses SRCHBRE with
%    NEWFF, NEWCF, or NEWELM.
%
%    To prepare a custom network to be trained with TRAINCGF and
%     to use the line search function SRCHBRE:
%    1) Set NET.trainFcn to 'traincgf'.
%       This will set NET.trainParam to TRAINCGF's default parameters.
%    2) Set NET.trainParam.searchFcn to 'srchbre'.
%
%    The SRCHBRE function can be used with any of the following
%     training functions: TRAINCGF, TRAINCGB, TRAINCGP, TRAINBFG, TRAINOSS.
%
%
%  Examples
%
%    Here is a problem consisting of inputs P and targets T that we would
%    like to solve with a network.
%
%      p = [0 1 2 3 4 5];
%      t = [0 0 0 1 1 1];
%
%    Here a two-layer feed-forward network is created.  The network's
%    input ranges from [0 to 10].  The first layer has two TANSIG
%    neurons, and the second layer has one LOGSIG neuron.  The TRAINCGF
%     network training function and the SRCHBRE search function are to be used.
%
%      % Create and Test a Network
%      net = newff([0 5],[2 1],{'tansig','logsig'},'traincgf');
%      a = sim(net,p)
%
%      % Train and Retest the Network
%       net.trainParam.searchFcn = 'srchbre';
%      net.trainParam.epochs = 50;
%      net.trainParam.show = 10;
%      net.trainParam.goal = 0.1;
%      net = train(net,p,t);
%      a = sim(net,p)
%
%
%  Algorithm
%
%    SRCHBRE brackets the minimum of the performance function in
%    the search direction dX, using Brent's
%    algorithm described on page 46 of Scales (Introduction to 
%     Non-Linear Estimation 1985). It is a hybrid algorithm based on 
%     the golden section search and quadratic approximation.
%
%  See also SRCHBAC, SRCHCHA, SRCHGOL, SRCHHYB
%
%   References
%
%     Brent, Introduction to Non-Linear Estimation, 1985.

% Copyright 1992-2007 The MathWorks, Inc.
% Updated by Orlando De Jesús, Martin Hagan, 7-20-05
% $Revision: 1.1.6.6 $ $Date: 2007/11/09 20:52:21 $

if (nargin < 1), error('NNET:Arguments','Not enough arguments.'); end
if ischar(net)
  switch(net)
    case 'name'
      a = 'One-Dimensional Interval Location w-Brent''s Method';
    otherwise, error('NNET:Arguments',['Unrecognized code: ''' net ''''])
  end
  return
end

% ALGORITHM PARAMETERS
scale_tol = net.trainParam.scale_tol;
alpha = net.trainParam.alpha;
beta = net.trainParam.beta;
bmax = net.trainParam.bmax;

% Parameter Checking
if (~isa(scale_tol,'double')) | (~isreal(scale_tol)) | (any(size(scale_tol)) ~= 1) | ...
  (scale_tol <= 0)
  error('NNET:Arguments','Scale_tol is not a positive real value.')
end
if (~isa(alpha,'double')) | (~isreal(alpha)) | (any(size(alpha)) ~= 1) | ...
  (alpha < 0) | (alpha > 1)
  error('NNET:Arguments','Alpha is not a real value between 0 and 1.')
end
if (~isa(beta,'double')) | (~isreal(beta)) | (any(size(beta)) ~= 1) | ...
  (beta < 0) | (beta > 1)
  error('NNET:Arguments','Beta is not a real value between 0 and 1.')
end
if (~isa(bmax,'double')) | (~isreal(bmax)) | (any(size(bmax)) ~= 1) | ...
  (bmax <= 0)
  error('NNET:Arguments','Bmax is not a positive real value.')
end

%INITIALIZE
perfa = perf;
a = 0;
u = 1e19;
perfu = 1e19;
cnt1 = 0;
cnt2 = 0;
lambda = delta;

% INTERVAL FOR GOLDEN SECTION SEARCH
tau = 0.618;
tau1 = 1 - tau;

% STEP SIZE INCREASE FACTOR FOR INTERVAL LOCATION (NORMALLY 2)
scale = 2;

% INITIALIZE A AND B
a = 0;
a_old = 0;

% We check influence of this condition on solution. FIND FIRST STEP SIZE
delta_star = abs(-2*ch_perf/dperf);
delta = max([delta delta_star]);

b = delta;
perfa = perf;
perfa_old = perfa;
  
% CALCLULATE PERFORMANCE FOR B
X_temp = X + b*dX;
net_temp = setx(net,X_temp);
[perfb,E,Ac,N,Zb,Zi,Zl] = calcperf(net_temp,X_temp,Pd,Tl,Ai,Q,TS);
cnt1 = cnt1 + 1;

% INTERVAL LOCATION
% FIND INITIAL INTERVAL WHERE MINIMUM PERF OCCURS
while (perfa>perfb)&(b<bmax)
  a_old=a;
  perfa_old=perfa;
  perfa=perfb;
  a=b;
  b=scale*b;
  X_temp = X + b*dX;
  net_temp = setx(net,X_temp);
  [perfb,E,Ac,N,Zb,Zi,Zl] = calcperf(net_temp,X_temp,Pd,Tl,Ai,Q,TS);
  cnt1 = cnt1 + 1;
end

% If perfb is NaN we return
if ~isnan(perfb)

  if (a == a_old)
    % GET INTERMEDIATE POINT IF NO MIDPOINT EXISTS
    % We check until perfv smaller than perfb
    perfv=perfb;
    v=b;
    while (perfv>=perfb) & (v==b) & ((b-a)>tol) % mth 6/5/05 add check for b-a
      v = a + tau1*(b - a);
      w = v;
      x = v;
      X_temp = X + v*dX;
      net_temp = setx(net,X_temp);
      [perfv,E,Ac,N,Zb,Zi,Zl] = calcperf(net_temp,X_temp,Pd,Tl,Ai,Q,TS);
      perfw = perfv;
      perfx = perfv;
      cnt1 = cnt1 + 1;
      % If greater we change b to v, 
      % except when there is a descent direction from a to v
      if perfv>=perfb & perfa<=perfv
         b=v;
         perfb=perfv;
      end
    end
  else
    % USE ALREADY COMPUTED VALUE AS INITIAL INTERMEDIATE POINT
    v = a;
    w = v;
    x = v;
    perfv = perfa;
    perfw = perfv;
    perfx = perfv;
    a=a_old;
    perfa=perfa_old;
  end

  max_int = w;
  min_int = w;

  % REDUCE THE INTERVAL
  while ((b-a)>tol) & (perfx >= perf + alpha*x*dperf)

    % QUADRATIC INTERPOLATION
    if (w~=x)&(w~=v)&(x~=v)&( (max_int - min_int) > 0.02*(b-a) )
      [zz,i] = sort([v w x]);
      pp = [perfv perfw perfx];
      pp = pp(i);
      num = (zz(3)^2 - zz(2)^2)*pp(1) + (zz(2)^2 - zz(1)^2)*pp(3) + (zz(1)^2 - zz(3)^2)*pp(2);
      den = (zz(3) - zz(2))*pp(1) + (zz(2) - zz(1))*pp(3) + (zz(1) - zz(3))*pp(2); 
      % Change to avoid division by zero
      if den==0
        break; %We finish program.
      else
        x_star = 0.5*num/den;
        if (x_star < b)&(a < x_star)
          u = x_star;
          gold_sec = 0;
        else
          gold_sec = 1;
        end
      end
    else
      gold_sec = 1;
    end

    % GOLDEN SECTION 
    if (gold_sec == 1)
      if (x >= (a + b)/2);
        u = x - tau1*(x - a);
      else
        u = x + tau1*(b - x);
      end
    end

    X_temp = X + u*dX;
    net_temp = setx(net,X_temp);
    [perfu,E,Ac,N,Zb,Zi,Zl] = calcperf(net_temp,X_temp,Pd,Tl,Ai,Q,TS);
    cnt2 = cnt2 + 1;

    % UPDATE POINTS
    if (perfu <= perfx)
      if (u < x)
        b = x;
        perfb = perfx;
      else
        % If perfx smaller than perfa we are OK
        if perfa >= perfu
          a = x;
          perfa = perfx;
        else   % Otherwise we must move b to x.
          b = x;
          perfb = perfx;
          % We must GET INTERMEDIATE POINT IF NO MIDPOINT EXISTS
          v = a + tau1*(b - a);
          w = v;
          x = v;
          X_temp = X + v*dX;
          net_temp = setx(net,X_temp);
          [perfv,E,Ac,N,Zb,Zi,Zl] = calcperf(net_temp,X_temp,Pd,Tl,Ai,Q,TS);
          perfw = perfv;
          perfx = perfv;
          cnt1 = cnt1 + 1;
        end      
      end

      v = w; perfv = perfw;
      w = x; perfw = perfx;
      x = u; perfx = perfu;
    else
      if (u < x)
        % If perfu smaller than perfa we are OK
        if perfa >= perfu
          a = u;
          perfa = perfu;
        else   % Otherwise we must move b to u.
          b = u;
          perfb = perfu;
          % We must GET INTERMEDIATE POINT IF NO MIDPOINT EXISTS
          v = a + tau1*(b - a);
          w = v;
          x = v;
          X_temp = X + v*dX;
          net_temp = setx(net,X_temp);
          [perfv,E,Ac,N,Zb,Zi,Zl] = calcperf(net_temp,X_temp,Pd,Tl,Ai,Q,TS);
          perfw = perfv;
          perfx = perfv;
          cnt1 = cnt1 + 1;
        end
      else
        b = u;
        perfb = perfu;
      end
    
      if (perfu <= perfw) | (w == x)
        v = w; perfv = perfw;
        w = u; perfw = perfu;
      elseif (perfu <= perfv) | (v == x) | (v == w)
        v = u; perfv = perfu;
      end

    end

    temp = [w x v];
    min_int = min(temp);
    max_int = max(temp);
  end
else
   v=a;w=a;x=a;
   perfv=perfa;perfw=perfa;perfx=perfa;
end

% COMPUTE THE FINAL STEP, FUNCTION VALUE AND GRADIENT
xtot = [a b v w x];
perftot = [perfa perfb perfv perfw perfx];
[perftot,i] = sort(perftot);
xtot = xtot(i);
a = xtot(1);
perf = perftot(1);
X = X + a*dX;
net = setx(net,X);
[perf,E,Ac,N,Zb,Zi,Zl] = calcperf(net,X,Pd,Tl,Ai,Q,TS);
gX = -calcgx(net,X,Pd,Zb,Zi,Zl,N,Ac,E,perf,Q,TS);

% CHANGE INITIAL STEP SIZE TO PREVIOUS STEP
delta=a;
if delta < net.trainParam.delta
  delta = net.trainParam.delta;
end

% We always update the tolerance.
tol=delta/scale_tol;

retcode = [cnt1 cnt2 0];
