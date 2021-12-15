function [dw,ls] = learnsomb(w,p,z,n,a,t,e,gW,gA,d,lp,ls)
%LEARNSOM Batch self-organizing map weight learning function.
%
%  Syntax
%  
%    [dW,LS] = learnsomb(W,P,Z,N,A,T,E,gW,gA,D,LP,LS)
%    info = learnsomb(code)
%
%  Description
%
%    LEARNSOMB is the batch self-organizing map weight learning function.
%
%    LEARNSOMB(W,P,Z,N,A,T,E,gW,gA,D,LP,LS) takes several inputs,
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
%    and returns,
%      dW - SxR weight (or bias) change matrix.
%      LS - New learning state.
%
%    Learning occurs according to LEARNSOMB's learning parameter,
%    shown here with its default value.
%      LP.init_neighborhood -  3 - Initial neighborhood size.
%      LP.steps - 100 - Ordering phase steps.
%
%    LEARNSOMB(CODE) returns useful information for each CODE string:
%      'pnames'    - Returns names of learning parameters.
%      'pdefaults' - Returns default learning parameters.
%      'needg'     - Returns 1 if this function uses gW or gA.
%
%  Examples
%
%    Here we define a random input P, output A, and weight matrix W,
%    for a layer with a 2-element input and 6 neurons.  We also calculate
%    the positions and distances for the neurons which are arranged in a
%    2x3 hexagonal pattern.
%
%      p = rand(2,1);
%      a = rand(6,1);
%      w = rand(6,2);
%      pos = hextop(2,3);
%      d = linkdist(pos);
%      lp = learnsomb('pdefaults');
%
%    Since LEARNSOM only needs these values to calculate a weight
%    change (see Algorithm below), we will use them to do so.
%
%      ls = [];
%      [dW,ls] = learnsomb(w,p,[],[],a,[],[],[],[],d,lp,ls)
%
%  Network Use
%
%    You can create a standard network that uses LEARNSOMB with NEWSOM.
%
%    To prepare the weights of layer i of a custom network
%    to learn with LEARNSOMB:
%    1) Set NET.trainFcn to 'trainr'.
%       (NET.trainParam will automatically become TRAINR's default parameters.)
%    2) Set NET.adaptFcn to 'trains'.
%       (NET.adaptParam will automatically become TRAINS's default parameters.)
%    3) Set each NET.inputWeights{i,j}.learnFcn to 'learnsomb'.
%       Set each NET.layerWeights{i,j}.learnFcn to 'learnsomb'.
%       (Each weight learning parameter property will automatically
%       be set to LEARNSOMB's default parameters.)
%
%    To train the network (or enable it to adapt):
%    1) Set NET.trainParam (or NET.adaptParam) properties as desired.
%    2) Call TRAIN (or ADAPT).
%
%  Algorithm
%
%    LEARNSOMB calculates the weight changes so that each neurons new
%    weight vector will be the weighted average of the input vectors
%    which that neuron and neuron's in its neighborhood responded to
%    with an output of 1.
%
%    The ordering phase lasts as many steps as LP.steps.
%    During this phase the neighborhood is gradually reduced from
%    a maximum size of LP.init_neighborhood down to 1, where it remains
%    from then on.
%
%  See also ADAPT, TRAIN.

% Copyright 2007-2008 The MathWorks, Inc.

% FUNCTION INFO
% =============
if ischar(w)
  switch lower(w)
  case 'name'
    dw = 'Batch Self-Organizing Map';
  case 'pnames'
    dw = fieldnames(learnsom('pdefaults'));
  case 'pdefaults'
    lp.init_neighborhood = 3;
    lp.steps = 100;
    dw = lp;
  case 'needg'
    dw = 0;
  otherwise
    error('NNET:Arguments','Unrecognized code.')
  end
  return
end

% CALCULATION
% ===========

[S,R] = size(w);
[R,Q] = size(p);

% Initial learning state
if isempty(ls)
  ls.step = 0;
end

% Neighborhood distance
nd = 1 + (lp.init_neighborhood-1) * (1-ls.step/lp.steps);
neighborhood = (d <= nd);

% Activations
a = a .* double(rand(size(a))<0.9);
a2 =  neighborhood * a + a;

suma2 = sum(a2,2);
loserIndex = (suma2 == 0);
suma2(loserIndex) = 1;
a3 = a2 ./ suma2(:,ones(1,Q));

neww = a3*p';
dw = neww - w;
dw(loserIndex,:) = 0;

% Next learning state
ls.step = ls.step + 1;
