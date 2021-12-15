function d=processinputderiv(net,x)
%PROCESSINPUTDERIV Applies a network's preprocessing settings to target values
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

ismatrix = isnumeric(x);
if ismatrix, x = {x}; end

d = cell(size(x));
for i=1:net.numInputs
  processFcns = net.inputs{i}.processFcns;
  processSettings = net.inputs{i}.processSettings;
  d(i,:) = processdx(processFcns,processSettings,x(i,:));
end

if ismatrix, d = d{1}; end
