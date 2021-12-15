function result = mandist(a,b,c,d,e)
%MANDIST Manhattan distance weight function.
%
%	Syntax
%
%	  Z = mandist(W,P,FP)
%	  info = mandist(code)
%	  dim = mandist('size',S,R,FP)
%	  dp = mandist('dp',W,P,Z,FP)
%	  dw = mandist('dw',W,P,Z,FP)
%	  D = mandist(pos);
%
%	Description
%
%	  MANDIST is the Manhattan distance weight function. Weight
%	  functions apply weights to an input to get weighted inputs.
%
%	  MANDIST(W,P,FP) takes these inputs,
%	    W - SxR weight matrix.
%	    P - RxQ matrix of Q input (column) vectors.
%	    FP - Row cell array of function parameters (optional, ignored).
%	  and returns the SxQ matrix of vector distances.
%
%	  MANDIST(code) returns information about this function.
%	  These codes are defined:
%	    'deriv'      - Name of derivative function.
%	    'fullderiv'  - Full derivative = 1, linear derivative = 0.
%	    'name'       - Full name.
%	    'fpnames'    - Returns names of function parameters.
%	    'fpdefaults' - Returns default function parameters.
%
%	  MANDIST('size',S,R,FP) takes the layer dimension S, input dimension R,
%	  and function parameters, and returns the weight size [SxR].
%
%	  MANDIST('dp',W,P,Z,FP) returns the derivative of Z with respect to P.
%	  MANDIST('size',S,R,FP) returns the derivative of Z with respect to W.
%
%	  MANDIST is also a layer distance function which can be used
%	  to find distances between neurons in a layer.
%
%	  MANDIST(POS) takes one argument,
%	    POS - S row matrix of neuron positions.
%	  and returns the SxS matrix of distances.
%
%	Examples
%
%	  Here we define a random weight matrix W and input vector P
%	  and calculate the corresponding weighted input Z.
%
%	    W = rand(4,3);
%	    P = rand(3,1);
%	    Z = mandist(W,P)
%
%	  Here we define a random matrix of positions for 10 neurons
%	  arranged in three dimensional space and then find their distances.
%
%	    pos = rand(3,10);
%	    D = mandist(pos)
%
%	Network Use
%
%	  You can create a standard network that uses MANDIST
%	  as a distance function by calling NEWSOM.
%
%	  To change a network so an input weight uses MANDIST set
%	  NET.inputWeight{i,j}.weightFcn to 'mandist.  For a layer weight
%	  set NET.inputWeight{i,j}.weightFcn to 'mandist'.
%
%	  To change a network so a layer's topology uses MANDIST set
%	  NET.layers{i}.distanceFcn to 'mandist'.
%
%	  In either case, call SIM to simulate the network with DIST.
%	  See NEWPNN or NEWGRNN for simulation examples.
%
%	Algorithm
%
%	  The Manhattan distance D between two vectors X and Y is:
%	
%	    D = sum(abs(x-y))
%
%	See also SIM, DIST, LINKDIST.

% Mark Beale, 12-15-93
% Revised 11-31-97, MB
% Mark Hudson Beale, improvements, 01-08-2001
% Orlando De Jesus, code fix, 02-12-2002
% Updated by Orlando De Jesús, Martin Hagan, for derivatives 7-20-05
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.5 $  $Date: 2007/11/09 20:53:13 $

fn = mfilename;
boiler_weight

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Manhattan Distance';
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
    z(:,q) = sum(abs(w-p(q+copies,:)),2);
  end
else
  w = w';
  copies = zeros(1,Q);
  for i=1:S
    z(i,:) = sum(abs(w(:,i+copies)-p),1);
  end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative w/respect to Input
function dp = derivative_dz_dp(w,p,z,fp)
[S,R] = size(w);
[R2,Q] = size(p);
dp = cell(1,Q);
p = p';
copies = zeros(1,S);
for q=1:Q
  dp{q} = sign(p(q+copies,:)-w);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative w/respect to Weight
function dz = derivative_dz_dw(w,p,z,fp)
[S,R] = size(w);
[R2,Q] = size(p);
dz = cell(1,S);
w = w';
copies = zeros(1,Q);
for i=1:S
  dz{i} = sign(w(:,i+copies)-p);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
