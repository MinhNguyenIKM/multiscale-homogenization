function net = nnt2lvq(pr,w1,w2,lr,lf)
%NNT2LVQ Update NNT 2.0 learning vector quantization network.
%
%  Syntax
%
%    net = nnt2lvq(pr,w1,w2,lr,lf)
%
%  Description
%
%    NNT2LVQ(PR,W1,W2,LR,LF) takes these arguments,
%      PR - Rx2 matrix of min and max values for R input elements.
%      W1 - S1xR weight matrix.
%      W2 - S2xS1 weight matrix.
%      LR - learning rate, default = 0.01.
%      LF - Learning function, default = 'learnlv2'.
%    and returns an LVQ network.
%
%     The learning function LF can be LEARNLV1 or LEARNLV2.
%
%    Once a network has been updated it can be simulated, initialized,
%    adapted, or trained with SIM, INIT, ADAPT, and TRAIN.
%
%  See also NEWLVQ.

% Mark Beale, 11-31-97
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.5 $

% Check
if size(pr,2) ~= 2, error('NNET:Arguments','PR must have two columns.'), end
if size(pr,1) ~= size(w1,2), error('NNET:Arguments','PR and W1 sizes do not match.'), end
if size(w1,1) ~= size(w2,2), error('NNET:Arguments','W1 and W2 sizes do not match.'), end

% Defaults
if nargin < 4, lr = 0.01; end
if nargin < 5, lf = 'learnlv2'; end

% Update
s1 = size(w1,1);
s2 = size(w2,1);
net = newlvq(pr,s1,ones(1,s2)/s2,lr,lf);
net.iw{1,1} = w1;
net.lw{2,1} = w2;
