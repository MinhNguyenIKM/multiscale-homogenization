function [dw,ls] = template_learn(w,p,z,n,a,t,e,gW,gA,d,lp,ls)
%TEMPLATE_LEARN Template learning function.
%  
%  WARNING - Future versions of the toolbox may require you to update
%  custom functions.
%
%  Directions for Customizing
%
%    1. Make a copy of this function with a new name
%    2. Edit your new function according to the code comments marked ***
%    3. Type HELP NNLEARN to see a list of other learning functions.
%
%  Syntax
%  
%    [dW,LS] = template_learn(W,P,Z,N,A,T,E,gW,gA,D,LP,LS)
%    [db,LS] = template_learn(b,ones(1,Q),Z,N,A,T,E,gW,gA,D,LP,LS)
%    info = template_learn(code)
%
%  Description
%
%    TEMPLATE_LEARN(W,P,Z,N,A,T,E,gW,gA,D,LP,LS) takes several inputs,
%      W  - SxR weight matrix (or Sx1 bias vector).
%      P  - RxQ input vectors (or ones(1,Q)).
%      Z  - SxQ weighted input vectors.
%      N  - SxQ net input vectors.
%      A  - SxQ output vectors.
%      T  - SxQ layer target vectors.
%      E  - SxQ layer error vectors.
%      gW - SxR gradient with respect to performance.
%      gA - SxQ output gradient with respect to performance.
%      D  - SxS neuron distances.
%      LP - Learning parameters, none, LP = [].
%      LS - Learning state, initially should be = [].
%    and returns
%      dW - SxR weight (or bias) change matrix.
%      LS - New learning state.
%
%    TEMPLATE_LEARN(CODE) return useful information for each CODE string:
%      'pnames'    - Returns names of learning parameters.
%      'pdefaults' - Returns default learning parameters.
%      'needg'     - Returns 1 if this function uses gW or gA.
%
%  Network Use
%
%    To prepare the weights and the bias of layer i of a custom network
%    to train or adapt with TEMPLATE_LEARN:
%    1) Set NET.trainFcn to 'trainb' or NET.adaptFcn to 'trains'.
%    2) Set each NET.inputWeights{i,j}.learnFcn to 'template_learn'.
%       Set each NET.layerWeights{i,j}.learnFcn to 'template_learn'.
%       Set NET.biases{i}.learnFcn to 'template_learn'.
%       Each weight and bias learning parameter property will automatically
%       be set to TEMPLATE_LEARN's default parameters.
%    To train or adapt the network use TRAIN or ADAPT.

% Copyright 1992-2007 The MathWorks, Inc.

% FUNCTION INFO
% =============
if isstr(w)
  switch lower(w)
  case 'pnames'

    % *** CUSTOMIZE HERE
    % *** Define names of any parameters for this learning function
    dw = {'Param One','Param Two','Param Three'};
    % ***
    
  case 'pdefaults'
    dw = struct;
    
    % *** CUSTOMIZE HERE
    % *** Define defaults of any parameters for this learning function
    dw.param1 = 1;
    dw.param2 = 2;
    dw.param3 = 3;
    % ***
    
  case 'needg'

    % *** CUSTOMIZE HERE
    % *** Return 1 if this function depends on either gA or gW, 0 otherwise 
    dw = 1;
    % ***
    
  otherwise
    error('NNET:Code','Unrecognized code.')
  end
  return
end

[s,r] = size(w);

% *** CUSTOMIZE HERE
% *** Return SxR change matrix for weight or bias
% *** Calculated from any of the input arguments of
% *** this function or parameters.

dw = 0.001 * gW;
