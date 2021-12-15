function result = negdist(a,b,c,d,e)
%NEGDIST Negative distance weight function.
%
%	Syntax
%
%	  Z = negdist(W,P,FP)
%	  info = negdist(code)
%     dim = normprod('size',S,R,FP)
%     dp = normprod('dp',W,P,Z,FP)
%     dw = normprod('dw',W,P,Z,FP)
%
%	Description
%
%	  NEGDIST is a weight function.  Weight functions apply
%	  weights to an input to get weighted inputs.
%
%	  NEGDIST(W,P,FP) takes these inputs,
%	    W - SxR weight matrix.
%	    P - RxQ matrix of Q input (column) vectors.
%	    FP - Row cell array of function parameters (optional, ignored).
%	  and returns the SxQ matrix of negative vector distances.
%
%	  NEGDIST(code) returns information about this function.
%	  These codes are defined:
%	    'deriv'      - Name of derivative function.
%       'fullderiv'  - Full derivative = 1, linear derivative = 0.
%	    'name'       - Full name.
%	    'fpnames'    - Returns names of function parameters.
%	    'fpdefaults' - Returns default function parameters.
%
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
%	    Z = negdist(W,P)
%
%	Network Use
%
%	  You can create a standard network that uses NEGDIST
%	  by calling NEWC or NEWSOM.
%
%	  To change a network so an input weight uses NEGDIST, set
%	  NET.inputWeight{i,j}.weightFcn to 'negdist'.  For a layer weight
%	  set NET.inputWeight{i,j}.weightFcn to 'negdist'.
%
%	  In either case, call SIM to simulate the network with NEGDIST.
%	  See NEWC or NEWSOM for simulation examples.
%
%	Algorithm
%
%	  NEGDIST returns the negative Euclidean distance:
%
%	    z = -sqrt(sum(w-p)^2)
%
%	See also SIM, DOTPROD, DIST

% Mark Beale, 11-31-97
% Mark Hudson Beale, improvements, 01-08-2001
% Orlando De Jesus, code fix, 02-12-2002
% Updated by Orlando De Jesús, Martin Hagan, updated for derivatives 7-20-05
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.5 $

fn = mfilename;
boiler_weight

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Negative Distance';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Flag for dZ/dP type
function d = p_deriv
d = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Flag for dZ/dW type
function d = w_deriv
d = 1;
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
if (R ~= R2), error('NNET:Dimensions','Inner matrix dimensions do not match.'),end
z = zeros(S,Q);
if (Q<S)
  p = p';
  copies = zeros(1,S);
  for q=1:Q
    z(:,q) = sum((w-p(q+copies,:)).^2,2);
  end
else
  w = w';
  copies = zeros(1,Q);
  for i=1:S
    z(i,:) = sum((w(:,i+copies)-p).^2,1);
  end
end
z = -z.^0.5;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative w/respect to Input
function d = derivative_dz_dp(w,p,z,fp)
[S,R] = size(w);
[R2,Q] = size(p);
p = p';
d = cell(1,Q);
copies1 = zeros(1,S);
copies2 = zeros(R,1);
for q=1:Q
  den = z(:,q+copies2);
  flg = den~=0;
  num = (p(q+copies1,:)-w);
  num = flg.*num;
  den = den + ~flg;
  d{q} = num./den;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative w/respect to Weight
function d = derivative_dz_dw(w,p,z,fp)
[S,R] = size(w);
[R2,Q] = size(p);
d = cell(1,S);
w = w';
copies1 = zeros(1,Q);
copies2 = zeros(R,1);
for i=1:S 
  den = z(i+copies2,:);
  flg = den~=0;
  num = w(:,i+copies1)-p;
  num = flg.*num;
  den = den + ~flg;
  d{i} = num./den;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
