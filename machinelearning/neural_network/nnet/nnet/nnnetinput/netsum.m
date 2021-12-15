function out1=netsum(varargin)
%NETSUM Sum net input function.
%
%	Syntax
%
%	  N = netsum({Z1,Z2,...,Zn},FP)
%   dN_dZj = netsum('dz',j,Z,N,FP)
%	  INFO = netsum(CODE)
%
%	Description
%
%	  NETSUM is a net input function.  Net input functions calculate
%	  a layer's net input by combining its weighted inputs and bias.
%
%	  NETSUM({Z1,Z2,...,Zn},FP) takes Z1-Zn and optional function parameters,
%	    Zi - SxQ matrices in a row cell array.
%	    FP - Row cell array of function parameters (ignored).
%	  Returns element-wise sum of Z1 to Zn.
%
%   NETSUM('dz',j,{Z1,...,Zn},N,FP) returns the derivative of N with
%   respect to Zj.  If FP is not supplied the default values are used.
%   if N is not supplied, or is [], it is calculated for you.
%
%	  NETSUM('name') returns the name of this function.
%	  NETSUM('type') returns the type of this function.
%   NETSUM('fpnames') returns the names of the function parameters.
%   NETSUM('fpdefaults') returns default function parameter values.
%   NETSUM('fpcheck',FP) throws an error for illegal function parameters.
%	  NETSUM('fullderiv') returns 0 or 1, if the derivate is SxQ or NxSxQ.
%
%	Examples
%
%	  Here NETSUM combines two sets of weighted input vectors and a bias.
%   We must use CONCUR to make B the same dimensions as Z1 and Z2. 
%
%	    z1 = [1 2 4; 3 4 1]
%	    z2 = [-1 2 2; -5 -6 1]
%	    b = [0; -1]
%	    n = netsum({z1,z2,concur(b,3)})
%
%	  Here we assign this net input function to layer i of a network.
%
%     net.layers{i}.netFcn = 'compet';
%
%   Use NEWP or NEWLIN to create a standard network that uses NETSUM.
%
%	See also NETPROD, NETINV, NETNORMALIZED

% Mark Beale, 11-31-97
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.3 $

fn = mfilename;
boiler_net

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Sum';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Defaults
function fp = param_defaults(values)
fp = struct;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Names
function names = param_names
names = {};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Check
function err = param_check(fp)
err = '';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Apply Net Function
function n = apply(z,fp)
n = z{1};
for i=2:length(z)
  n = n + z{i};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of N w/respect to Zj
function d = derivative_dn_dzj(j,z,n,fp)
d = ones(size(n));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
