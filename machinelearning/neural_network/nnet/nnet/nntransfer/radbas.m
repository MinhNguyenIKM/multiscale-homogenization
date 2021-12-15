function out1 = radbas(in1,in2,in3,in4)
%RADBAS Radial basis transfer function.
%	
%	Syntax
%
%	  A = radbas(N,FP)
%   dA_dN = radbas('dn',N,A,FP)
%	  INFO = radbas(CODE)
%
%	Description
%	
%	  RADBAS is a neural transfer function.  Transfer functions
%	  calculate a layer's output from its net input.
%
%	  RADBAS(N,FP) takes N and optional function parameters,
%	    N - SxQ matrix of net input (column) vectors.
%	    FP - Struct of function parameters (ignored).
%	  and returns A, an SxQ matrix of the radial basis function
%   applied to each element of N.
%	
%   RADBAS('dn',N,A,FP) returns SxQ derivative of A w-respect to N.
%   If A or FP are not supplied or are set to [], FP reverts to
%   the default parameters, and A is calculated from N.
%
%   RADBAS('name') returns the name of this function.
%   RADBAS('output',FP) returns the [min max] output range.
%   RADBAS('active',FP) returns the [min max] active input range.
%   RADBAS('fullderiv') returns 1 or 0, whether DA_DN is SxSxQ or SxQ.
%   RADBAS('fpnames') returns the names of the function parameters.
%   RADBAS('fpdefaults') returns the default function parameters.
%	
%	Examples
%
%	  Here we create a plot of the RADBAS transfer function.
%	
%	    n = -5:0.1:5;
%	    a = radbas(n);
%	    plot(n,a)
%
%	  Here we assign this transfer function to layer i of a network.
%
%     net.layers{i}.transferFcn = 'radbas';
%
%	Algorithm
%
%	    a = radbas(n) = exp(-n^2)
%
%	See also SIM, TRIBAS, DRADBAS.

% Mark Beale, 12-15-93
% Revised 11-31-97, MB
% Copyright 1992-2005 The MathWorks, Inc.
% $Revision: 1.1.6.2 $  $Date: 2005/12/22 18:21:13 $

fn = mfilename;
boiler_transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Radial Basis';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output range
function r = output_range(fp)
r = [0 1];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Active input range
function r = active_input_range(fp)
r = [-2 +2];
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
a = exp(-(n.*n));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function da_dn = derivative(n,a,fp)
da_dn = (-2)*(n.*a);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
