function weights = initsompc(varargin)
%INITSOMPC Initialize SOM weights with principle components.
%
%  Syntax
%
%    weights = initsom(inputs,dimensions,positions)
%    weights = initsom(inputs,dimensions,topologyFcn)
%
%  Description
%
%    INITSOMPC initalizes the weights of an N-dimensional self-organizing map
%    so that the initial weights are distributed across the space spanned
%    by the most significant N principal components of the inputs. This
%    significantly speeds up SOM learning, as the map starts out with a
%    reasonable ordering of the input space.
%
%    INITSOMPC takes these arguments,
%      INPUTS - RxQ matrix of Q R-element input vectors.
%      DIMENSIONS - Dx1 vector of positive integer SOM dimensions.
%      POSITIONS - DxS matrix of S D-dimension neuron positions.
%    and returns,
%      WEIGHTS - SxR matrix of weights.
%
%    Alternatively, INITSOMPC can be called with TOPOLOGYFCN (the name of
%    a layer topology function) instead of POSITIONS. TOPOLOGYFCN will be
%    called with DIMENSIONS to obtain POSITIONS.
%
%  Example
%
%    inputs = rand(2,100)+[2;3]*ones(1,100);
%    dimensions = [3 4];
%    positions = gridtop(dimensions);
%    weights = initsompc(inputs,dimensions,positions);
%
%  See also NEWSOM, GRIDTOP, HEXTOP, RANDTOP

% Copyright 2007 The MathWorks, Inc.

arg1 = varargin{1};
if strcmp('new_weights',arg1)
  [inputWeight,input,layer] = deal(varargin{2:4});
  inputs = input.exampleInput;
  dimensions = layer.dimensions;
  neuronPositions = layer.positions;
else
  if nargin ~= 3, error('NNET:Arguments','Incorrect number of input arguments.'); end
  [inputs,dimensions,neuronPositions] = deal(varargin{:});
  if ischar(neuronPositions)
    neuronPositions = feval(neuronPositions,dimensions);
  elseif isa(neuronPositions,'function_handle')
    neuronPositions = neuronPositions(dimensions);
  end
end

[numInputs,numSamples] = size(inputs);
numDimensions = length(dimensions);
numNeurons = prod(dimensions);

[dimensions,dimOrder] = sort(dimensions,2,'descend');
neuronPositions = neuronPositions(dimOrder,:);

meanInputs = mean(inputs,2);
shiftedInputs = inputs - meanInputs(:,ones(1,numSamples));

if numInputs > numDimensions
  neuronPositions = [neuronPositions; zeros(numInputs-numDimensions,numNeurons)];
end

% Ensure that num cols > num rows
numCopies = ceil(numInputs/numSamples);
shiftedInputs = shiftedInputs(:,repmat(1:numSamples,1,numCopies));

[components,gains,encodedInputsT] = svd(shiftedInputs,'econ');
encodedInputsT = encodedInputsT(1:numSamples,:);
basis = components*gains;
stdev = std(encodedInputsT,1,1)';

% Map neuron positions into ND-box of [-1,+1] values
minNP = min(neuronPositions,[],2);
maxNP = max(neuronPositions,[],2);
difNP = maxNP-minNP;
difNP(difNP == 0) = 1;
numNeurons1s = ones(1,numNeurons);
minNP = minNP(:,numNeurons1s);
difNP = difNP(:,numNeurons1s);
basisPositions = 2 *((neuronPositions-minNP)./difNP) - 1;

scaledBasis = basis * 2.5 * diag(stdev);
if numDimensions > numInputs
  scaledBasis = [scaledBasis rands(numInputs,numDimensions-numInputs)*0.001];
end

weights = (meanInputs(:,ones(1,numNeurons)) + (scaledBasis * basisPositions))';
