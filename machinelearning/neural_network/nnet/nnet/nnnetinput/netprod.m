function out1=netprod(varargin)
%NETPROD Product net input function.
%
%	Syntax
%
%	  N = netprod({Z1,Z2,...,Zn},FP)
%   dN_dZj = netprod('dz',j,Z,N,FP)
%	  INFO = netprod(CODE)
%
%	Description
%
%	  NETPROD is a net input function.  Net input functions
%	  calculate a layer's net input by combining its weighted
%	  inputs and biases.
%
%	  NETPROD({Z1,Z2,...,Zn},FP) takes these arguments,
%	    Zi - SxQ matrices in a row cell array.
%	    FP - Row cell array of function parameters (optional, ignored).
%	  Returns element-wise product of Z1 to Zn.
%
%	  NETPROD(code) returns information about this function.
%	  These codes are defined:
%	    'deriv'      - Name of derivative function.
%     'fullderiv'  - Full NxSxQ derivative = 1, Element-wise SxQ derivative = 0.
%	    'name'       - Full name.
%	    'fpnames'    - Returns names of function parameters.
%	    'fpdefaults' - Returns default function parameters.
%
%	Examples
%
%	  Here NETPROD combines two sets of weighted input
%	  vectors (which we have defined ourselves).
%
%	    z1 = [1 2 4;3 4 1];
%	    z2 = [-1 2 2; -5 -6 1];
%     z = {z1,z2};
%	    n = netprod({z})
%
%	  Here NETPROD combines the same weighted inputs with
%	  a bias vector.  Because Z1 and Z2 each contain three
%	  concurrent vectors, three concurrent copies of B must
%	  be created with CONCUR so that all sizes match up.
%
%	    b = [0; -1];
%     z = {z1, z2, concur(b,3)};
%	    n = netprod(z)
%
%	Network Use
%
%	  You can create a standard network that uses NETPROD
%	  by calling NEWPNN or NEWGRNN.
%
%	  To change a network so that a layer uses NETPROD, set
%	  NET.layers{i}.netInputFcn to 'netprod'.
%
%	  In either case, call SIM to simulate the network with NETPROD.
%	  See NEWPNN or NEWGRNN for simulation examples.
%
%	See also NETWORK/SIM, DNETPROD, NETSUM, CONCUR

% Mark Beale, 11-31-97
% Copyright 1992-2005 The MathWorks, Inc.
% $Revision: 1.1.6.2 $

fn = mfilename;
boiler_net

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Product';
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
  n = n .* z{i};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of N w/respect to Zj
function d = derivative_dn_dzj(j,z,n,fp)
if (length(z) == 1)
  d = ones(size(n));
else
  z(j) = [];
  d = z{1};
  for i=2:length(z)
    d = d .* z{i};
  end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
