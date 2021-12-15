function out1 = compet(in1,in2,in3,in4)
%COMPET Competitive transfer function.
%	
%	Syntax
%
%	  A = compet(N,FP)
%   dA_dN = compet('dn',N,A,FP)
%	  INFO = compet(CODE)
%
%	Description
%	
%	  COMPET is a neural transfer function.  Transfer functions
%	  calculate a layer's output from its net input.
%
%	  COMPET(N,FP) takes N and optional function parameters,
%	    N - SxQ matrix of net input (column) vectors.
%	    FP - Struct of function parameters (ignored).
%	  and returns SxQ matrix A with a 1 in each column where
%	  the same column of N has its maximum value, and 0 elsewhere.
%	
%   COMPET('dn',N,A,FP) returns derivative of A w-respect to N.
%   If A or FP are not supplied or are set to [], FP reverts to
%   the default parameters, and A is calculated from N.
%
%   COMPET('name') returns the name of this function.
%   COMPET('output',FP) returns the [min max] output range.
%   COMPET('active',FP) returns the [min max] active input range.
%   COMPET('fullderiv') returns 1 or 0, whether DA_DN is SxSxQ or SxQ.
%   COMPET('fpnames') returns the names of the function parameters.
%   COMPET('fpdefaults') returns the default function parameters.
%	
%	Examples
%
%	  Here we define a net input vector N, calculate the output,
%	  and plot both with bar graphs.
%
%	    n = [0; 1; -0.5; 0.5];
%	    a = compet(n);
%	    subplot(2,1,1), bar(n), ylabel('n')
%	    subplot(2,1,2), bar(a), ylabel('a')
%
%	  Here we assign this transfer function to layer i of a network.
%
%     net.layers{i}.transferFcn = 'compet';
%
%	See also SIM, SOFTMAX.

% Mark Beale, 1-31-92
% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.3 $  $Date: 2008/06/20 08:04:43 $

fn = mfilename;
boiler_transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Competitive';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output range
function r = output_range(fp)
r = [0 1];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Active input range
function r = active_input_range(fp)
r = [-inf inf];
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
[S,Q] = size(n);
sumn = sum(n,1);
nanIndex = find(isnan(sumn));
[maxn,rows] = max(n,[],1);
cols = 1:Q;
rows(nanIndex) = [];
cols(nanIndex) = [];
numNaN = length(nanIndex);
numReal = Q - numNaN;
nanValues = nan(1,numNaN*S);
nanRows = repmat(1:S,1,numNaN);
nanCols = reshape(repmat(nanIndex,S,1),1,S*numNaN);
a = sparse([rows nanRows],[cols nanCols],[ones(1,numReal) nanValues],S,Q);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function da_dn = derivative(n,a,fp)
da_dn = zeros(size(a));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
