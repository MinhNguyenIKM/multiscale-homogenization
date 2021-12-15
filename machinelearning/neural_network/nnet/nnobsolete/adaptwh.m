function [a,e,w,b] = adaptwh(w,b,p,t,lr)
%ADAPTWH Adapt linear layer with Widrow-Hoff rule.
%
%  This function is obselete.
%  Use NNT2LIN and ADAPT to update and adapt your network.

nntobsf('adaptwh','Use NNT2LIN and ADAPT to update and adapt your network.')

%  [A,E,W,B] = ADAPTWH(W,B,P,T,lr)
%    W  - SxR weight matrix.
%    B  - Sx1 bias vector.
%    P  - RxQ matrix of input vectors.
%    T  - SxQ matrix of target vectors.
%    lr - Learning rate (optional, default = 0.1).
%  Returns:
%    A - output of adaptive linear filter.
%    E - error of adaptive linear filter.
%    W - new weight matrix
%    B - new weights & biases.
%  
%  See also ADAPTFUN, LINNET, SIMLIN, SOLVELIN, INITLIN, LEARNWH, TRAINLIN.
%  
%  EXAMPLE: time = 0:1:40;
%           p = sin(time);
%           t = p*2+1;
%           [w,b] = initlin(p,t);
%          [a,e,w,b] = adaptwh(w,b,p,t,1.0);
%          plot(time,t,'+',time,a)
%          label('time','output - target +','Output and Target Signals')

% Mark Beale, 9-22-93
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.11.4.3 $  $Date: 2007/11/09 20:53:35 $

if nargin < 4,error('NNET:Arguments','Not enough arguments.'),end

% TRAINING PARAMETERS
if nargin == 4, lr = 0.1; end

[r,q] = size(p);
[s,q] = size(t);

a = zeros(s,q);
e = zeros(s,q);

% PRESENTATION PHASE

for i=1:q
  a(:,i) = purelin(w*p(:,i),b);
  e(:,i) = t(:,i) - a(:,i);

  [dw,db] = learnwh(p(:,i),e(:,i),lr);
  w = w + dw; b = b + db;
end
