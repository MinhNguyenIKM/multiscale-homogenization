function jx=calcjxfp(net,PD,BZ,IWZ,LWZ,N,Ac,Q,TS)
%CALCJXFP Calculate weight and bias performance Jacobian as a single matrix.
%
%	Syntax
%
%	  jx = calcjxfp(net,PD,BZ,IWZ,LWZ,N,Ac,Q,TS)
%
%	Description
%
%	  This function calculates the Jacobian of a network's errors
%	  with respect to its vector of weight and bias values X.
%
%	  jX = CALCJXFP(NET,PD,BZ,IWZ,LWZ,N,Ac,Q,TS) takes,
%	    NET    - Neural network.
%	    PD     - Delayed inputs.
%	    BZ     - Concurrent biases.
%	    IWZ    - Weighted inputs.
%	    LWZ    - Weighted layer outputs.
%	    N      - Net inputs.
%	    Ac     - Combined layer outputs.
%	    Q      - Concurrent size.
%	    TS     - Time steps.
%	  and returns,
%	    jX     - Jacobian of network errors with respect to X.
%
%	Examples
%
%	  Here we create a linear network with a single input element
%	  ranging from 0 to 1, two neurons, and a tap delay on the
%	  input with taps at 0, 2, and 4 timesteps.  The network is
%	  also given a recurrent connection from layer 1 to itself with
%	  tap delays of [1 2].
%
%	    net = newlin([0 1],2);
%	    net.layerConnect(1,1) = 1;
%	    net.layerWeights{1,1}.delays = [1 2];
%
%    We initialize the weights to specific values:
%
%      net.IW{1}=[0.1;0.2];
%      net.LW{1}=[0.01 0.02 0.03 0.04; 0.05 0.06 0.07 0.07];
%      net.b{1}=[0.3; 0.4];
%
%	  Here is a single (Q = 1) input sequence P with 5 timesteps (TS = 5),
%	  and the 4 initial input delay conditions Pi, combined inputs Pc,
%	  and delayed inputs Pd.
%
%	    P = {0 0.1 0.3 0.6 0.4};
%	    Pi = {0.2 0.3 0.4 0.1};
%	    Pc = [Pi P];
%	    Pd = calcpd(net,5,1,Pc);
%
%	  Here the two initial layer delay conditions for each of the
%	  two neurons, and the layer targets for the two neurons over
%	  five timesteps are defined.
%
%	    Ai = {[0.5; 0.1] [0.6; 0.5]};
%	    Tl = {[0.1;0.2] [0.3;0.1], [0.5;0.6] [0.8;0.9], [0.5;0.1]};
%
%	  Here the network's weight and bias values are extracted, and
%	  the network's performance and other signals are calculated.
%
%	    [perf,El,Ac,N,BZ,IWZ,LWZ] = calcperf(net,X,Pd,Tl,Ai,1,5);
%
%	  Finally we can use CALCJXFP to calculate the Jacobian.
%
%	    jX = calcjxfp(net,Pd,BZ,IWZ,LWZ,N,Ac,1,5);
%
%    IMPORTANT: If you use the regular CALCJX the gradient values will
%               differ because the dynamics is not being considered.
%
%	See also CALCGX, CALCJXBT.

% Orlando De Jesus, Matin Hagan, 7-20-05
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.4 $ $Date: 2007/11/09 20:55:41 $

% CALCULATE ERROR SIZE
numLayerDelays = net.numLayerDelays;
S = net.hint.totalOutputSize;
QS = Q*S;

% CALCULATE ERROR CONNECTIONS
QNegEyes =  repcol(-eye(S),Q);
gE = cell(net.numLayers,TS);
pos = 0;
for i=net.hint.outputInd
  for ts=1:TS
    siz = net.outputs{i}.size;
    gE{i,ts} = QNegEyes(pos+(1:siz),:);
  end
  pos = pos + siz;
end

% Output processing
A = cell(net.numLayers,TS);
for i=net.hint.outputInd
  for ts=1:TS
    A{i,ts} = repcolint(Ac{i,numLayerDelays+ts},S);
  end
end
gE = processperfoutputderiv(net,A,gE,QS);

% We use the calcgfp function to obtain the individual gradient values.
[gB,gIW,gLW]=calcgfp(net,Q,PD,BZ,IWZ,LWZ,N,Ac,gE,TS,1);

% Shortcuts
inputLearn = net.hint.inputLearn;
layerLearn = net.hint.layerLearn;
biasLearn = net.hint.biasLearn;
inputWeightInd = net.hint.inputWeightInd;
layerWeightInd = net.hint.layerWeightInd;
biasInd = net.hint.biasInd;

% We convert gB{}, gIW{}, gLW{} -> jX()
jx = zeros(net.hint.xLen,QS*TS);
for ss=1:S
   for qq=1:Q
      for ts=1:TS
         for i=1:net.numLayers
            for j=find(inputLearn(i,:))
               jx(inputWeightInd{i,j},(ts-1)*QS+(qq-1)*S+ss) = gIW{i,j,(ts-1)*QS+(qq-1)*S+ss}(:);
            end
            for j=find(layerLearn(i,:))
               jx(layerWeightInd{i,j},(ts-1)*QS+(qq-1)*S+ss) = gLW{i,j,(ts-1)*QS+(qq-1)*S+ss}(:);
            end
            if biasLearn(i)
               jx(biasInd{i},(ts-1)*QS+(qq-1)*S+ss) = gB{i,(ts-1)*QS+(qq-1)*S+ss}(:);
            end
         end
      end
   end
end

% ===========================================================
function b = col2diag(a)
% REARRANGE NxM matrix A into an Nx(N*M) matrix B
% where the columns of A are expanded into diagonal submatrices of B.

[n,m] = size(a);
b = zeros(n,n*m);
submatrixElements = n*n;
for i=1:m
  ind = (1:n)+(0:n:((n-1)*n))+(i-1)*submatrixElements;
  b(ind) = a(:,i);
end

% ===========================================================
function m = repcol(m,n)
% REPLICATE COLUMNS OF Ac MATRIX

mcols = size(m,2);
m = m(:,rem(0:(mcols*n-1),mcols)+1);

% ===========================================================
function m = repcolint(m,n)
% REPLICATE COLUMNS OF MATRIX WITH ELEMENTS INTERLEAVED

mcols = size(m,2);
m = m(:,floor([0:(mcols*n-1)]/n)+1);

% ===========================================================
