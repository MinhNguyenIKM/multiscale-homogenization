function [out1,out2] = processpca(in1,in2,in3,in4)

%PROCESSPCA Processes rows of matrix with principal component analysis.
%  
%  Syntax
%
%    [y,ps] = processpca(maxfrac)
%    [y,ps] = processpca(x,fp)
%    y = processpca('apply',x,ps)
%    x = processpca('reverse',y,ps)
%    dx_dy = processpca('dx',x,y,ps)
%    dx_dy = processpca('dx',x,[],ps)
%    name = processpca('name');
%    fp = processpca('pdefaults');
%    names = processpca('pnames');
%    processpca('pcheck',fp);
%
%  Description
%  
%   PROCESSPCA processes matrices using principal component analysis so
%   that each row is uncorrelated, the rows are in the order of the amount
%   they contribute to total variation, and rows whose contribution
%   to total variation are less than MAXFRAC are removed.
%  
%	  PROCESSPCA(X,MAXFRAC) takes X and an optional parameter,
%	  X - NxQ matrix or a 1xTS row cell array of NxQ matrices.
%     MAXFRAC - Maximum fraction of variance for removed rows. (Default 0)
%	  and returns,
%     Y - Each NxQ matrix with N-M rows deleted (optional).
%     PS - Process settings, to allow consistent processing of values.
%
%   PROCESSPCA(X,FP) takes parameters as struct: FP.maxfrac.
%   PROCESSPCA('apply',X,PS) returns Y, given X and settings PS.
%   PROCESSPCA('reverse',Y,PS) returns X, given Y and settings PS.
%   PROCESSPCA('dx',X,Y,PS) returns MxNxQ derivative of Y w/respect to X.
%   PROCESSPCA('dx',X,[],PS)  returns the derivative, less efficiently.
%   PROCESSPCA('name') returns the name of this process method.
%   PROCESSPCA('pdefaults') returns default process parameter structure.
%   PROCESSPCA('pdesc') returns the process parameter descriptions.
%   PROCESSPCA('pcheck',fp) throws an error if any parameter is illegal.
%    
%   Here is how to format a matrix with an independent row, a correlated row,
%   and a completely redundant row, so that its rows are uncorrelated and
%   the redundant row is dropped.
%	
%     x1_independent = rand(1,5)
%     x1_correlated = rand(1,5) + x_independent;
%     x1_redundant = x_independent + x_correlated
%     x1 = [x1_independent; x1_correlated; x1_redundant]
%     [y1,ps] = processpca(x1)
%
%   Next, we apply the same processing settings to new values.
%
%     x2_independent = rand(1,5)
%     x2_correlated = rand(1,5) + x_independent;
%     x2_redundant = x_independent + x_correlated
%     x2 = [x2_independent; x2_correlated; x2_redundant];
%     y2 = processpca('apply',x2,ps)
%
%   Here we reverse the processing of y1 to get x1 again.
%
%     x1_again = processpca('reverse',y1,ps)
%
%  Algorithm
%
%     Values in rows whose elements are not all the same are set to:
%       y = 2*(x-minx)/(maxx-minx) - 1;
%     Values in rows with all the same value are set to 0.
%
%  See also MAPMINMAX, FIXUNKNOWNS, MAPSTD, REMOVECONSTANTROWS

% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.11 $

% Process function boiler plate script
boiler_process

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Uncorrelate Rows';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Defaults
function fp = param_defaults(values)

if length(values)>=1, fp.maxfrac = values{1}; else fp.maxfrac = 0; end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Names
function names = param_names()
names = {'Minimum fraction of total variable for a row to be kept.'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Check
function err = param_check(fp)

mf = fp.maxfrac;
if ~isa(mf,'double') || any(size(mf)~=[1 1]) || ~isreal(mf) || ~isfinite(mf) || (mf<0) || (mf>=1)
  err = 'maxfrac must be a real scalar value between 0 and 1.';
else
  err = '';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% New Process
function [y,ps] = new_process(x,fp)

if any(any(~isfinite(x)))
  error('NNET:Process','Use FIXUNKNOWNS to replace NaN values in X.');
end
[R,Q]=size(x);
if  R > Q
  error('NNET:Dimensions','X has more rows than columns.');
end  

% Use the singular value decomposition to compute the principal components
[transform,s] = svd(x,0);

% Compute the variance of each principal component
var = diag(s).^2/(Q-1);

% Compute total variance and fractional variance
total_variance = sum(var);
frac_var = var./total_variance;

% Find the componets which contribute more than min_frac of the total variance
yrows = sum(frac_var >= fp.maxfrac);

% Reduce the transformation matrix appropriately
ps.name = 'processpca';
ps.xrows = R;
ps.yrows = yrows;
ps.maxfrac = fp.maxfrac;
ps.transform = transform(:,1:yrows)';

y = apply_process(x,ps);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Apply Process
function y = apply_process(x,ps)

y = ps.transform * x;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Reverse Process
function x = reverse_process(y,ps)

x = pinv(ps.transform) * y;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function dy_dx = derivative(x,y,ps);

Q = size(x,2);
dy_dx = ps.transform(:,:,ones(1,Q));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function dx_dy = reverse_derivative(x,y,ps);

Q = size(x,2);
inverse_transform = pinv(ps.transform);
dx_dy = inverse_transform(:,:,ones(1,Q));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function p = simulink_params(ps)

p = ...
  { ...
  'transform',mat2str(ps.transform);
  };

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function p = simulink_reverse_params(ps)

inverse_transform = pinv(ps.transform);
p = ...
  { ...
  'inverse_transform',mat2str(inverse_transform);
  };
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
