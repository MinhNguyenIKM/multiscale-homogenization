function a=processoutputs(net,a)
%PROCESSOUTPUT Applies a network's preprocessing settings to output values
%
% Syntax
%   
%   a2 = processoutputs(net,a1)
%
% Description
%
%   PROCESSOUTPUT(net,a1) takes a network and output values (either a
%   matrix or a cell array of matrices) and returns those values after
%   applying the network's preprocessing settings.
%
%   If A is a cell array, it may have as many rows as network targets,
%   or as many rows as network layers.

% Copyright 2007 The MathWorks, Inc.

ismatrix = isnumeric(a);
if ismatrix, a = {a}; end

rows = size(a,1);
compact = (rows == net.numOutputs);

if compact
  % A has as many rows as outputs
  for i=1:net.numOutputs
    j = net.hint.outputInd(i);
    k = i;
    processFcns = net.outputs{j}.processFcns;
    processSettings = net.outputs{j}.processSettings;
    a(k,:) = processreverse(processFcns,processSettings,a(k,:));
  end
else
  % A has as many rows as layers
  for i=1:net.numOutputs
    j = net.hint.outputInd(i);
    k = j;
    processFcns = net.outputs{j}.processFcns;
    processSettings = net.outputs{j}.processSettings;
    a(k,:) = processreverse(processFcns,processSettings,a(k,:));
  end
end

if ismatrix, a = a{1}; end
