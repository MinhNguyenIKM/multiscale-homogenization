function result=scalprod(a,b,c,d,e)
%SCALPROD Scalar product weight function.
%
%	Syntax
%
%	  Z = scalprod(W,P,FP)
%     dim = scalprod('size',S,R,FP)
%     dp = scalprod('dp',W,P,Z,FP)
%     dw = scalprod('dw',W,P,Z,FP)
%	  info = scalrod(code)
%
%	Description
%
%	  SCALROD is the scalar product weight function.  Weight functions
%	  apply weights to an input to get weighted inputs.
%
%	  SCALPROD(W,P) takes these inputs,
%	    W - 1x1 weight matrix.
%	    P - RxQ matrix of Q input (column) vectors.
%	  and returns the RxQ scalar product of W and P defined by:
%       Z = w*P
%
%	  SCALPROD(code) returns information about this function.
%	  These codes are defined:
%	    'deriv'      - Name of derivative function.
%       'fullderiv'  - Reduced derivative = 2, Full derivative = 1, linear derivative = 0.
%       'pfullderiv' - Input: Reduced derivative = 2, Full derivative = 1, linear derivative = 0.
%       'wfullderiv' - Weight: Reduced derivative = 2, Full derivative = 1, linear derivative = 0.
%	    'name'       - Full name.
%	    'fpnames'    - Returns names of function parameters.
%	    'fpdefaults' - Returns default function parameters.
%
%
%     SCALPROD('size',S,R,FP) takes the layer dimension S, input dimension R,
%     and function parameters, and returns the weight size [1x1].
%
%     SCALPROD('dp',W,P,Z,FP) returns the derivative of Z with respect to P.
%     SCALPROD('dw',W,P,Z,FP) returns the derivative of Z with respect to W.
%
%	Examples
%
%	  Here we define a random weight matrix W and input vector P
%	  and calculate the corresponding weighted input Z.
%
%	    W = rand(1,1);
%	    P = rand(3,1);
%	    Z = scalprod(W,P)
%
%	Network Use
%
%	  To change a network so an input weight uses SCALPROD set
%	  NET.inputWeight{i,j}.weightFcn to 'scalprod.  For a layer weight
%	  set NET.inputWeight{i,j}.weightFcn to 'scalprod.
%
%	  In either case, call SIM to simulate the network with SCALPROD.
%	  See NEWP and NEWLIN for simulation examples.
%
%	See also DOTPROD, SIM, DIST, NEGDIST, NORMPROD.

% Orlando De Jesús, Martin Hagan, 7-20-05
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.3 $

boiler_weight

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Scalar Product';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Flag for dZ/dP type
function d = p_deriv
d = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Flag for dZ/dW type
function d = w_deriv
d = 2;
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
dim = [1 1];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Apply Weight Function
function z = apply(w,p,fp)
[S,R] = size(w);
[R2,Q] = size(p);
z = w*p;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative w/respect to Input
function d = derivative_dz_dp(w,p,z,fp)
[S,Q] = size(z);
[R2,Q] = size(p);
d=w*eye(S,R2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative w/respect to Weight
function d = derivative_dz_dw(w,p,z,fp)
[S,R] = size(w);
[R2,Q] = size(p);
d(:,1,:)=p;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
