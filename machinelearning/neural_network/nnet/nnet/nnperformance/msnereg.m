function out1=msnereg(varargin)
%MSNEREG Mean squared normalized error with regularization performance function.
%
%  Syntax
%
%    perf = msnereg(E,Y,NET,FP)
%    dPerf_dy = msnereg('dy',E,Y,NET,perf,FP);
%    dPerf_dx = msnereg('dx',E,Y,NET,perf,FP);
%    info = msnereg(code)
%
%  Description
%
%    MSNEREG is a network performance function.  It measures
%    network performance as the weighted sum of two factors:
%    the mean squared normalized error and the mean squared
%    weights and biases.
%  
%    The normalization insures that networks with multiple outputs will
%    be trained so that accuracy of each outputs is treated as equally
%    important. Without normalization outputs with larger values
%    (and therefore larger errors) would be treated as more important.
%
%    MSNEREG(E,Y,NET,FP) takes E and optional function parameters,
%      E    - Matrix or cell array of error vectors.
%      Y    - Matrix or cell array of output vectors. (ignored).
%      NET  - Neural network.
%      FP.ratio - Ratio of importance between errors and weights.
%    and returns the mean squared normalized error, plus FP.reg times the mean
%    squared weights.
%
%    MSNEREG('dy',E,Y,NET,PERF,FP) returns derivative of PERF with respect to Y.
%    MSNEREG('dx',E,Y,NET,PERF,FP) returns derivative of PERF with respect to X.
%
%    MSNEREG('name') returns the name of this function.
%    MSNEREG('pnames') returns the name of this function.
%    MSNEREG('pdefaults') returns the default function parameters.
%  
%  Examples
%
%    Here a two layer feed-forward network is created with a 1-element
%    input ranging from -10 to 10, targets ranging from 0 to 1, and four
%    hidden  neurons, using MSNEREG as its performance function, with
%    an importance ratio emphasizing minimizing errors as 20 times as
%    important as minimizing weights.
%
%      net = newff([-10 0 10],[0 0.5 1]);
%      net.performFcn = 'msnereg';
%      net.performParam.ratio = 20/(20+1);
%
%    Here the network is given a batch of inputs P.  The error
%    is calculated by subtracting the output A from target T.
%    Then the mean squared error is calculated.
%
%      p = [-10 -5 0 5 10];
%      t = [0 0 1 1 1];
%      y = sim(net,p)
%      e = t-y
%      perf = msnereg(e,y,net)
%
%  Network Use
%
%    To prepare a custom network to be trained with MSNEREGEC, set
%    NET.performFcn to 'msnereg'.  This will automatically set
%    NET.performParam to the default performance parameters.
%
%    In either case, calling TRAIN or ADAPT will result
%    in MSNEREG being used to calculate performance.
%
%  See also MSE, MSNE, MSEREG.

% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.8.5 $

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
n = 'Mean Squared Normalized Error with Regularization';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Defaults
function fp = param_defaults()
fp = struct;
fp.ratio = 0.9;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Names
function names = param_names
names = {'ratio'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Check
function err = param_check(fp)

err = {};
e = fp.ratio;
if ~isa(e,'double') || (prod(size(e))~=1) || ~isfinite(e) || (r<0) || (r>1)
  err(end+1) = 'RATIO must be a real in the interal [0,1].';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Apply Performance Function
function perf = performance(e,y,net,fp)

% Normalize t,y,e
t = celladd(e,y);
t = nn_normalize_outputs(t,net);
y = nn_normalize_outputs(y,net);
e = cellsubtract(t,y);

dontcares = find(~isfinite(e));
e(dontcares) = 0;
numerator = sum(sum(e.^2));
numElements = prod(size(e)) - length(dontcares);
if (numElements == 0)
  perfe = 0;
else
  perfe = numerator / numElements;
end
if (length(x) == 0)
  perfx = 0;
else
  perfx = sum(sum(x.^2))/length(x);
end
perf = fp.ratio*perfe + (1-fp.ratio)*perfx;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Perf w/respect to Y
function d = derivative_dperf_dy(e,y,net,perf,fp)

% Normalize t,y,e
t = celladd(e,y);
t = nn_normalize_outputs(t,net);
y = nn_normalize_outputs(y,net);
e = cellsubtract(t,y);

dontcares = find(~isfinite(e));
e(dontcares) = 0;
numElements = prod(size(e)) - length(dontcares);
if (numElements == 0)
  d = zeros(size(e));
else
  d = e * (fp.ratio * 2/numElements);
end

% Normalize d
d = nn_normalize_output_derivatives(d,net);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Perf w/respect to X
function d = derivative_dperf_dx(e,y,net,perf,fp)

x = getx(net);

m = 2*(1-fp.ratio)/length(x);
d = -x * m;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
