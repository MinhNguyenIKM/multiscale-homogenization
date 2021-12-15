function net = newfit(varargin)
%NEWFIT Create a fitting network.
%
%  Syntax
%
%    net = newfit(P,T,S,TF,BTF,BLF,PF,IPF,OPF,DDF)
%
%  Description
%
%    NEWFIT(P,T,S,TF,BTF,BLF,PF,IPF,OPF,DDF) takes,
%      P  - RxQ1 matrix of Q1 representative R-element input vectors.
%      T  - SNxQ2 matrix of Q2 representative SN-element target vectors.
%      Si  - Sizes of N-1 hidden layers, S1 to S(N-1), default = [].
%            (Output layer size SN is determined from T.)
%      TFi - Transfer function of ith layer. Default is 'tansig' for
%            hidden layers, and 'linear' for output layer.
%      BTF - Backprop network training function, default = 'trainlm'.
%      BLF - Backprop weight/bias learning function, default = 'learngdm'.
%      PF  - Performance function, default = 'mse'.
%      IPF - Row cell array of input processing functions.
%            Default is {'fixunknowns','remconstantrows','mapminmax'}.
%      OPF - Row cell array of output processing functions.
%            Default is {'remconstantrows','mapminmax'}.
%      DDF - Data division function, default = 'dividerand';
%    and returns an N layer feed-forward backprop network.
%
%    The transfer functions TF{i} can be any differentiable transfer
%    function such as TANSIG, LOGSIG, or PURELIN.
%
%    The training function BTF can be any of the backprop training
%    functions such as TRAINLM, TRAINBFG, TRAINRP, TRAINGD, etc.
%
%    *WARNING*: TRAINLM is the default training function because it
%    is very fast, but it requires a lot of memory to run.  If you get
%    an "out-of-memory" error when training try doing one of these:
%
%    (1) Slow TRAINLM training, but reduce memory requirements, by
%        setting NET.trainParam.mem_reduc to 2 or more. (See HELP TRAINLM.)
%    (2) Use TRAINBFG, which is slower but more memory efficient than TRAINLM.
%    (3) Use TRAINRP which is slower but more memory efficient than TRAINBFG.
%
%    The learning function BLF can be either of the backpropagation
%    learning functions such as LEARNGD, or LEARNGDM.
%
%    The performance function can be any of the differentiable performance
%    functions such as MSE or MSEREG.
%
%  Examples
%
%    load simplefit_dataset
%    net = newfit(simplefitInputs,simplefitTargets,20);
%    net = train(net,simplefitInputs,simplefitTargets);
%    simplefitOutputs = sim(net,simplefitInputs);
%
%  Algorithm
%
%    NEWFIT returns a network exactly as NEWFF would, but with an
%    additional plotting function, PLOTFIT, included in the
%    networks net.plotFcns property.
%
%  See also NEWFF, NEWCF, NEWELM, SIM, INIT, ADAPT, TRAIN, TRAINS

% Copyright 2007 The MathWorks, Inc.

if nargin < 2, error('NNET:Arguments','Not enough input arguments'), end

net = newff(varargin{:});
net.plotFcns = {'plotperform','plottrainstate','plotfit','plotregression'};
