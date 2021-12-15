function out1 = hardlim(in1,in2,in3,in4)
%HARDLIM Hard limit transfer function.
%	
%	Syntax
%
%	  A = hardlim(N,FP)
%   dA_dN = hardlim('dn',N,A,FP)
%	  INFO = hardlim(CODE)
%
%	Description
%
%	  HARDLIM is a neural transfer function.  Transfer functions
%	  calculate a layer's output from its net input.
%
%	  HARDLIM(N,FP) takes N and optional function parameters,
%	    N - SxQ matrix of net input (column) vectors.
%	    FP - Struct of function parameters (ignored).
%	  and returns A, the SxQ boolean matrix with 1's where N >= 0.
%	
%   HARDLIM('dn',N,A,FP) returns SxQ derivative of A w-respect to N.
%   If A or FP are not supplied or are set to [], FP reverts to
%   the default parameters, and A is calculated from N.
%
%   HARDLIM('name') returns the name of this function.
%   HARDLIM('output',FP) returns the [min max] output range.
%   HARDLIM('active',FP) returns the [min max] active input range.
%   HARDLIM('fullderiv') returns 1 or 0, whether DA_DN is SxSxQ or SxQ.
%   HARDLIM('fpnames') returns the names of the function parameters.
%   HARDLIM('fpdefaults') returns the default function parameters.
%	
%	Examples
%
%	  Here is how to create a plot of the HARDLIM transfer function.
%	
%	    n = -5:0.1:5;
%	    a = hardlim(n);
%	    plot(n,a)
%
%	  Here we assign this transfer function to layer i of a network.
%
%     net.layers{i}.transferFcn = 'hardlim';
%
%	Algorithm
%
%	    hardlim(n) = 1, if n >= 0
%	                 0, otherwise
%
%	See also SIM, HARDLIMS.

% Mark Beale, 1-31-92
% Revised 12-15-93, MB
% Revised 11-31-97, MB
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.3 $  $Date: 2008/06/20 08:04:44 $

fn = mfilename;
boiler_transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Hard Limit';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output range
function r = output_range(fp)
r = [0 1];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Active input range
function r = active_input_range(fp)
r = [0 0];
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
a = double(n >= 0);
a(isnan(n)) = nan;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function da_dn = derivative(n,a,fp)
da_dn = zeros(size(n));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
