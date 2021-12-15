function [trainV,valV,testV] = dividevec(p,t,valPercent,testPercent)
%DIVIDEVEC Divide problem vectors into training, validation and test vectors.
%
% Syntax
%
%   [trainV,valV,testV] = dividevec(p,t,valPercent,testPercent)
%
% Description
%
%   DIVIDEVEC is used to seperate a set of input and target data into
%   groups of vectors for training, validating network performance during
%   training so that training stops early if it attempts to overfit the training
%   data, and test data used for an independent measure of how the network
%   might be expected to perform on data it was not trained on.
% 
%   DIVIDEVEC(P,T,valPercent,testPercent) takes the following inputs,
%     P - RxQ matrix of inputs, or cell array of input matices.
%     T - SxQ matrix of targets, or cell array of target matrices.
%     valPercent - Fraction of column vectors to use for validation.
%     testPercent - Fraction of column vectors to use for test.
%   and returns:
%     trainV.P, .T, .indices - Training vectors and their original indices
%     valV.P, .T, .indices - Validation vectors and their original indices
%     testV.P, .T, .indices - Test vectors and their original indices
%
% Examples
%
%   Here 1000 3-element input and 2-element target vectors are  created:
%   
%     p = rands(3,1000);
%     t = [p(1,:).*p(2,:); p(2,:).*p(3,:)];
%
%  Here they are divided up into training, validation and test sets.
%  Validation and test sets contain 20% of the vectors each, leaving
%  60% of the vectors for training.
%
%     [trainV,valV,testV] = dividevec(p,t,0.20,0.20);
%
%  Now a network is created and trained with the data.
%
%     net = newff(minmax(p),[10 size(t,1)]);
%     net = train(net,trainV.P,trainV.T,[],[],valV,testV);
%
% See also con2seq, seq2con.

% Copyright 2005-2007 The MathWorks, Inc.

if nargin < 4, testPercent = 0.0; end
if nargin < 3, valPercent = 0.0; end
if nargin < 2, error('NNET:dividevec:Arguments','Not enough arguments.'),end

err = nncheckpt(p,t,'P','T'); if ~isempty(err), error('NNET:dividevec:Arguments',err); end

[p,mode] = nnpackdata(p);
[t,mode] = nnpackdata(t);

TS = size(p,2);
Q = size(p{1,1},2);
R = size(p,1);
S = size(t,1);

numValidate = floor(valPercent * Q);
numTest = floor(testPercent * Q);
numTrain = Q - numValidate - numTest;

i = randperm(Q);
i1 = sort(i(1:numTrain));
i2 = sort(i(numTrain+(1:numValidate)));
i3 = sort(i(numTrain+numValidate+(1:numTest)));

trainV.P = cell(R,TS);
trainV.T = cell(S,TS);
valV.P = cell(R,TS);
valV.T = cell(S,TS);
testV.P = cell(R,TS);
testV.T = cell(S,TS);

for ts=1:TS
  for i=1:R
    pi = p{i,ts};
    trainV.P{i,ts} = pi(:,i1);
    valV.P{i,ts} = pi(:,i2);
    testV.P{i,ts} = pi(:,i3);
  end
  for i=1:S
    ti = t{i,ts};
    trainV.T{i,ts} = ti(:,i1);
    valV.T{i,ts} = ti(:,i2);
    testV.T{i,ts} = ti(:,i3);
  end
end

trainV.P = nnunpackdata(trainV.P,mode);
trainV.T = nnunpackdata(trainV.T,mode);
trainV.indices = i1;
valV.P = nnunpackdata(valV.P,mode);
valV.T = nnunpackdata(valV.T,mode);
valV.indices = i2;
testV.P = nnunpackdata(testV.P,mode);
testV.T = nnunpackdata(testV.T,mode);
testV.indices = i3;
