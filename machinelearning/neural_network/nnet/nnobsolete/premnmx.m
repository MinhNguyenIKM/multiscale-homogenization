function [pn,minp,maxp,tn,mint,maxt] = premnmx(p,t)
%PREMNMX Preprocesses data so that minimum is -1 and maximum is 1.
%  
%  
%  This function is obselete.
%  Use MAPMINMAX instead.
%
% BUG WARNING:
% PREMNMX normally calculates min and max values for each row, and maps the
% values of each row accordingly. However, when called with a single
% columng vector it inconsistently calculated min and max values for the
% column and mapped its values accordingly. MAPMINMAX, the new function,
% consistently calculates min and max values for rows.
%
% So in cases where your code called PREMNMX with a column vector you
% should transpose that vector before calling MAPMINMAX, and transpose the
% transformed vector returned by MAPMINMAX, if you want to get the same
% results as you did with PREMNMX.

nntobsf('premnmx','Use MAPMINMAX instead, type HELP PREMNMX for bug warning.')

%  Syntax
%
%    [pn,minp,maxp,tn,mint,maxt] = premnmx(p,t)
%     [pn,minp,maxp] = premnmx(p)
%
%  Description
%  
%    PREMNMX preprocesses the network training
%    set by normalizing the inputs and targets so that
%     they fall in the interval [-1,1].
%  
%    PREMNMX(P,T) takes these inputs,
%      P - RxQ matrix of input (column) vectors.
%       T - SxQ matrix of target vectors.
%    and returns,
%       PN  - RxQ matrix of normalized input vectors
%       MINP- Rx1 vector containing minimums for each P
%       MAXP- Rx1 vector containing maximums for each P
%       TN  - SxQ matrix of normalized target vectors
%       MINT- Sx1 vector containing minimums for each T
%       MAXT- Sx1 vector containing maximums for each T
%    
%  Examples
%
%    Here is how to normalize a given data set so
%     that the inputs and targets will fall in the
%     range [-1,1].
%  
%      p = [-10 -7.5 -5 -2.5 0 2.5 5 7.5 10];
%       t = [0 7.07 -10 -7.07 0 7.07 10 7.07 0];
%      [pn,minp,maxp,tn,mint,maxt] = premnmx(p,t);
%
%     If you just want to normalize the input:
%
%       [pn,minp,maxp] = premnmx(p);
%
%  Algorithm
%
%     pn = 2*(p-minp)/(maxp-minp) - 1;
%
%  See also PRESTD, PREPCA, POSTMNMX, TRAMNMX.

% Copyright 1992-2005 The MathWorks, Inc.
% $Revision: 1.1.6.3 $

if nargin > 2
  error('NNET:premnmx:Arguments','Wrong number of arguments.');
end

minp = min(p')';
maxp = max(p')';
[R,Q]=size(p);
oneQ = ones(1,Q);

equal = minp==maxp;
nequal = ~equal;
if sum(equal) ~= 0
  warning('NNET:premnmx:Arguments','Some maximums and minimums are equal. Those inputs won''t be transformed.');
  minp0 = minp.*nequal - 1*equal;
  maxp0 = maxp.*nequal + 1*equal;
else
  minp0 = minp;
  maxp0 = maxp;
end

pn = 2*(p-minp0*oneQ)./((maxp0-minp0)*oneQ) - 1;

if nargin==2
  mint = min(t')';
  maxt = max(t')';
  equal = mint==maxt;
  nequal = ~equal;
  if sum(equal) ~= 0
    warning('NNET:premnmx:Arguments','Some maximums and minimums are equal. Those targets won''t be transformed.');
    mint0 = mint.*nequal - 1*equal;
    maxt0 = maxt.*nequal + 1*equal;
  else
    mint0 = mint;
    maxt0 = maxt;
  end
  tn = 2*(t-mint0*oneQ)./((maxt0-mint0)*oneQ) - 1;
end

