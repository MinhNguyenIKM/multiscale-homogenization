function [out1,out2] = template_process(in1,in2,in3,in4)
%TEMPLATE_PROCESS Template data processing function.
%  
%  WARNING - Future versions of the toolbox may require you to update
%  custom functions.
%
%  Directions for Customizing
%
%    1. Make a copy of this function with a new name
%    2. Edit your new function according to the code comments marked ***
%    3. Type HELP NNPROCESS to see a list of other processing functions.
%
%  Syntax
%
%	  [y,ps] = template_process(x,...1 to 3 args...)
%	  [y,ps] = template_process(x,fp)
%	  y = template_process('apply',x,ps)
%	  x = template_process('reverse',y,ps)
%	  dx_dy = template_process('dx',x,y,ps)
%	  dx_dy = template_process('dx',x,[],ps)
%   name = template_process('name');
%   fp = template_process('pdefaults');
%   names = template_process('pnames');
%   template_process('pcheck',fp);
%
%  Description
%  
%	  TEMPLATE_PROCESS(X,...1 to 3 args...) takes X and optional parameters,
%	    X - NxQ matrix or a 1xTS row cell array of NxQ matrices.
%     arg1 - Optional argument, default = ?
%     arg2 - Optional argument, default = ?
%     arg3 - Optional argument, default = ?
%	  and returns,
%     Y - Each MxQ matrix (where M == N) (optional).
%     PS - Process settings, to allow consistent processing of values.
%
%   TEMPLATE_PROCESS(X,FP) takes parameters as struct: FP.arg1, etc.
%   TEMPLATE_PROCESS('apply',X,PS) returns Y, given X and settings PS.
%   TEMPLATE_PROCESS('reverse',Y,PS) returns X, given Y and settings PS.
%   TEMPLATE_PROCESS('dx',X,Y,PS) returns MxNxQ derivative of Y w/respect to X.
%   TEMPLATE_PROCESS('dx',X,[],PS)  returns the derivative, less efficiently.
%   TEMPLATE_PROCESS('name') returns the name of this process method.
%   TEMPLATE_PROCESS('pdefaults') returns default process parameter structure.
%   TEMPLATE_PROCESS('pdesc') returns the process parameter descriptions.
%   TEMPLATE_PROCESS('pcheck',fp) throws an error if any parameter is illegal.

% Copyright 1992-2005 The MathWorks, Inc.

fn = mfilename;
boiler_process

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Name
function n = name
n = 'Template Process';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Defaults
function fp = param_defaults(values)

fp = struct;

% *** CUSTOMIZE HERE
% *** Define defaults for each of the function parameters.
% *** Parameters should have more descriptive names than arg1, etc.
if length(values)>=1, fp.arg1 = values{1}; else fp.arg1 = 1; end
if length(values)>=2, fp.arg2 = values{2}; else fp.arg2 = 2; end
if length(values)>=3, fp.arg3 = values{3}; else fp.arg3 = 3; end
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Names
function names = param_names()

% *** CUSTOMIZE HERE
% *** Define human friendly names for each of the function parameters.
names = {'Argument One', 'Argument Two', 'Argument Three'};
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Parameter Check
function err = param_check(fp)

err = [];

% *** CUSTOMIZE HERE
% *** Return an error string if any function parameter is not defined properly.
if (fp.arg1 < -1000)
   err = 'Argument One is less than -1000';
elseif (fp.arg2 == 20)
  err = 'Argument Two is 20';
elseif (floor(fp.arg3/2) == (fp.arg3/2))
  err = 'Argument Three is even';
end
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% New Process
function [y,ps] = new_process(x,fp)

ps.name = mfilename;

% *** CUSTOMIZE HERE
% *** Define settings to be used for consistent application, reversal, and derivative calculations.
% *** These settings are usually a function of x, not random as shown below.
ps.setting1 = rand;
ps.setting2 = rand;
% ***

y = apply_process(x,ps);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Apply Process
function y = apply_process(x,ps)

% *** CUSTOMIZE HERE
% *** Transform each column of X into the corresponding column of Y
y = x * ps.setting1 + ps.setting2;
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Reverse Process
function x = reverse_process(y,ps)

% *** CUSTOMIZE HERE
% *** Reverse transform each column of X into the corresponding column of Y
% *** If perfect reverse calculations are not possible, return the best
% *** estimate, and avoid using this function for processing network
% *** outputs and targets.
x = (y - ps.setting2) / ps.setting1;
% ***

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Derivative of Y w/respect to X
function dy_dx = derivative(x,y,ps);

[n,q] = size(x);
[m,q] = size(y);
dy_dx = zeros(m,n,q);
for k=1:q
  
  % *** CUSTOMIZE HERE
  % *** Calculate the MxN derivative of M-element Y(:,j) with
  % *** respect to N-element X(:,i).
   d = eye(n) * ps.setting1;
   % ***
   
   dy_dx(:,:,k) = d;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
