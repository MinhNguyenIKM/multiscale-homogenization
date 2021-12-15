function out1 = purelin(in1,in2,in3,in4)
%PURELIN Linear transfer function.
%	
%	Syntax
%
%	  A = purelin(N,FP)
%   dA_dN = purelin('dn',N,A,FP)
%	  INFO = purelin(CODE)
%
%	Description
%	
%	  PURELIN is a neural transfer function.  Transfer functions
%	  calculate a layer's output from its net input.
%
%	  PURELIN(N,FP) takes N and optional function parameters,
%	    N - SxQ matrix of net input (column) vectors.
%	    FP - Struct of function parameters (ignored).
%	  and returns A, an SxQ matrix equal to N.
%	
%   PURELIN('dn',N,A,FP) returns SxQ derivative of A w-respect to N.
%   If A or FP are not supplied or are set to [], FP reverts to
%   the default parameters, and A is calculated from N.
%
%   PURELIN('name') returns the name of this function.
%   PURELIN('output',FP) returns the [min max] output range.
%   PURELIN('active',FP) returns the [min max] active input range.
%   PURELIN('fullderiv') returns 1 or 0, whether DA_DN is SxSxQ or SxQ.
%   PURELIN('fpnames') returns the names of the function parameters.
%   PURELIN('fpdefaults') returns the default function parameters.
%	
%	Examples
%
%	  Here is the code to create a plot of the PURELIN transfer function.
%	
%	    n = -5:0.1:5;
%	    a = purelin(n);
%	    plot(n,a)
%
%	  Here we assign this transfer function to layer i of a network.
%
%     net.layers{i}.transferFcn = 'purelin';
%
%	Algorithm
%
%	    a = purelin(n) = n
%
%	See also SIM, DPURELIN, SATLIN, SATLINS.

% Mark Beale, 1-31-92
% Revised 12-15-93, MB
% Revised 11-31-97, MB
% Copyright 1992-2005 The MathWorks, Inc.
% $Revision: 1.1.6.2 $  $Date: 2005/12/22 18:21:12 $

fn = mfilename;
boiler_transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Linear';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output range
function r = output_range(fp)
r = [-inf +inf];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Active input range
function r = active_input_range(fp)
r = [-inf +inf];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Defaults
function fp = param_defaults(values)
fp = struct;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Names
function names = param_names
names = {};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Check
function err = param_check(fp)
err = '';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Apply Transfer Function
function a = apply_transfer(n,fp)
a = n;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function da_dn = derivative(n,a,fp)
da_dn = ones(size(n));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
