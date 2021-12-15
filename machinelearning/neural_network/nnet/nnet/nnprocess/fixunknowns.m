function [out1,out2] = fixunknowns(in1,in2,in3,in4,varargin)
%FIXUNKNOWNS Processes matrix rows with unknown values.
%	
%	Syntax
%
%	  [y,ps] = fixunknowns(x)
%	  [y,ps] = fixunknowns(x,fp)
%	  y = fixunknowns('apply',x,ps)
%	  x = fixunknowns('reverse',y,ps)
%	  dx_dy = fixunknowns('dx',x,y,ps)
%	  dx_dy = fixunknowns('dx',x,[],ps)
%	  name = fixunknowns('name');
%	  fp = fixunknowns('pdefaults');
%	  names = fixunknowns('pnames');
%	  fixunknowns('pcheck',fp);
%
%	Description
%	
%	FIXUNKNOWNS processes matrixes by replacing each row containing
%   unknown values (represented by NaN) with two rows of information.
%   The first row contains the origonal row, with NaN values replaced
%   by the row's mean.  The second row contains 1 and 0 values, indicating
%   which values in the first row were known or unknown, respectively.
%	  
%	FIXUNKNOWNS(X) takes these inputs,
%	X - Single NxQ matrix or a 1xTS row cell array of NxQ matrices.
%	and returns,
%     Y - Each MxQ matrix with M-N rows added (optional).
%     PS - Process settings, to allow consistent processing of values.
%
%   FIXUNKNOWNS(X,FP) takes empty struct FP of parameters.
%   FIXUNKNOWNS('apply',X,PS) returns Y, given X and settings PS.
%   FIXUNKNOWNS('reverse',Y,PS) returns X, given Y and settings PS.
%   FIXUNKNOWNS('dx',X,Y,PS) returns MxNxQ derivative of Y w/respect to X.
%   FIXUNKNOWNS('dx',X,[],PS)  returns the derivative, less efficiently.
%   FIXUNKNOWNS('name') returns the name of this process method.
%   FIXUNKNOWNS('pdefaults') returns default process parameter structure.
%   FIXUNKNOWNS('pdesc') returns the process parameter descriptions.
%   FIXUNKNOWNS('pcheck',fp) throws an error if any parameter is illegal.
%
%	Examples
%
%   Here is how to format a matrix with a mixture of known and
%   unknown values in its second row.
%	
%     x1 = [1 2 3 4; 4 NaN 6 5; NaN 2 3 NaN]
%     [y1,ps] = fixunknowns(x1)
%
%   Next, we apply the same processing settings to new values.
%
%     x2 = [4 5 3 2; NaN 9 NaN 2; 4 9 5 2]
%     y2 = fixunknowns('apply',x2,ps)
%
%   Here we reverse the processing of y1 to get x1 again.
%
%     x1_again = fixunknowns('reverse',y1,ps)
%
%  See also MAPMINMAX, MAPSTD, PROCESSPCA, REMOVECONSTANTROWS

% Copyright 1992-2007 The MathWorks, Inc.

% Mark Hudson Beale, 4-16-2002, Created

% Process function boiler plate script
boiler_process

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Fix Unknowns';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Defaults
function fp = param_defaults(values)
fp = struct;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Names
function names = param_names()
names = {};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Check
function err = param_check(fp)
err = '';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% New Process
function [y,ps] = new_process(x,fp)

ps.name = 'fixunknowns';
unknown_rows = ~isfinite(sum(x,2))';
ps.xrows = size(x,1);
ps.yrows = ps.xrows + sum(unknown_rows);
ps.unknown = find(unknown_rows);
ps.known = find(~unknown_rows);
ps.shift = [0 cumsum(unknown_rows(1:(end-1)))];
numUnknown = length(ps.unknown);
ps.xmeans = zeros(ps.xrows,1);
for i=1:ps.xrows
  finite_unknowns = isfinite(x(i,:));
  if any(finite_unknowns)
    ps.xmeans(i) = mean(x(i,finite_unknowns));
  else
    ps.xmeans(i) = 0;
  end
end

y = apply_process(x,ps);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Apply Process
function y = apply_process(x,ps)

q = size(x,2);
y = zeros(ps.yrows,q);
y(ps.known+ps.shift(ps.known),:) = x(ps.known,:);
unknown_rows = x(ps.unknown,:);
is_known = isfinite(unknown_rows);
is_not_known = ~is_known;
unknown_means = ps.xmeans(ps.unknown,ones(1,q));
unknown_rows(is_not_known) = unknown_means(is_not_known);
y(ps.unknown+ps.shift(ps.unknown),:) = unknown_rows;
y(ps.unknown+ps.shift(ps.unknown)+1,:) = is_known;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Reverse Process
function x = reverse_process(y,ps)

q = size(y,2);
x = zeros(ps.xrows,q);
x(ps.known,:) = y(ps.known+ps.shift(ps.known),:);
unknown_rows = y(ps.unknown+ps.shift(ps.unknown),:);
is_unknown = y(ps.unknown+ps.shift(ps.unknown)+1,:) == 0;
unknown_rows(is_unknown) = NaN;
x(ps.unknown,:) = unknown_rows;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function dy_dx = derivative(x,y,ps);

% Derivatives for Known rows - same for all Q
dknown = zeros(ps.yrows,ps.xrows);
for k=1:length(ps.known)
  j = ps.known(k);
  i = j+ps.shift(ps.known(k));
  dknown(i,j) = 1;
end

% Derivatives for Unknown rows - different for each q in Q
Q = size(x,2);
dy_dx = zeros(ps.yrows,ps.xrows,Q);
for q=1:Q
  d = dknown;
  for k=1:length(ps.unknown)
  j = ps.unknown(k);
  i = j+ps.shift(ps.unknown(k));
    d(i,j) = y(i+1,q);
  end
  dy_dx(:,:,q) = d;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function dx_dy = reverse_derivative(x,y,ps);

Q = size(x,2);
d = derivative(x(:,1),y(:,1),ps)';
dx_dy = d(:,:,ones(1,Q));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function p = simulink_params(ps)

p = {};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function p = simulink_reverse_params(ps)

p = {};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
