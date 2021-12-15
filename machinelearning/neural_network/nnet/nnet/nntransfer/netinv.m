function out1 = netinv(in1,in2,in3,in4)
%NETINV Inverse transfer function.
%  
%  Syntax
%
%    A = netinv(N,FP)
%    dA_dN = netinv('dn',N,A,FP)
%    info = netinv(code)
%
%  Description
%  
%    NETINV is a transfer function.  Transfer functions
%    calculate a layer's output from its net input.
%  
%    NETINV(N,FP) takes inputs,
%     N - SxQ matrix of net input (column) vectors.
%     FP - Struct of function parameters (ignored).
%    and returns 1/N.
%  
%    NETINV('dn',N,A,FP) returns derivative of A w-respect to N.
%    If A or FP are not supplied or are set to [], FP reverts to
%    the default parameters, and A is calculated from N.
%
%    NETINV('name') returns the name of this function.
%    NETINV('output',FP) returns the [min max] output range.
%    NETINV('active',FP) returns the [min max] active input range.
%    NETINV('fullderiv') returns 1 or 0, whether DA_DN is SxSxQ or SxQ.
%    NETINV('fpnames') returns the names of the function parameters.
%    NETINV('fpdefaults') returns the default function parameters.
%
% Examples
%
%   Here we define 10 5-element net input vectors N, and calculate A.
%
%     n = rand(5,10);
%     a = netinv(n);
%
%   Here we assign this transfer function to layer i of a network.
%
%     net.layers{i}.transferFcn = 'netinv';
%
% See also TANSIG, LOGSIG

% Orlando De Jesus, Martin Hagan, 8-8-99
% Updated by Orlando De Jesús, Martin Hagan, 7-20-05
% Copyright 1992-2005 The MathWorks, Inc.
% $Revision: 1.1.6.2 $ $Date: 2005/12/22 18:21:10 $

fn = mfilename;
boiler_transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name

n = 'Inverse';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output range
function r = output_range(fp)

r = [-inf +inf];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Active input range
function r = active_input_range(fp)

r = [-inf +inf];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Defaults
function fp = param_defaults

fp = struct;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Names
function names = param_names

names = {};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Check
function err = param_check(fp)

err = '';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Apply Transfer Function
function a = apply_transfer(n,fp)

i = find(abs(n)<1e-30);
n(i) = (n(i)>=0)*1e-30 + (n(i)<0)*-1e-30;
a = 1./n;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function da_dn = derivative(n,a,fp)

i = find(abs(n)<1e-30);
n(i) = (n(i)>=0)*1e-30 + (n(i)<0)*-1e-30;
da_dn = -1./(n.^2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
