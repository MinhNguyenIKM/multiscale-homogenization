function out1=mse(varargin)
%MSE Mean squared error performance function.
%
%  Syntax
%
%    perf = mse(E,Y,X,FP)
%    dPerf_dy = mse('dy',E,Y,X,perf,FP);
%    dPerf_dx = mse('dx',E,Y,X,perf,FP);
%    info = mse(code)
%
%  Description
%
%    MSE is a network performance function.  It measures the
%    network's performance according to the mean of squared errors.
%  
%    MSE(E,Y,X,PP) takes E and optional function parameters,
%      E - Matrix or cell array of error vectors.
%      Y - Matrix or cell array of output vectors. (ignored).
%      X  - Vector of all weight and bias values (ignored).
%      FP - Function parameters (ignored).
%     and returns the mean squared error.
%
%    MSE('dy',E,Y,X,PERF,FP) returns derivative of PERF with respect to Y.
%    MSE('dx',E,Y,X,PERF,FP) returns derivative of PERF with respect to X.
%
%    MSE('name') returns the name of this function.
%    MSE('pnames') returns the name of this function.
%    MSE('pdefaults') returns the default function parameters.
%  
%  Examples
%
%    Here a two layer feed-forward network is created with a 1-element
%    input ranging from -10 to 10, four hidden TANSIG neurons, and one
%    PURELIN output neuron. The default performance function for networks
%    created with NEWFF is MSE.
%
%      net = newff([-10 10],[4 1],{'tansig','purelin'});
%
%    Here the network is given a batch of inputs P.  The error
%    is calculated by subtracting the output A from target T.
%    Then the mean squared error is calculated.
%
%      p = [-10 -5 0 5 10];
%      t = [0 0 1 1 1];
%      y = sim(net,p)
%      e = t-y
%      perf = mse(e)
%
%    Note that MSE can be called with only one argument because the
%    other arguments are ignored.  MSE supports those ignored arguments
%    to conform to the standard performance function argument list.
%
%  Network Use
%
%    You can create a standard network that uses MSE with NEWFF,
%    NEWCF, or NEWELM.
%
%    To prepare a custom network to be trained with MSE set
%    NET.performFcn to 'mse'.  This will automatically set
%    NET.performParam to the empty matrix [], as MSE has no
%    performance parameters.
%
%    In either case, calling TRAIN or ADAPT will result
%    in MSE being used to calculate performance.
%
%    See NEWFF or NEWCF for examples.
%
%  See also MSNE, MSEREG, MSNEREG, MAE

% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.6 $

fn = mfilename;
boiler_perform

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Info
function info = function_info

info.function = 'mse';
info.title = name;
info.type = 'Performance';
info.version = 6;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Mean Squared Error';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Defaults
function fp = param_defaults()
fp = struct;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Names
function names = param_names
names = {};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Check
function err = param_check(fp)
err = {};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Apply Performance Function
function perf = performance(e,y,x,fp)

dontcares = find(~isfinite(e));
e(dontcares) = 0;
numerator = sum(sum(e.^2));
numElements = prod(size(e)) - length(dontcares);
if (numElements == 0)
  perf = 0;
else
  perf = numerator / numElements;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Perf w/respect to Y
function d = derivative_dperf_dy(e,y,x,perf,fp)

dontcares = find(~isfinite(e));
numElements = numel(e) - length(dontcares);
if (numElements == 0)
  d = zeros(size(e));
else
  d = e * (2/numElements);
  d(dontcares) = 0;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Perf w/respect to X
function d = derivative_dperf_dx(t,y,x,perf,fp)

d = zeros(size(x));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
