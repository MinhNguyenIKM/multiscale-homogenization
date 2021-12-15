function d=processoutputderiv(net,a)
%PROCESSOUTPUTDERIV Applies a network's preprocessing settings to target values
%
% Syntax
%   
%   t2 = processoutputderiv(net,t1)
%
% Description
%
%   PROCESSOUTPUTDERIV(net,t1) takes a network and target values (either a
%   matrix or a cell array of matrices) and returns those values after
%   applying the network's preprocessing settings.
%
%   If T is a cell array, it may have as many rows as network targets,
%   or as many rows as network layers.

% Copyright 2007 The MathWorks, Inc.

ismatrix = isnumeric(a);
if ismatrix, a = {a}; end

rows = size(a,1);
compact = (rows == net.numOutputs);
d = cell(size(a));

if compact
  % A has as many rows as outputs
  for i=1:net.numOutputs
    j = net.hint.outputInd(i);
    k = i;
    processFcns = net.outputs{j}.processFcns;
    processSettings = net.outputs{j}.processSettings;
    d(k,:) = processinversedx(processFcns,processSettings,a(k,:));
  end
else
  % A has as many rows as layers
  for i=1:net.numOutputs
    j = net.hint.outputInd(i);
    k = j;
    processFcns = net.outputs{j}.processFcns;
    processSettings = net.outputs{j}.processSettings;
    d(k,:) = processinversedx(processFcns,processSettings,a(k,:));
  end
end

if ismatrix, d = d{1}; end
