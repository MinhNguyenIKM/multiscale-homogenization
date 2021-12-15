function out1=template_net_input(varargin)
%TEMPLATE_NET_INPUT Template net input function.
%
%  WARNING - Future versions of the toolbox may require you to update
%  custom functions.
%
%  Directions for Customizing
%
%    1. Make a copy of this function with a new name
%    2. Edit your new function according to the code comments marked ***
%    3. Type HELP NNNETINPUT to see a list of other net input functions.
%
%	Syntax
%
%	  N = template_net_input({Z1,Z2,...,Zn},FP)
%   dN_dZj = template_net_input('dz',j,Z,N,FP)
%	  INFO = template_net_input(CODE)
%
%	Description
%
%	  TEMPLATE_NET_INPUT({Z1,Z2,...,Zn},FP) takes these arguments,
%	    Zi - SxQ matrices in a row cell array.
%	    FP - Row cell array of function parameters (optional, ignored).
%	  Returns element-wise product of Z1 to Zn.
%
%	  TEMPLATE_NET_INPUT(code) returns information about this function.
%	  These codes are defined:
%     'fullderiv'  - Full NxSxQ derivative = 1, Element-wise SxQ derivative = 0.
%	    'name'       - Full name.
%	    'fpnames'    - Returns names of function parameters.
%	    'fpdefaults' - Returns default function parameters.
%
%	Network Use
%
%	  To change a network so that a layer uses TEMPLATE_NET_INPUT, set
%	  NET.layers{i}.netInputFcn to 'template_net_input'.

% Copyright 1992-2005 The MathWorks, Inc.

fn = mfilename;
boiler_net

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name

% *** CUSTOMIZE HERE
% *** Define this functions human readable name
n = 'Template';
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Defaults
function fp = param_defaults(values)
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Apply Net Function
function n = apply(z,fp)

[s,q] = size(z{1});

% *** CUSTOMIZE HERE
% *** Combine all the SxQ Z{i} matrices into one SxQ N matrix
% *** Each value N{j,q} must depend only on the set of Z{i}(j,q)'s
n = z{1};
for i=2:length(z)
  n = n .* z{i};
end
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of N w/respect to Zj
function d = derivative_dn_dzj(j,z,n,fp)

[s,q] = size(n);

% *** CUSTOMIZE HERE
% *** Calculate the SxQ derivative of N with respect to Z{i}
if (length(z) == 1)
  d = ones(s,q);
else
  z(j) = [];
  d = z{1};
  for i=2:length(z)
    d = d .* z{i};
  end
end
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
