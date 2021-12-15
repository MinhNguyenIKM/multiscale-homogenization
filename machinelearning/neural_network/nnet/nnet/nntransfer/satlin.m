function out1 = satlin(in1,in2,in3,in4)
%SATLIN Saturating linear transfer function.
%	
%	Syntax
%
%	  A = satlin(N,FP)
%   dA_dN = satlin('dn',N,A,FP)
%	  INFO = satlin(CODE)
%
%	Description
%	
%	  SATLIN is a neural transfer function.  Transfer functions
%	  calculate a layer's output from its net input.
%
%	  SATLIN(N,FP) takes N and optional function parameters,
%	    N - SxQ matrix of net input (column) vectors.
%	    FP - Struct of function parameters (ignored).
%	  and returns A, the SxQ matrix of N's elements clipped to [0, 1].
%	
%   SATLIN('dn',N,A,FP) returns SxQ derivative of A w-respect to N.
%   If A or FP are not supplied or are set to [], FP reverts to
%   the default parameters, and A is calculated from N.
%
%   SATLIN('name') returns the name of this function.
%   SATLIN('output',FP) returns the [min max] output range.
%   SATLIN('active',FP) returns the [min max] active input range.
%   SATLIN('fullderiv') returns 1 or 0, whether DA_DN is SxSxQ or SxQ.
%   SATLIN('fpnames') returns the names of the function parameters.
%   SATLIN('fpdefaults') returns the default function parameters.
%	
%	Examples
%
%	  Here is the code to create a plot of the SATLIN transfer function.
%	
%	    n = -5:0.1:5;
%	    a = satlin(n);
%	    plot(n,a)
%
%	  Here we assign this transfer function to layer i of a network.
%
%     net.layers{i}.transferFcn = 'satlin';
%
%	Algorithm
%
%	    a = satlin(n) = 0, if n <= 0
%	                    n, if 0 <= n <= 1
%	                    1, if 1 <= n
%
%	See also SIM, POSLIN, SATLINS, PURELIN.

% Mark Beale, 1-31-92
% Revised 12-15-93, MB
% Revised 11-31-97, MB
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.3 $  $Date: 2008/06/20 08:04:47 $

fn = mfilename;
boiler_transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Saturating Linear';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output range
function r = output_range(fp)
r = [0 1];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Active input range
function r = active_input_range(fp)
r = [0 1];
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
a = max(0,min(1,n));
a(isnan(n)) = nan;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function da_dn = derivative(n,a,fp)
da_dn = double((n >= 0) & (n <= 1));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
