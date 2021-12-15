function result=template_weight(a,b,c,d,e)
%TEMPLATE_WEIGHT Template weight function.
%
%  WARNING - Future versions of the toolbox may require you to update
%  custom functions.
%
%  Directions for Customizing
%
%    1. Make a copy of this function with a new name
%    2. Edit your new function according to the code comments marked ***
%    3. Type HELP NNWEIGHT to see a list of other weight functions.
%
%	Syntax
%
%     Z = template_weight(W,P,FP)
%     info = template_weight(code)
%     dim = template_weight('size',S,R,FP)
%     dp = template_weight('dp',W,P,Z,FP)
%     dw = template_weight('dw',W,P,Z,FP)
%
%	Description
%
%	  TEMPLATE_WEIGHT(W,P,FP) takes these inputs,
%	    W - SxR weight matrix.
%	    P - RxQ matrix of Q input (column) vectors.
%	    FP - Row cell array of function parameters (optional, ignored).
%	  and returns the SxQ dot product of W and P.
%
%	  TEMPLATE_WEIGHT(code) returns information about this function.
%	  These codes are defined:
%	    'pfullderiv' - Input: Reduced derivative = 2, Full derivative = 1, linear derivative = 0.
%     'wfullderiv' - Weight: Reduced derivative = 2, Full derivative = 1, linear derivative = 0.
%	    'name'       - Full name.
%	    'fpnames'    - Returns names of function parameters.
%	    'fpdefaults' - Returns default function parameters.
%
%   TEMPLATE_WEIGHT('size',S,R,FP) takes the layer dimension S, input dimension R,
%   and function parameters, and returns the weight size [SxR].
%   TEMPLATE_WEIGHT('dp',W,P,Z,FP) returns the derivative of Z with respect to P.
%   TEMPLATE_WEIGHT('dw',W,P,Z,FP) returns the derivative of Z with respect to W.
%
%	Network Use
%
%	  To change a network so an input weight uses TEMPLATE_WEIGHT set
%	  NET.inputWeight{i,j}.weightFcn to 'template_weight.  For a layer weight
%	  set NET.inputWeight{i,j}.weightFcn to 'template_weight.

% Copyright 1992-2007 The MathWorks, Inc.

fn = mfilename;
boiler_weight

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name

% *** CUSTOMIZE HERE
% *** Define this functions human readable name
n = 'Template';
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Flag for dZ/dP type
function d = p_deriv

% *** CUSTOMIZE HERE
% *** Define this form of dZ/dP returned by this function.
% *** 0 = linear (SxR matrix)
% *** 1 = full (1xQ cell array of SxR matrices)
% *** 2 = reduced
d = 0;
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Flag for dZ/dW type
function d = w_deriv

% *** CUSTOMIZE HERE
% *** Define this form of dZ/dP returned by this function.
% *** 0 = linear (RxQ matrix)
% *** 1 = full (1xS cell array of RxQ matrices)
% *** 2 = reduced
d = 0;
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter default values
function fp = param_defaults
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Weight Size
function dim = weight_size(s,r,fp)

% *** CUSTOMIZE HERE
% *** Return dimensions of the weight given R element input to
% *** an S neuron layer
dim = [s r];
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Apply Weight Function
function z = apply(w,p,fp)

% *** CUSTOMIZE HERE
% *** Calculate SxQ net input Z given SxR weight W and RxQ input P
z = w*p;
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative w/respect to Input
function d = derivative_dz_dp(w,p,z,fp)

% *** CUSTOMIZE HERE
% *** Calculate derivative of weight input with respect to input
% *** The results form must be consistent with the value returned
% ***  by P_DERIV above.
d = w;
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative w/respect to Weight
function d = derivative_dz_dw(w,p,z,fp)

% *** CUSTOMIZE HERE
% *** Calculate derivative of weight input with respect to weight
% *** The results form must be consistent with the value returned
% ***  by W_DERIV above.
d = p;
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
