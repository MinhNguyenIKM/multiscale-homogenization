function result = normprod(a,b,c,d,e)
%NORMPROD Normalized dot product weight function.
%
%	Syntax
%
%	  Z = normprod(W,P,FP)
%	  info = normprod(code)
%     dim = normprod('size',S,R,FP)
%     dp = normprod('dp',W,P,Z,FP)
%     dw = normprod('dw',W,P,Z,FP)
%
%	Description
%
%	  NORMPROD is a weight function.  Weight functions apply
%	  weights to an input to get weighted inputs.
%
%	  NORMPROD(W,P,FP) takes these inputs,
%	    W - SxR weight matrix.
%	    P - RxQ matrix of Q input (column) vectors.
%	    FP - Row cell array of function parameters (optional, ignored).
%	  and returns the SxQ matrix of normalized dot products.
%
%	  NORMPROD(code) returns information about this function.
%	  These codes are defined:
%	    'deriv'      - Name of derivative function.
%       'pfullderiv' - Full input derivative = 1, linear input derivative = 0.
%       'wfullderiv' - Full weight derivative = 1, linear weight derivative = 0.
%	    'name'       - Full name.
%	    'fpnames'    - Returns names of function parameters.
%	    'fpdefaults' - Returns default function parameters.
%
%   NORMPROD('size',S,R,FP) takes the layer dimension S, input dimension R,
%   and function parameters, and returns the weight size [SxR].
%
%   NORMPROD('dp',W,P,Z,FP) returns the derivative of Z with respect to P.
%   NORMPROD('size',S,R,FP) returns the derivative of Z with respect to W.
%
%	Examples
%
%	  Here we define a random weight matrix W and input vector P
%	  and calculate the corresponding weighted input Z.
%
%	    W = rand(4,3);
%	    P = rand(3,1);
%	    Z = normprod(W,P)
%
%	Network Use
%
%	  You can create a standard network that uses NORMPROD
%	  by calling NEWGRNN.
%
%	  To change a network so an input weight uses NORMPROD, set
%	  NET.inputWeight{i,j}.weightFcn to 'normprod.  For a layer weight
%	  set NET.inputWeight{i,j}.weightFcn to 'normprod.
%
%	  In either case, call SIM to simulate the network with NORMPROD.
%	  See NEWGRNN for simulation examples.
%
%	Algorithm
%
%	  NORMPROD returns the dot product normalized by the sum
%	  of the input vector elements.
%
%	    z = w*p/sum(p)
%
%	See also DOTPROD.

% Mark Beale, 11-31-97
% Mark Hudson Beale, improvements, 01-08-2001
% Orlando De Jesus, code fix, 02-12-2002
% Updated by Orlando De Jesús, Martin Hagan, 7-20-05
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.5 $

fn = mfilename;
boiler_weight

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Normalized Dot Product';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Flag for dZ/dP type
function d = p_deriv
d = 1;
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
[S,R] = size(w);
[R2,Q] = size(p);
if (R ~= R2), error('NNET:Dimensions','Inner matrix dimensions do not match.'), end
sump = sum(p,1);
i = find(abs(sump) < 1e-30);
sump(i) = (sump(i)>=0)*1e-30 + (sump(i)<0)*-1e-30;
z = w * (p ./ sump(ones(1,R),:));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative w/respect to Input
function d = derivative_dz_dp(w,p,z,fp)
[S,R] = size(w);
[R2,Q] = size(p);
sump = sum(p,1);
i = find(abs(sump) < 1e-30);
sump(i) = (sump(i)>=0)*1e-30 + (sump(i)<0)*-1e-30;
dprod = w * p;
d = cell(1,Q);
for q=1:Q
  sumpq = sump(q);
  sumpq2 = sumpq^2;
  if (sumpq2 == 0)
    d{q} = zeros(S,R);
  else
    d{q}=(w*sumpq-dprod(:,zeros(1,R)+q))./(sumpq2);
  end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative w/respect to Weight
function d = derivative_dz_dw(w,p,z,fp)
[S,R] = size(w);
[R2,Q] = size(p);
sump = sum(p,1);
dprod = w * p;
d = zeros(R,Q);
q = find(sump ~= 0);
d(:,q) = p(:,q) ./ sump(ones(1,R),q);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
