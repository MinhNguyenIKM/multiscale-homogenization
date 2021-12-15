function out1 = tribas(in1,in2,in3,in4)
%TRIBAS Triangular basis transfer function.
%	
%	Syntax
%
%	  A = tribas(N,FP)
%   dA_dN = tribas('dn',N,A,FP)
%	  INFO = tribas(CODE)
%
%	Description
%	
%	  TRIBAS is a neural transfer function.  Transfer functions
%	  calculate a layer's output from its net input.
%
%	  TRIBAS(N,FP) takes N and optional function parameters,
%	    N - SxQ matrix of net input (column) vectors.
%	    FP - Struct of function parameters (ignored).
%	  and returns A, an SxQ matrix of the triangular basis function
%   applied to each element of N.
%	
%   TRIBAS('dn',N,A,FP) returns SxQ derivative of A w-respect to N.
%   If A or FP are not supplied or are set to [], FP reverts to
%   the default parameters, and A is calculated from N.
%
%   TRIBAS('name') returns the name of this function.
%   TRIBAS('output',FP) returns the [min max] output range.
%   TRIBAS('active',FP) returns the [min max] active input range.
%   TRIBAS('fullderiv') returns 1 or 0, whether DA_DN is SxSxQ or SxQ.
%   TRIBAS('fpnames') returns the names of the function parameters.
%   TRIBAS('fpdefaults') returns the default function parameters.
%	
%	Examples
%
%	  Here we create a plot of the TRIBAS transfer function.
%	
%	    n = -5:0.1:5;
%	    a = tribas(n);
%	    plot(n,a)
%
%	  Here we assign this transfer function to layer i of a network.
%
%     net.layers{i}.transferFcn = 'tribas';
%
%	Algorithm
%
%	    a = tribas(n) = 1 - abs(n), if -1 <= n <= 1
%                   = 0, otherwise
%
%	See also SIM, RADBAS.

% Mark Beale, 11-31-97
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.3 $

fn = mfilename;
boiler_transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Triangle Basis';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output range
function r = output_range(fp)
r = [0 1];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Active input range
function r = active_input_range(fp)
r = [-1 +1];
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
a = max(0,1-abs(n));
a(isnan(n)) = nan;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function da_dn = derivative(n,a,fp)
da_dn = (abs(n) <= 1) .* sign(-n);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
