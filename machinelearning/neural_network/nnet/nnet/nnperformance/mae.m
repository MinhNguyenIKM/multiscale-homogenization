function out1=mae(varargin)
%MAE Mean absolute error performance function.
%
%  Syntax
%
%    perf = mae(E,Y,X,FP)
%    dPerf_dy = mae('dy',E,Y,X,perf,FP);
%    dPerf_dx = mae('dx',E,Y,X,perf,FP);
%    info = mae(code)
%
%  Description
%
%    MAE is a network performance function.  It measures network
%    performance as the mean of absolute errors.
%  
%    MAE(E,Y,X,PP) takes E and optional function parameters,
%      E - Matrix or cell array of error vectors.
%      Y - Matrix or cell array of output vectors. (ignored).
%      X  - Vector of all weight and bias values (ignored).
%      FP - Function parameters (ignored).
%     and returns the mean absolute error.
%
%    MAE('dy',E,Y,X,PERF,FP) returns derivative of PERF with respect to Y.
%    MAE('dx',E,Y,X,PERF,FP) returns derivative of PERF with respect to X.
%
%    MAE('name') returns the name of this function.
%    MAE('pnames') returns the name of this function.
%    MAE('pdefaults') returns the default function parameters.
%  
%  Examples
%
%    Here a perceptron is created with a 1-element input ranging
%    from -10 to 10, and one neuron.
%
%      net = newp([-10 10],1);
%
%    Here the network is given a batch of inputs P.  The error
%    is calculated by subtracting the output A from target T.
%    Then the mean absolute error is calculated.
%
%      p = [-10 -5 0 5 10];
%      t = [0 0 1 1 1];
%      y = sim(net,p)
%      e = t-y
%      perf = mae(e)
%
%    Note that MAE can be called with only one argument because
%    the other arguments are ignored.  MAE supports those arguments
%    to conform to the standard performance function argument list.
%
%  Network Use
%
%    You can create a standard network that uses MAE with NEWP.
%
%    To prepare a custom network to be trained with MAE, set
%    NET.performFcn to 'mae'.  This will automatically set
%    NET.performParam to the empty matrix [], as MAE has no
%    performance parameters.
%
%    In either case, calling TRAIN or ADAPT will result
%    in MAE being used to calculate performance.
%
%    See NEWP for examples.
%
%  See also MSE, MSEREG, DMAE.

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
n = 'Mean Absolute Error';
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
numcares = prod(size(e)) - length(dontcares);
e(dontcares) = 0;
perf = sum(sum(abs(e)))/numcares;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Perf w/respect to Y
function d = derivative_dperf_dy(e,y,x,perf,fp)

dontcares = find(~isfinite(e));
numcares = prod(size(e)) - length(dontcares);
e(dontcares) = 0;
d = sign(e)/numcares;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Perf w/respect to X
function d = derivative_dperf_dx(t,y,x,perf,fp)

d = zeros(size(x));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
