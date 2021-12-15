function out1 = logsig(in1,in2,in3,in4)
%LOGSIG Logarithmic sigmoid transfer function.
%	
%	Syntax
%
%	  A = logsig(N,FP)
%   dA_dN = logsig('dn',N,A,FP)
%	  INFO = logsig(CODE)
%
%	Description
%
%	  LOGSIG(N,FP) takes N and optional function parameters,
%	    N - SxQ matrix of net input (column) vectors.
%	    FP - Struct of function parameters (ignored).
%	  and returns A, the SxQ matrix of N's elements squashed into [0, 1].
%	
%   LOGSIG('dn',N,A,FP) returns SxQ derivative of A w-respect to N.
%   If A or FP are not supplied or are set to [], FP reverts to
%   the default parameters, and A is calculated from N.
%
%   LOGSIG('name') returns the name of this function.
%   LOGSIG('output',FP) returns the [min max] output range.
%   LOGSIG('active',FP) returns the [min max] active input range.
%   LOGSIG('fullderiv') returns 1 or 0, whether DA_DN is SxSxQ or SxQ.
%   LOGSIG('fpnames') returns the names of the function parameters.
%   LOGSIG('fpdefaults') returns the default function parameters.
%
%	Examples
%
%	  Here is code for creating a plot of the LOGSIG transfer function.
%	
%	    n = -5:0.1:5;
%	    a = logsig(n);
%	    plot(n,a)
%
%	  Here we assign this transfer function to layer i of a network.
%
%     net.layers{i}.transferFcn = 'logsig';
%
%	Algorithm
%
%	    logsig(n) = 1 / (1 + exp(-n))
%
%	See also SIM, DLOGSIG, TANSIG.

% Mark Beale, 1-31-92
% Revised 12-15-93, MB
% Revised 11-31-97, MB
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.6 $  $Date: 2007/11/09 20:53:04 $

fn = mfilename;
boiler_transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Log Sigmoid';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output range
function r = output_range(fp)
r = [0 1];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Active input range
function r = active_input_range(fp)
r = [-4 +4];
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
a = 1 ./ (1 + exp(-n));
i = find(~isfinite(a));
a(i) = sign(n(i));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function da_dn = derivative(n,a,fp)
da_dn = a.*(1-a);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
