function [trainV,valV,testV,trainInd,valInd,testInd] = divideint(allV,trainRatio,valRatio,testRatio)
%DIVIDEINT Divide vectors into three sets using interleaved indices.
%
% Syntax
%
%   [trainV,valV,testV,trainInd,valInd,testInd] =
%     divideint(allV,trainRatio,valRatio,testRatio)
%
% Description
%
%   DIVIDEINT is used to separate input and target vectors into three
%   sets: training, validation and testing.
% 
%   DIVIDEINT takes the following inputs,
%     allV       - RxQ matrix of Q R-element vectors.
%     trainRatio - Ratio of vectors for training, default = 0.6.
%     valRatio   - Ratio of vectors for validation, default = 0.2.
%     testRatio  - Ratio of vectors for testing, default = 0.2.
%   and returns:
%     trainV   - Training vectors
%     valV     - Validation vectors
%     testV    - Test vectors
%     trainInd - Training indices
%     valInd   - Validation indices
%     testInd  - Test indices
%
% Examples
%
%     p = rands(3,1000);
%     t = [p(1,:).*p(2,:); p(2,:).*p(3,:)];
%     [trainP,valP,testV,trainInd,valInd,testInd] = divideint(p,0.6,0.2,0.2);
%     [trainT,valT,testT] = divideind(t,trainInd,valInd,testInd);
%
%  Network Use
%
%   Here are the network properties that defines which data division function
%   to use, and what its parameters are, when TRAIN is called.
%
%     net.divideFcn
%     net.divideParam
%
% See also divideblock, divideind, dividerand.

% Copyright 2006-2008 The MathWorks, Inc.

%% ERROR CHECKING
if nargin < 1, error('NNET:Arguments','Not enough arguments.'),end

%% FUNCTION INFO
if ischar(allV)
  switch (allV)
    case 'info'
      info.name = mfilename;
      info.title = 'Interleaved';
      info.type = 'Data Division';
      info.version = 6;
      trainV = info;
    case 'name'
      trainV = 'Interleaved';
    case 'fpdefaults'
      defaults = struct;
      defaults.trainRatio = 0.6;
      defaults.valRatio = 0.2;
      defaults.testRatio = 0.2;
      trainV = defaults;
    otherwise
      error('NNET:Arguments','Unrecognized string: %s',allV)
  end
  return
end

%% DEFAULTS
if (nargin == 1), trainRatio = divideint('fpdefaults'); end
if isstruct(trainRatio)
  valRatio = trainRatio.valRatio;
  testRatio = trainRatio.testRatio;
  trainRatio = trainRatio.trainRatio;
else
  if nargin < 3, testRatio = trainRatio * 0.2/0.6; end
  if nargin < 4, valRatio = (trainRatio+testRatio) * 0.2/0.8; end
end

%% DIVIDE DATA
totalRatio = trainRatio + testRatio + valRatio;
trainPercent = trainRatio/totalRatio;
testPercent = testRatio/totalRatio;
valPercent = valRatio/totalRatio;

[allV,mode] = nnpackdata(allV);
Q = size(allV{1,1},2);

percents = [trainPercent testPercent valPercent];
totals = [0 0 0];
slots = zeros(1,Q);
for i=1:Q
  if i==1
    d = percents;
  else
    d = percents - (totals./(i-1));
  end
  slot = find(d == max(d),1);
  slots(i) = slot;
  totals(slot) = totals(slot) + 1;
end
trainInd = find(slots==1);
valInd = find(slots==2);
testInd = find(slots==3);

[trainV,valV,testV] = divideind(allV,trainInd,valInd,testInd);

trainV = nnunpackdata(trainV,mode);
valV = nnunpackdata(valV,mode);
testV = nnunpackdata(testV,mode);
