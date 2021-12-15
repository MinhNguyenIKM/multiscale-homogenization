function result=dotprod(a,b,c,d,e)
%DOTPROD Dot product weight function.
%
%	Syntax
%
%	  Z = dotprod(W,P,FP)
%	  info = dotprod(code)
%     dim = dotprod('size',S,R,FP)
%     dp = dotprod('dp',W,P,Z,FP)
%     dw = dotprod('dw',W,P,Z,FP)
%
%	Description
%
%	  DOTPROD is the dot product weight function.  Weight functions
%	  apply weights to an input to get weighted inputs.
%
%	  DOTPROD(W,P,FP) takes these inputs,
%	    W - SxR weight matrix.
%	    P - RxQ matrix of Q input (column) vectors.
%	    FP - Row cell array of function parameters (optional, ignored).
%	  and returns the SxQ dot product of W and P.
%
%	  DOTPROD(code) returns information about this function.
%	  These codes are defined:
%	    'deriv'      - Name of derivative function (for ver. 4).
%	    'pfullderiv' - Input: Reduced derivative = 2, Full derivative = 1, linear derivative = 0.
%       'wfullderiv' - Weight: Reduced derivative = 2, Full derivative = 1, linear derivative = 0.
%	    'name'       - Full name.
%	    'fpnames'    - Returns names of function parameters.
%	    'fpdefaults' - Returns default function parameters.
%
%   DOTPROD('size',S,R,FP) takes the layer dimension S, input dimension R,
%   and function parameters, and returns the weight size [SxR].
%
%   DOTPROD('dp',W,P,Z,FP) returns the derivative of Z with respect to P.
%   DOTPROD('dw',W,P,Z,FP) returns the derivative of Z with respect to W.
%
%	Examples
%
%	  Here we define a random weight matrix W and input vector P
%	  and calculate the corresponding weighted input Z.
%
%	    W = rand(4,3);
%	    P = rand(3,1);
%	    Z = dotprod(W,P)
%
%	Network Use
%
%	  You can create a standard network that uses DOTPROD
%	  by calling NEWP or NEWLIN.
%
%	  To change a network so an input weight uses DOTPROD set
%	  NET.inputWeight{i,j}.weightFcn to 'dotprod.  For a layer weight
%	  set NET.inputWeight{i,j}.weightFcn to 'dotprod.
%
%	  In either case, call SIM to simulate the network with DOTPROD.
%	  See NEWP and NEWLIN for simulation examples.
%
%	See also SIM, DDOTPROD, DIST, NEGDIST, NORMPROD.

% Mark Beale, 11-31-97
% Mark Hudson Beale, improvements, 01-08-2001
% Orlando De Jesus, code fix, 02-12-2002
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.3 $

fn = mfilename;
boiler_weight

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Dot Product';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Flag for dZ/dP type
function d = p_deriv
d = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Flag for dZ/dW type
function d = w_deriv
d = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter default values
function fp = param_defaults
fp = struct;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Names
function names = param_names
names = {};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Check
function err = param_check(fp)
err = '';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Weight Size
function dim = weight_size(s,r,fp)
dim = [s r];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Apply Weight Function
function z = apply(w,p,fp)
z = w*p;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative w/respect to Input
function d = derivative_dz_dp(w,p,z,fp)
d = w;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative w/respect to Weight
function d = derivative_dz_dw(w,p,z,fp)
d = p;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
