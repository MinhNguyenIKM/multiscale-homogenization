function out1=mseregec(varargin)
%MSEREGEC Mean squared error with regularization and economization performance function.
%
%  Syntax
%
%    perf = mseregec(E,Y,X,FP)
%    dPerf_dy = mseregec('dy',E,Y,X,perf,FP);
%    dPerf_dx = mseregec('dx',E,Y,X,perf,FP);
%    info = mseregec(code)
%
%  Description
%
%    MSEREGEC is a network performance function.  It measures
%    network performance as the weighted sum of three factors:
%    the mean squared error, the mean squared weights and biases,
%    and the mean squared output.
%  
%    MSEREGEC(E,Y,X,PP) takes from these arguments,
%      E - SxQ error matrix or NxTS cell array of such matrices.
%      Y - SxQ error matrix or NxTS cell array of such matrices.
%      X - Vector of weight and bias values.
%      FP.reg - Importance of minimizing weights relative to errors.
%      FP.econ - Importance of minimizing outputs relative to errors.
%    and returns the mean squared error, plus FP.reg times the mean
%    squared weights, plus FP.econ times the mean squared output.
%
%    MSEREGEC('dy',E,Y,X,PERF,FP) returns derivative of PERF with respect to Y.
%    MSEREGEC('dx',E,Y,X,PERF,FP) returns derivative of PERF with respect to X.
%
%    MSEREGEC('name') returns the name of this function.
%    MSEREGEC('pnames') returns the name of this function.
%    MSEREGEC('pdefaults') returns the default function parameters.
%  
%  Examples
%
%    Here a two layer feed-forward is created with a 1-element input
%    ranging from -2 to 2, four hidden TANSIG neurons, and one
%    PURELIN output neuron.
%
%  net = newff([-2 2],[4 1],{'tansig','purelin'},'trainlm','learngdm','msereg');
%
%    Here the network is given a batch of inputs P.  The error is
%    calculated by subtracting the output A from target T. Then the
%    mean squared error is calculated using a ratio of 20/(20+1).
%    (Errors are 20 times as important as weight and bias values).
%
%      p = [-2 -1 0 1 2];
%      t = [0 1 1 1 0];
%      y = sim(net,p)
%      e = t-y
%      net.performParam.ratio = 20/(20+1);
%      perf = msereg(e,net)
%
%  Network Use
%
%    You can create a standard network that uses MSEREG with NEWFF,
%    NEWCF, or NEWELM.
%
%    To prepare a custom network to be trained with MSEREG, set
%    NET.performFcn to 'msereg'.  This will automatically set
%    NET.performParam to MSEREG's default performance parameters.
%
%    In either case, calling TRAIN or ADAPT will result
%    in MSEREG being used to calculate performance.
%
%    See NEWFF or NEWCF for examples.
%
%  See also MSE, MAE, DMSEREG.

% Copyright 1992-2008 The MathWorks, Inc.

fn = mfilename;
boiler_perform

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Info
function info = function_info

info.function = mfilename;
info.title = name;
info.type = 'Performance';
info.version = 6;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Mean Squared Error with Regularization & Economization';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Defaults
function fp = param_defaults()
fp = struct;
fp.reg = 0.05;
fp.econ = 0.05;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Names
function names = param_names
names = {'reg','econ'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Check
function err = param_check(fp)

err = {};
r = fp.reg;
if ~isa(r,'double') || (prod(size(r))~=1) || ~isfinite(r) || (r<0)
  err(end+1) = 'REG must be positive real or zero.';
end
e = fp.econ;
if ~isa(e,'double') || (prod(size(e))~=1) || ~isfinite(e) || (r<0)
  err(end+1) = 'ECON must be positive real or zero.';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Apply Performance Function
function perf = performance(e,y,x,fp)

dontcares = find(~isfinite(e));
e(dontcares) = 0;
numerator = sum(sum(e.^2));
numElements = prod(size(e)) - length(dontcares);
if (numElements == 0)
  perfe = 0;
else
  perfe = numerator / numElements;
end
perfx = sum(sum(x.^2))/length(x);
perfy = sum(sum(y.^2))/prod(size(y));
perf = perfe + fp.reg*perfx + fp.econ*perfy;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Perf w/respect to Y
function d = derivative_dperf_dy(e,y,x,perf,fp)

dontcares = find(~isfinite(e));
e(dontcares) = 0;
numElements = prod(size(e)) - length(dontcares);
if (numElements == 0)
  d1 = zeros(size(e));
else
  d1 = e * (2/numElements);
end
d2 = y * (fp.econ * -2/prod(size(y)));
d = d1 + d2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Perf w/respect to X
function d = derivative_dperf_dx(e,y,x,perf,fp)

m = -2*fp.reg/length(x);
d = x * m;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
