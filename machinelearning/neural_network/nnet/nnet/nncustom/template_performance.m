function out1=template_performance(varargin)
%TEMPLATE_PERFORMANCE Template performance function.
%
%  WARNING - Future versions of the toolbox may require you to update
%  custom functions.
%
%  Directions for Customizing
%
%    1. Make a copy of this function with a new name
%    2. Edit your new function according to the code comments marked ***
%    3. Type HELP NNPERFORMANCE to see a list of other performance functions.
%
%  Syntax
%
%    perf = template_performance(E,Y,X,FP)
%    dPerf_dy = template_performance('dy',E,Y,X,perf,FP);
%    dPerf_dx = template_performance('dx',E,Y,X,perf,FP);
%    info = template_performance(code)
%
%  Description
%
%    TEMPLATE_PERFORMANCE(E,Y,X,PP) takes E and optional function parameters,
%      E - Matrix or cell array of error vectors.
%      Y - Matrix or cell array of output vectors. (ignored).
%      X  - Vector of all weight and bias values (ignored).
%      FP - Function parameters (ignored).
%     and returns the mean squared error.
%
%    TEMPLATE_PERFORMANCE('dy',E,Y,X,PERF,FP) returns derivative of PERF with respect to Y.
%    TEMPLATE_PERFORMANCE('dx',E,Y,X,PERF,FP) returns derivative of PERF with respect to X.
%    TEMPLATE_PERFORMANCE('name') returns the name of this function.
%    TEMPLATE_PERFORMANCE('pnames') returns the name of this function.
%    TEMPLATE_PERFORMANCE('pdefaults') returns the default function parameters.
%
%  Network Use
%
%    To prepare a custom network to be trained with TEMPLATE_PERFORMANCE set
%    NET.performFcn to 'template_performance'.  This will automatically set
%    NET.performParam to the default functions parameters.

% Copyright 1992-2007 The MathWorks, Inc.

fn = mfilename;
boiler_perform

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name

% *** CUSTOMIZE HERE
% *** Define this functions human readable name
n = 'Template';
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Defaults
function fp = param_defaults()
fp = struct;

% *** CUSTOMIZE HERE
% *** Defined this functions parameters by supplied or default values, if any
if length(values) > 1, fp.param = values{1}; else fp.param1 = 1; end
if length(values) > 1, fp.param2 = values{2}; else fp.param2 = 2; end
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Names
function names = param_names

% *** CUSTOMIZE HERE
% *** Defined human readable names for this functions parameters, if any
names = {'Param One', 'Param Two'};
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Check
function err = param_check(fp)
err = [];

% *** CUSTOMIZE HERE
% *** Return an error string if any function parameter is not defined properly.
if (fp.param1 < -1000)
   err = 'Argument One is less than -1000';
elseif (fp.param2 == 20)
  err = 'Argument Two is 20';
end
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Apply Performance Function
function perf = performance(e,y,x,fp)

dontcareindices = find(~isfinite(e));
numdontcares = length(dontcareindices);
e(dontcareindices) = 0;

% *** CUSTOMIZE HERE
% *** Calculate scaler performance from error matrix E, output matrix Y, and
% *** the network weight and bias values vector X.
% *** Zero should indicate perfect performance, with more positive values
% *** indication worse performance.
% *** Don't care elements should effectively be ignored.
numerator = sum(sum(e.^2));
numElements = prod(size(e)) - length(dontcares);
if (numElements == 0)
  perf = 0;
else
  perf = numerator / numElements;
end
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Perf w/respect to Y
function d = derivative_dperf_dy(e,y,x,perf,fp)

dontcareindices = find(~isfinite(e));
numdontcares = length(dontcareindices);
e(dontcareindices) = 0;

% *** CUSTOMIZE HERE
% *** Calculate derivative of performance with respect to outputs Y
% *** This should include contributions of both error and any direct effect
% *** of outputs.
numElements = prod(size(e)) - length(dontcares);
if (numElements == 0)
  d = zeros(size(e));
else
  d = e * (2/numElements);
end
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Perf w/respect to X
function d = derivative_dperf_dx(t,y,x,perf,fp)

n = length(x);

% *** CUSTOMIZE HERE
% *** Calculate the Nx1 derivative of performance with respect to the networks
% *** weights and biases.
d = zeros(n,1);
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
