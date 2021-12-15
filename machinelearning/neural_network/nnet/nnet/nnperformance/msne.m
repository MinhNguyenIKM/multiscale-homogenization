function out1=msne(varargin)
%MSNE Mean squared normalized error performance function.
%
%  Syntax
%
%    perf = msne(E,Y,X,FP)
%    dPerf_dy = msne('dy',E,Y,net,perf,FP);
%    dPerf_dx = msne('dx',E,Y,net,perf,FP);
%    info = msne(code)
%
%  Description
%
%    MSNE is a network performance function.  It measures the
%    network's performance according to the mean of squared normalized
%    errors. Normalized errors are calculated as the difference between
%    targets and outputs after they are each normalized to [-1,1].
%
%    The normalization insures that networks with multiple outputs will
%    be trained so that accuracy of each output is treated as equally
%    important. Without normalization outputs with larger values
%    (and therefore larger errors) would be treated as more important.
%  
%    MSNE(E,Y,X,PP) takes E and optional function parameters,
%      E   - Matrix or cell array of error vectors.
%      Y   - Matrix or cell array of output vectors. (ignored).
%      NET - Neural network.
%      FP  - Function parameters (ignored).
%     and returns the mean squared error.
%
%    MSNE('dy',E,Y,NET,PERF,FP) returns derivative of PERF with respect to Y.
%    MSNE('dx',E,Y,NET,PERF,FP) returns derivative of PERF with respect to X.
%
%    MSNE('name') returns the name of this function.
%    MSNE('pnames') returns the name of this function.
%    MSNE('pdefaults') returns the default function parameters.
%  
%  Examples
%
%    Here a two layer feed-forward network is created with a 1-element
%    input ranging from -10 to 10, targets ranging from 0 to 1, and four
%    hidden  neurons, using MSNE as its performance function.
%
%      net = newff([-10 0 10],[0 0.5 1],4);
%      net.performFcn = 'msne';
%
%    Here the network is given a batch of inputs P.  The error
%    is calculated by subtracting the output A from target T.
%    Then the mean squared error is calculated.
%
%      p = [-10 -5 0 5 10];
%      t = [0 0 1 1 1];
%      y = sim(net,p)
%      e = t-y
%      perf = msne(e,y,net)
%
%  Network Use
%
%    To prepare a custom network to be trained with MSNE set
%    NET.performFcn to 'msne'.  This will automatically set
%    NET.performParam to the empty matrix [], as MSNE has no
%    performance parameters.
%
%    In either case, calling TRAIN or ADAPT will result
%    in MSNE being used to calculate performance.
%
%  See also MSE, MSEREG, MSNEREG, MAE

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

%% Name
function n = name
n = 'Mean Squared Normalized Error';

%% Parameter Defaults
function fp = param_defaults()
fp = struct;

%% Parameter Names
function names = param_names
names = {};

%% Parameter Check
function err = param_check(fp)
err = {};

%% Apply Performance Function
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
  perf = 0;
else
  perf = numerator / numElements;
end

%% Derivative of Perf w/respect to Y
function d = derivative_dperf_dy(e,y,net,perf,fp)

% Normalize t,y,e
t = celladd(e,y);
t = nn_normalize_outputs(t,net);
y = nn_normalize_outputs(y,net);
e = cellsubtract(t,y);

dontcares = find(~isfinite(e));
numElements = numel(e) - length(dontcares);
if (numElements == 0)
  d = zeros(size(e));
else
  d = e * (2/numElements);
  d(dontcares) = 0;
end

% Normalize d
d = nn_normalize_output_derivatives(d,net);

%% Derivative of Perf w/respect to X
function d = derivative_dperf_dx(t,y,net,perf,fp)

x = getx(net);

d = zeros(size(x));
