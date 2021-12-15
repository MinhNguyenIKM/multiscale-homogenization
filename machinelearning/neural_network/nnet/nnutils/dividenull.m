function [trainV,valV,testV,trainInd,valInd,testInd] = dividenull(allV,trainRatio,valRatio,testRatio)
%DIVIDENULL No data division.

% Copyright 2007 The MathWorks, Inc.

%% ERROR CHECKING
if nargin < 1, error('NNET:Arguments','Not enough arguments.'),end
if (nargin == 1) && ~ischar(allV), error('NNET:Arguments','Single argument must be string.'); end

%% FUNCTION INFO
if ischar(allV)
  switch (allV)
    case 'info'
      info.name = mfilename;
      info.title = 'Null';
      info.type = 'Data Division';
      info.version = 6;
      trainV = info;
    case 'name'
      trainV = 'Null';
    case 'fpdefaults'
      defaults = struct;
      trainV = defaults;
    otherwise
      error('NNET:Arguments','Unrecognized string: %s',allV)
  end
  return
end

%% DIVIDE DATA
[allV,mode] = nnpackdata(allV);
Q = size(allV{1,1},2);

trainInd = 1:Q;
valInd = [];
testInd = [];

trainV = allV;
valV = {[]};
testV = {[]};

trainV = nnunpackdata(trainV,mode);
valV = nnunpackdata(valV,mode);
testV = nnunpackdata(testV,mode);
