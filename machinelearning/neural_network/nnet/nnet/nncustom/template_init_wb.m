function w = template_init_wb(s,pr)
%TEMPLATE_INIT_WB Template weight/bias initialization function.
%
%  WARNING - Future versions of the toolbox may require you to update
%  custom functions.
%
%  Directions for Customizing
%
%    1. Make a copy of this function with a new name
%    2. Edit your new function according to the code comments marked ***
%    3. Type HELP NNINIT to see a list of other weight/bias initialization functions.
%
%  Syntax
%
%    W = template_init_wb(S,PR)
%    b = template_init_wb(S)
%
%  Description
%
%    RANDS(S,PR) takes,
%      S  - number of neurons.
%      PR - Rx2 matrix of R input ranges.
%    and returns an S-by-R weight matrix of random values between -1 and 1.
%
%  Network Use
%
%    To prepare the weights and the bias of layer i of a custom network
%    to be initialized with TEMPLATE_INIT_WB:
%    1) Set NET.initFcn to 'initlay'.
%       (NET.initParam will automatically become INITLAY's default parameters.)
%    2) Set NET.layers{i}.initFcn to 'initwb'.
%    3) Set each NET.inputWeights{i,j}.initFcn to 'template_init_wb'.
%       Set each NET.layerWeights{i,j}.initFcn to 'template_init_wb';
%       Set each NET.biases{i}.initFcn to 'template_init_wb'.
%    To initialize the network call INIT.

% Copyright 1992-2007 The MathWorks, Inc.

if nargin < 1, error('NNET:Arguments','Not enough input arguments.'); end
if (nargin == 1)
  
  % *** CUSTOMIZE HERE
  % *** Define Sx1 bias vector
  w = zeros(s,1);
  % ***
  
else
  r = size(pr,1);
  
  % *** CUSTOMIZE HERE
  % *** Define SxR weight matrix
  w = zeros(s,r);
  % ***

end
