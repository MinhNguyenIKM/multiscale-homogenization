function jac = nnlmarq(p,d)
%NNLMARQ  Marquardt Backpropagation Learning Rule
%           
%         (See PURELIN, LOGSIG, TANSIG)
%
%         jac = NNLMARQ(P,D)
%           P  - RxQ matrix of input vectors.
%           D  - SxQ matrix of sensitivity vectors.
%         Returns:
%           jac - a partial jacobian matrix.

% Copyright 1994-2007 PWS Publishing Company and The MathWorks, Inc.
% $Revision: 1.6.4.3 $


if nargin ~= 2
  error('NNET:Arguments','Wrong number of arguments.');
end

[s,q]=size(d);
[r,q]=size(p);

jac=kron(p',ones(1,s)).*kron(ones(1,r),d');

