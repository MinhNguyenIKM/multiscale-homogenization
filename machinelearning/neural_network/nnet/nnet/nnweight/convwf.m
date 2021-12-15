function result=convwt(a,b,c,d,e)
%CONVWF Convolution weight function.
%
%	Syntax
%
%	  Z = convwf(W,P)
%   dim = convwf('size',S,R,FP)
%   dp = convwf('dp',W,P,Z,FP)
%   dw = convwf('dw',W,P,Z,FP)
%	  info = convwf(code)
%
%	Description
%
%	  CONVWF is the convolution weight function.  Weight functions
%	  apply weights to an input to get weighted inputs.
%
%	  CONVWF(code) returns information about this function.
%	  These codes are defined:
%	    'deriv'      - Name of derivative function.
%	    'fullderiv'  - Reduced derivative = 2, Full derivative = 1, linear derivative = 0.
%	    'pfullderiv' - Input: Reduced derivative = 2, Full derivative = 1, linear derivative = 0.
%	    'wfullderiv' - Weight: Reduced derivative = 2, Full derivative = 1, linear derivative = 0.
%	    'name'       - Full name.
%	    'fpnames'    - Returns names of function parameters.
%	    'fpdefaults' - Returns default function parameters.
%
%
%	  CONVWF('size',S,R,FP) takes the layer dimension S, input dimension R,
%	  and function parameters, and returns the weight size.
%
%	  CONVWF('dp',W,P,Z,FP) returns the derivative of Z with respect to P.
%	  CONVWF('dw',W,P,Z,FP) returns the derivative of Z with respect to W.
%
%	Examples
%
%	  Here we define a random weight matrix W and input vector P
%	  and calculate the corresponding weighted input Z.
%
%	    W = rand(4,1);
%	    P = rand(8,1);
%	    Z = convwf(W,P)
%
%	Network Use
%
%	  To change a network so an input weight uses CONVWF set
%	  NET.inputWeight{i,j}.weightFcn to 'convwf'.  For a layer weight
%	  set NET.inputWeight{i,j}.weightFcn to 'convwf'.
%
%	  In either case, call SIM to simulate the network with CONVWF.

% Orlando De Jesús, Martin Hagan, 7-20-05
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.3 $

boiler_weight

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Convolution';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Flag for dZ/dP type
function d = p_deriv
d = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Flag for dZ/dW type
function d = w_deriv
d = 2;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter default values
function fp = param_defaults
fp = struct;
fp.size = 4;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Names
function names = param_names
names = {'size'};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Check
function err = param_check(fp)
err = '';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Weight Size
function dim = weight_size(s,r,fp)
dim = [fp.size 1];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Apply Weight Function
function z = apply(w,p,fp)
[R,Q] = size(p);
S = R-fp.size+1;
for i=1:S,
   z(i,:)=w'*p(i+[0:(fp.size-1)],:);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative w/respect to Input
function d = derivative_dz_dp(w,p,z,fp)
[R,Q] = size(p);
S = R-fp.size+1;
ww=w(:,ones(1,R))';
d=full(spdiags(ww,[0:-1:-(fp.size-1)],zeros(R,S)))';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative w/respect to Weight
function d = derivative_dz_dw(w,p,z,fp)
[R,Q] = size(p);
S = R-fp.size+1;

d=zeros(S,fp.size,Q);
for i=1:S,
    d(i,:,:)=p(i+(0:(fp.size-1)),:);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
