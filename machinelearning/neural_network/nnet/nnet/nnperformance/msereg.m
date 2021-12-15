function out1=msereg(varargin)
%MSEREG Mean squared error with regularization performance function.
%
%  Syntax
%
%    perf = msereg(E,Y,X,FP)
%    dPerf_dy = msereg('dy',E,Y,X,perf,FP);
%    dPerf_dx = msereg('dx',E,Y,X,perf,FP);
%    info = msereg(code)
%
%  Description
%
%    MSEREG is a network performance function.  It measures
%    network performance as the weight sum of two factors:
%    the mean squared error and the mean squared weights and biases.
%  
%    MSEREG(E,Y,X,PP) takes E and optional function parameters,
%      E - Matrix or cell array of error vectors.
%      Y - Matrix or cell array of output vectors. (ignored).
%      X  - Vector of all weight and bias values.
%      FP.ratio - Ratio of importance between errors and weights.
%    and returns the mean squared error, plus FP.reg times the mean
%    squared weights.
%
%    MSEREG('dy',E,Y,X,PERF,FP) returns derivative of PERF with respect to Y.
%    MSEREG('dx',E,Y,X,PERF,FP) returns derivative of PERF with respect to X.
%
%    MSEREG('name') returns the name of this function.
%    MSEREG('pnames') returns the name of this function.
%    MSEREG('pdefaults') returns the default function parameters.
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

% Mark Beale, 11-31-97
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.7 $

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
n = 'Mean Squared Error with Regularization';
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
if (length(x) == 0)
  perfx = 0;
else
  perfx = sum(sum(x.^2))/length(x);
end
perf = fp.ratio*perfe + (1-fp.ratio)*perfx;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Perf w/respect to Y
function d = derivative_dperf_dy(e,y,x,perf,fp)

dontcares = find(~isfinite(e));
e(dontcares) = 0;
numElements = prod(size(e)) - length(dontcares);
if (numElements == 0)
  d = zeros(size(e));
else
  d = e * (fp.ratio * 2/numElements);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Perf w/respect to X
function d = derivative_dperf_dx(e,y,x,perf,fp)

m = 2*(1-fp.ratio)/length(x);
d = -x * m;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
