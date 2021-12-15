function x = nn_normalize_outputs(x,net)

% Copyright 2007 The MathWorks, Inc.
% $Revision: 1.1.8.1 $

isMatrix = ~iscell(x);
if isMatrix, x = {x}; end

outputInd = net.hint.outputInd;
numOutputs = length(outputInd);
if size(x,1) == numOutputs
  xInd = 1:numOutputs;
else
  xInd = outputInd;
end

for ii = 1:numOutputs
  i = outputInd(ii);
  xi = xInd(ii);
  range = net.outputs{i}.range;
  for j=1:size(range,1)
    xij = x{xi}(j,:);
    rMin = range(j,1);
    rMax = range(j,2);
    multiplier = 2 / (rMax - rMin);
    offset = (rMax + rMin) / 2;
    x{xi}(j,:) = (xij - offset) * multiplier;
  end
end

if isMatrix, x = x{1}; end
