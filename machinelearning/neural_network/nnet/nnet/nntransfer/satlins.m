function out1 = satlins(in1,in2,in3,in4)
%SATLINS Symmetric saturating linear transfer function.
%	
%	Syntax
%
%	  A = satlins(N,FP)
%   dA_dN = satlins('dn',N,A,FP)
%	  INFO = satlins(CODE)
%
%	Description
%	
%	  SATLINS is a transfer function.  Transfer functions
%	  calculate a layer's output from its net input.
%	
%	  SATLINS(N,FP) takes N and optional function parameters,
%	    N - SxQ Matrix of net input (column) vectors.
%	    FP - Row cell array of function parameters (ignored).
%	  and returns values of N truncated into the interval [-1, 1].
%	
%	  SATLINS is a neural transfer function.  Transfer functions
%	  calculate a layer's output from its net input.
%
%	  SATLINS(N,FP) takes N and an optional argument,
%	    N - SxQ matrix of net input (column) vectors.
%	    FP - Struct of function parameters (optional, ignored).
%	  and returns A, the SxQ matrix of N's elements clipped to [-1, 1].
%	
%   SATLINS('dn',N,A,FP) returns SxQ derivative of A w-respect to N.
%   If A or FP are not supplied or are set to [], FP reverts to
%   the default parameters, and A is calculated from N.
%
%   SATLINS('name') returns the name of this function.
%   SATLINS('output',FP) returns the [min max] output range.
%   SATLINS('active',FP) returns the [min max] active input range.
%   SATLINS('fullderiv') returns 1 or 0, whether DA_DN is SxSxQ or SxQ.
%   SATLINS('fpnames') returns the names of the function parameters.
%   SATLINS('fpdefaults') returns the default function parameters.
%	
%	Examples
%
%	  Here is the code to create a plot of the SATLINS transfer function.
%	
%	    n = -5:0.1:5;
%	    a = satlins(n);
%	    plot(n,a)
%
%	  Here we assign this transfer function to layer i of a network.
%
%     net.layers{i}.transferFcn = 'satlins';
%
%	Algorithm
%
%	    a = satlins(n) = -1, if n <= -1
%	                      n, if -1 <= n <= 1
%	                      1, if 1 <= n
%
%	See also SIM, SATLIN, POSLIN, PURELIN.

% Mark Beale, 12-15-93
% Revised 11-31-97, MB
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.3 $  $Date: 2008/06/20 08:04:48 $

fn = mfilename;
boiler_transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Symmetric Saturating Linear';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output range
function r = output_range(fp)
r = [-1 +1];
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
a = max(-1,min(1,n));
a(isnan(n)) = nan;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function da_dn = derivative(n,a,fp)
da_dn = double((n >= -1) & (n <= 1));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
