function t=processtargets(net,t)
%PROCESSTARGETS Applies a network's preprocessing settings to target values
%
% Syntax
%   
%   t2 = processtargets(net,t1)
%
% Description
%
%   PROCESSTARGETS(net,t1) takes a network and target values (either a
%   matrix or a cell array of matrices) and returns those values after
%   applying the network's preprocessing settings.
%
%   If T is a cell array, it may have as many rows as network targets,
%   or as many rows as network layers.

% Copyright 2007 The MathWorks, Inc.

ismatrix = isnumeric(t);
if ismatrix, t = {t}; end

rows = size(t,1);
compact = (rows == net.numOutputs);

if compact
  % A has as many rows as targets
  for i=1:net.numOutputs
    j = net.hint.outputInd(i);
    k = i;
    processFcns = net.outputs{j}.processFcns;
    processSettings = net.outputs{j}.processSettings;
    t(k,:) = processforward(processFcns,processSettings,t(k,:));
  end
else
  % A has as many rows as layers
  for i=1:net.numOutputs
    j = net.hint.outputInd(i);
    k = j;
    processFcns = net.outputs{j}.processFcns;
    processSettings = net.outputs{j}.processSettings;
    t(k,:) = processforward(processFcns,processSettings,t(k,:));
  end
end

if ismatrix, t = t{1}; end
