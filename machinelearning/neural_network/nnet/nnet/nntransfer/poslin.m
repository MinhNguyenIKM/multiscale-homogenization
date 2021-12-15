function out1 = poslin(in1,in2,in3,in4)
%POSLIN Positive linear transfer function.
%	
%	Syntax
%
%	  A = poslin(N,FP)
%	  dA_dN = poslin('dn',N,A,FP)
%	  INFO = poslin(CODE)
%
%	Description
%	
%	  POSLIN is a neural transfer function.  Transfer functions
%	  calculate a layer's output from its net input.
%
%	  POSLIN(N,FP) takes N and optional function parameters,
%	    N - SxQ matrix of net input (column) vectors.
%	    FP - Struct of function parameters (ignored).
%	  and returns A, the SxQ matrix of N's elements clipped to [0, inf].
%	
%	  POSLIN('dn',N,A,FP) returns SxQ derivative of A w-respect to N.
%	  If A or FP are not supplied or are set to [], FP reverts to
%	  the default parameters, and A is calculated from N.
%
%	  POSLIN('name') returns the name of this function.
%	  POSLIN('output',FP) returns the [min max] output range.
%	  POSLIN('active',FP) returns the [min max] active input range.
%	  POSLIN('fullderiv') returns 1 or 0, whether DA_DN is SxSxQ or SxQ.
%	  POSLIN('fpnames') returns the names of the function parameters.
%	  POSLIN('fpdefaults') returns the default function parameters.
%	
%	Examples
%
%	  Here the code to create a plot of the POSLIN transfer function.
%	
%	    n = -5:0.1:5;
%	    a = poslin(n);
%	    plot(n,a)
%
%	  Here we assign this transfer function to layer i of a network.
%
%	    net.layers{i}.transferFcn = 'poslin';
%
%	Algorithm
%
%	    poslin(n) = n, if n >= 0
%	              = 0, if n <= 0
%
%	See also SIM, PURELIN, SATLIN, SATLINS.

% Revised 11-31-97, MB
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.3 $

fn = mfilename;
boiler_transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Positive Linear';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output range
function r = output_range(fp)
r = [0 inf];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Active input range
function r = active_input_range(fp)
r = [0 inf];
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
a = max(0,n);
a(isnan(n)) = nan;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function da_dn = derivative(n,a,fp)
da_dn = double(n >= 0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
