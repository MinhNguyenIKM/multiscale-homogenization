function p=processinputs(net,p)
%PROCESSINPUTS Applies a network's preprocessing settings to input values
%
% Syntax
%   
%   p2 = processinputs(net,p1)
%
% Description
%
%   PROCESSINPUTS(net,p1) takes a network and input values (either a
%   matrix or a cell array of matrices) and returns those values after
%   applying the network's preprocessing settings.

% Copyright 2007 The MathWorks, Inc.

ismatrix = isnumeric(p);
if ismatrix, p = {p}; end

for i=1:net.numInputs
  processFcns = net.inputs{i}.processFcns;
  processSettings = net.inputs{i}.processSettings;
  p(i,:) = processforward(processFcns,processSettings,p(i,:));
end

if ismatrix, p = p{1}; end
