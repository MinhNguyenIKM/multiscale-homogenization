function [trainV,valV,testV,trainInd,valInd,testInd] = divideind(allV,trainInd,valInd,testInd)
%DIVIDIND Divide vectors into three sets using specified indices.
%
% Syntax
%
%   [trainV,valV,testV,trainInd,valInd,testInd] =
%     divideind(allV,trainInd,valInd,testInd)
%
% Description
%
%   DIVIDIND is used to separate input and target vectors into three
%   sets: training, validation and testing.
% 
%   DIVIDIND takes the following inputs,
%     allV     - RxQ matrix of Q R-element vectors.
%     trainInd - Training indices
%     valInd   - Validation indices
%     testInd  - Test indices
%   and returns:
%     trainV   - Training vectors
%     valV     - Validation vectors
%     testV    - Test vectors
%     trainInd - Training indices (unchanged)
%     valInd   - Validation indices (unchanged)
%     testInd  - Test indices (unchanged)
%
% Examples
%
%     p = rands(3,1000);
%     trainInd = [(1:100) (301:800)];
%     valInd = [(101:200) (801:900)];
%     testInd = [(201:300) (901:1000)];
%     [trainP,valP,testV] = divideind(p,trainInd,valInd,testInd);
%
%  Network Use
%
%   Here are the network properties that defines which data division function
%   to use, and what its parameters are, when TRAIN is called.
%
%     net.divideFcn
%     net.divideParam
%
% See also divideblock, divideint, dividerand.

% Copyright 2006-2008 The MathWorks, Inc.

%% ERROR CHECKING
if nargin < 1, error('NNET:Arguments','Not enough arguments.'),end
if (nargin == 1) && ~ischar(allV), error('NNET:Arguments','Single argument must be string.'); end

%% FUNCTION INFO
if ischar(allV)
  switch (allV)
    case 'info'
      info.name = mfilename;
      info.title = 'Specified';
      info.type = 'Data Division';
      info.version = 6;
      trainV = info;case 'name'
      trainV = 'Specified';
    case 'fpdefaults'
      defaults = struct;
      defaults.trainInd = 1;
      defaults.valInd = [];
      defaults.testInd = [];
      trainV = defaults;
    otherwise
      error('NNET:Arguments','Unrecognized code: %s',allV)
  end
  return
end

%% DEFAULTS
if (nargin == 1), trainInd = divideind('fpdefaults'); end
if isstruct(trainInd)
  testInd = trainInd.testInd;
  valInd = trainInd.valInd;
  trainInd = trainInd.trainInd;
else
  if nargin < 3, valInd = []; end
  if nargin < 4, testInd = []; end
end

%% DIVIDE DATA
[allV,mode] = nnpackdata(allV);

if ndims(allV) == 2
  [R,TS] = size(allV);

  trainV = cell(R,TS);
  valV = cell(R,TS);
  testV = cell(R,TS);

  for ts=1:TS
    for i=1:R
      v = allV{i,ts};
      if isempty(v)
        trainV{i,ts} = [];
        valV{i,ts} =[];
        testV{i,ts} = [];
      else
        trainV{i,ts} = v(:,trainInd);
        valV{i,ts} = v(:,valInd);
        testV{i,ts} = v(:,testInd);
      end
    end
  end

  trainV = nnunpackdata(trainV,mode);
  valV = nnunpackdata(valV,mode);
  testV = nnunpackdata(testV,mode);
  
elseif ndims(allV) == 3
  [R,S,TS] = size(allV);

  trainV = cell(R,S,TS);
  valV = cell(R,S,TS);
  testV = cell(R,S,TS);

  for ts=1:TS
    for i=1:R
      for j=1:S
        v = allV{i,j,ts};
        if isempty(v)
          trainV{i,j,ts} = [];
          valV{i,j,ts} =[];
          testV{i,j,ts} = [];
        else
          trainV{i,j,ts} = v(:,trainInd,:);
          valV{i,j,ts} = v(:,valInd,:);
          testV{i,j,ts} = v(:,testInd,:);
        end
      end
    end
  end

  trainV = nnunpackdata(trainV,mode);
  valV = nnunpackdata(valV,mode);
  testV = nnunpackdata(testV,mode);
else
  error('NNET:divideind:Arguments','Only 2 and 3 dimension matrices supported.')
end
