function out1 = tansig(in1,in2,in3,in4)
%TANSIG Hyperbolic tangent sigmoid transfer function.
% 
% Syntax
%
%   A = tansig(N,FP)
%   dA_dN = tansig('dn',N,A,FP)
%   INFO = tansig(CODE)
%
% Description
% 
%   TANSIG is a neural transfer function.  Transfer functions
%   calculate a layer's output from its net input.
%
%   TANSIG(N,FP) takes N and optional function parameters,
%     N - SxQ matrix of net input (column) vectors.
%     FP - Struct of function parameters (ignored).
%   and returns A, the SxQ matrix of N's elements squashed into [-1 1].
% 
%   TANSIG('dn',N,A,FP) returns derivative of A w-respect to N.
%   If A or FP are not supplied or are set to [], FP reverts to
%   the default parameters, and A is calculated from N.
%
%   TANSIG('name') returns the name of this function.
%   TANSIG('output',FP) returns the [min max] output range.
%   TANSIG('active',FP) returns the [min max] active input range.
%   TANSIG('fullderiv') returns 1 or 0, whether DA_DN is SxSxQ or SxQ.
%   TANSIG('fpnames') returns the names of the function parameters.
%   TANSIG('fpdefaults') returns the default function parameters.
%
% Examples
%
%   Here the code to create a plot of the TANSIG transfer function.
% 
%     n = -5:0.1:5;
%     a = tansig(n);
%     plot(n,a)
%
%   Here we assign this transfer function to layer i of a network.
%
%     net.layers{i}.transferFcn = 'tansig';
%
% Algorithm
%
%     a = tansig(n) = 2/(1+exp(-2*n))-1
%
%   This is mathematically equivalent to TANH(N).  It differs
%   in that it runs faster than the MATLAB implementation of TANH,
%   but the results can have very small numerical differences.  This
%   function is a good trade off for neural networks, where speed is
%   important and the exact shape of the transfer function is not.
%
% See also SIM, LOGSIG.

% Mark Beale, 1-31-92
% Revised 12-15-93, MB
% Revised 11-31-97, MB
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.6 $  $Date: 2007/11/09 20:53:06 $

fn = mfilename;
boiler_transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Symmetric Tan Sigmoid';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output range
function r = output_range(fp)
r = [-1 +1];
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
a = 2 ./ (1 + exp(-2*n)) - 1;
i = find(~isfinite(a));
a(i) = sign(n(i));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function da_dn = derivative(n,a,fp)
da_dn = 1-(a.*a);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
