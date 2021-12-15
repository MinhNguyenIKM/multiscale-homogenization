function out1=sse(varargin)
%SSE Sum squared error performance function.
%
%  Syntax
%
%    perf = sse(E,Y,X,FP)
%    dPerf_dy = sse('dy',E,Y,X,perf,FP);
%    dPerf_dx = sse('dx',E,Y,X,perf,FP);
%    info = sse(code)
%
%  Description
%
%    SSE is a network performance function.  It measures
%    performance according to the sum of squared errors.
%  
%    SSE(E,Y,X,PP) takes E and optional function parameters,
%      E - Matrix or cell array of error vectors.
%      Y - Matrix or cell array of output vectors. (ignored).
%      X  - Vector of all weight and bias values (ignored).
%      FP - Function parameters (ignored).
%     and returns the sum squared error.
%
%    SSE('dy',E,Y,X,PERF,FP) returns derivative of PERF with respect to Y.
%    SSE('dx',E,Y,X,PERF,FP) returns derivative of PERF with respect to X.
%
%    SSE('name') returns the name of this function.
%    SSE('pnames') returns the name of this function.
%    SSE('pdefaults') returns the default function parameters.
%  
%  Examples
%
%    Here a two layer feed-forward is created with a 1-element input
%    ranging from -10 to 10, four hidden TANSIG neurons, and one
%    PURELIN output neuron.
%
%      net = newff([-10 10],[4 1],{'tansig','purelin'});
%
%    Here the network is given a batch of inputs P.  The error
%    is calculated by subtracting the output A from target T.
%    Then the sum squared error is calculated.
%
%      p = [-10 -5 0 5 10];
%      t = [0 0 1 1 1];
%      y = sim(net,p)
%      e = t-y
%      perf = sse(e)
%
%    Note that SSE can be called with only one argument because
%    the other arguments are ignored.  SSE supports those arguments
%    to conform to the standard performance function argument list.
%
%  Network Use
%
%    To prepare a custom network to be trained with SSE set
%    NET.performFcn to 'sse'.  This will automatically set
%    NET.performParam to the empty matrix [], as SSE has no
%    performance parameters.
%
%    Calling TRAIN or ADAPT will result in SSE being used to calculate
%    performance.
%
%  See also DSSE.

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
n = 'Sum Squared Error';
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
perf = sum(sum(e.^2));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Perf w/respect to Y
function d = derivative_dperf_dy(e,y,x,perf,fp)

dontcares = find(~isfinite(e));
e(dontcares) = 0;
d = e * 2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Perf w/respect to X
function d = derivative_dperf_dx(t,y,x,perf,fp)

d = zeros(size(x));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
