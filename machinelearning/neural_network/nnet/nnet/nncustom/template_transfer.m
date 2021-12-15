function out1 = template_transfer(in1,in2,in3,in4)
%TEMPLATE_TRANSFER Template transfer function.
%
%  WARNING - Future versions of the toolbox may require you to update
%  custom functions.
%
%  Directions for Customizing
%
%    1. Make a copy of this function with a new name
%    2. Edit your new function according to the code comments marked ***
%    3. Type HELP NNTRANSFER to see a list of other transfer functions.
%
%	Syntax
%
%	  A = template_transfer(N,FP)
%   dA_dN = template_transfer('dn',N,A,FP)
%	  INFO = template_transfer(CODE)
%
%	Description
%
%	  TEMPLATE_TRANSFER(N,FP) takes N and optional function parameters,
%	    N - SxQ matrix of net input (column) vectors.
%	    FP - Struct of function parameters (ignored).
%	  and returns A, the SxQ boolean matrix with 1's where N >= 0.
%	
%   TEMPLATE_TRANSFER('dn',N,A,FP) returns SxQ derivative of A w-respect to N.
%   If A or FP are not supplied or are set to [], FP reverts to
%   the default parameters, and A is calculated from N.
%
%   TEMPLATE_TRANSFER('name') returns the name of this function.
%   TEMPLATE_TRANSFER('output',FP) returns the [min max] output range.
%   TEMPLATE_TRANSFER('active',FP) returns the [min max] active input range.
%   TEMPLATE_TRANSFER('fullderiv') returns 1 or 0, whether DA_DN is SxSxQ or SxQ.
%   TEMPLATE_TRANSFER('fpnames') returns the names of the function parameters.
%   TEMPLATE_TRANSFER('fpdefaults') returns the default function parameters.
%	
%	Network Use
%
%	  To change a network so a layer uses TEMPLATE_TRANSFER set
%	  NET.layer{i}.transferFcn to 'template_transfer.

% Copyright 1992-2005 The MathWorks, Inc.

fn = mfilename;
boiler_transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name

% *** CUSTOMIZE HERE
% *** Define this functions human readable name
n = 'Template';
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output range
function r = output_range(fp)

% *** CUSTOMIZE HERE
% *** Return min and max values that this function can generate
r = [-1 1];
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Active input range
function r = active_input_range(fp)

% *** CUSTOMIZE HERE
% *** Return min and max values for the interval where this function
% *** appreciably changes.  If the function repeats, choose a repetition interval.
r = [-pi pi];
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Defaults
function fp = param_defaults
fp.param1 = 1;
fp.param2 = 2;
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Apply Transfer Function
function a = apply_transfer(n,fp)

% *** CUSTOMIZE HERE
% *** Return an error string if any function parameter is not defined properly.
a = sin(n);
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function da_dn = derivative(n,a,fp)

% *** CUSTOMIZE HERE
% *** Return an error string if any function parameter is not defined properly.
da_dn = cos(n);
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
