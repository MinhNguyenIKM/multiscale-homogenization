function jx=calcjx(net,PD,BZ,IWZ,LWZ,N,Ac,Q,TS)
%CALCJX Calculate weight and bias performance Jacobian as a single matrix.
%
%  Syntax
%
%    jx = calcjx(net,PD,BZ,IWZ,LWZ,N,Ac,Q,TS)
%
%  Description
%
%    This function calculates the Jacobian of a network's errors
%    with respect to its vector of weight and bias values X.
%
%    jX = CALCJX(NET,PD,BZ,IWZ,LWZ,N,Ac,Q,TS) takes,
%      NET    - Neural network.
%      PD     - Delayed inputs.
%      BZ     - Concurrent biases.
%      IWZ    - Weighted inputs.
%      LWZ    - Weighted layer outputs.
%      N      - Net inputs.
%      Ac     - Combined layer delay states and outputs.
%      Q      - Concurrent size.
%      TS     - Time steps.
%    and returns,
%      jX     - Jacobian of network errors with respect to X.
%
%  Examples
%
%    Here we create a linear network with a single input element
%    ranging from 0 to 1, two neurons, and a tap delay on the
%    input with taps at 0, 2, and 4 timesteps.  The network is
%    also given a recurrent connection from layer 1 to itself with
%    tap delays of [1 2].
%
%      net = newlin([0 1],2);
%      net.layerConnect(1,1) = 1;
%      net.layerWeights{1,1}.delays = [1 2];
%
%    Here is a single (Q = 1) input sequence P with 5 timesteps (TS = 5),
%    and the 4 initial input delay conditions Pi, combined inputs Pc,
%    and delayed inputs Pd.
%
%      P = {0 0.1 0.3 0.6 0.4};
%      Pi = {0.2 0.3 0.4 0.1};
%      Pc = [Pi P];
%      Pd = calcpd(net,5,1,Pc);
%
%    Here the two initial layer delay conditions for each of the
%    two neurons, and the layer targets for the two neurons over
%    five timesteps are defined.
%
%      Ai = {[0.5; 0.1] [0.6; 0.5]};
%      Tl = {[0.1;0.2] [0.3;0.1], [0.5;0.6] [0.8;0.9], [0.5;0.1]};
%
%    Here the network's weight and bias values are extracted, and
%    the network's performance and other signals are calculated.
%
%      [perf,El,Ac,N,BZ,IWZ,LWZ] = calcperf(net,X,Pd,Tl,Ai,1,5);
%
%    Finally we can use CALCJX to calculate the Jacobian.
%
%      jX = calcjx(net,Pd,BZ,IWZ,LWZ,N,Ac,1,5);
%
%  See also CALCGX, CALCJEJJ.

% Mark Beale, 11-31-97
% Mark Beale, Updated help, 5-25-98
% Orlando De Jesus, Martin Hagan, Changes for General Weight and Transfer
% Functions, 7-20-05
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.9.4.5 $ $Date: 2007/11/09 20:55:39 $

% Shortcuts
numLayerDelays = net.numLayerDelays;
TF = net.hint.transferFcn;
NF = net.hint.netInputFcn;
IWF = net.hint.inputWeightFcn;
LWF = net.hint.layerWeightFcn;
ICF = net.hint.inputConnectFrom;
LCF = net.hint.layerConnectFrom;
LCT = net.hint.layerConnectTo;
numLayers = net.numLayers;
numInputs = net.numInputs;  

% Functions and Parameters 
netInputParam = cell(numLayers,1);  
transferParam = cell(numLayers,1);  
inputWeightParam = cell(numLayers,numInputs);  
layerWeightParam = cell(numLayers,numLayers);  
for i=1:numLayers
  netInputParam{i}=net.layers{i}.netInputParam;
  transferParam{i} = net.layers{i}.transferParam;
   for j=ICF{i}
      inputWeightParam{i,j}=net.inputWeights{i,j}.weightParam;
    end
   for j=LCF{i}
      layerWeightParam{i,j}=net.layerWeights{i,j}.weightParam;
    end
end

% CALCULATE ERROR SIZE
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

% EXPAND SIGNALS
ind = floor((0:(QS-1))/S)+1;
for i=find(net.biasConnect)'
  BZ{i} = BZ{i}(:,ind);
end
for ts=1:TS
  for i=1:net.numLayers
    for j=find(net.inputConnect(i,:))
      PD{i,j,ts} = PD{i,j,ts}(:,ind);
      IWZ{i,j,ts} = IWZ{i,j,ts}(:,ind);
    end
  end
  for i=1:net.numLayers
    for j=find(net.layerConnect(i,:))
      LWZ{i,j,ts} = LWZ{i,j,ts}(:,ind);
    end
  end
  for i=1:net.numLayers
    N{i,ts} = N{i,ts}(:,ind);
  end
end
for ts=1:TS+numLayerDelays;
  for i=1:net.numLayers
    Ac{i,ts} = Ac{i,ts}(:,ind);
  end
end

Q = QS;

% Signals
gA = cell(net.numLayers,TS);
gN = cell(net.numLayers,TS);
gBZ = cell(net.numLayers,TS);
gIWZ = cell(net.numLayers,net.numInputs,TS);
gLWZ = cell(net.numLayers,net.numLayers,TS);
gB = gBZ;
gIW = gIWZ;
gLW = gIWZ;

% Backpropagate Derivatives...
for ts=TS:-1:1
  for i=net.hint.bpLayerOrder

    % ...from Performance
    if net.outputConnect(i)
      gA{i,ts} = gE{i,ts};
    else
      gA{i,ts} = zeros(net.layers{i}.size,Q);
    end
    
    % ...through Layer Weights
    for k=LCT{i}
      if (any(net.layerWeights{k,i}.delays == 0)) % only zero delay paths
        ZeroDelayW = net.LW{k,i}(:,1:net.layerWeights{k,i}.size(2));  
        temp = feval(LWF{k,i},'dp',ZeroDelayW,Ac{i,ts+numLayerDelays},LWZ{k,i,ts},layerWeightParam{k,i}); 
        if iscell(temp)
          for qq=1:Q,
            gA{i,ts}(:,qq) = gA{i,ts}(:,qq) + temp{qq}' * gLWZ{k,i,ts}(:,qq);
          end
        else
           gA{i,ts} = gA{i,ts} + temp' * gLWZ{k,i,ts};
        end  
      end
    end
  
    % ...through Transfer Functions
    Fdot = feval(TF{i},'dn',N{i,ts},Ac{i,ts+numLayerDelays},transferParam{i}); 
    if iscell(Fdot)  
      for qq=1:Q
        gN{i,ts}(:,qq) = Fdot{qq} * gA{i,ts}(:,qq);
      end
    else
      gN{i,ts} = Fdot .* gA{i,ts};
    end  
    
    % ...to Bias
  if net.biasConnect(i)
      Z = [BZ(i) IWZ(i,ICF{i},ts) LWZ(i,LCF{i},ts)]; 
      gBZ{i,ts} = feval(NF{i},'dz',1,Z,N{i,ts},netInputParam{i}) .* gN{i,ts};  

  end
       
    % ...to Input Weights
    jjj = 0; 
    for j=ICF{i}
      jjj = jjj +1; 
      Z = [IWZ(i,ICF{i},ts) LWZ(i,LCF{i},ts) BZ(i,net.biasConnect(i))]; 
      gIWZ{i,j,ts} = feval(NF{i},'dz',jjj,Z,N{i,ts},netInputParam{i}) .* gN{i,ts}; 
    end
     
    % ...to Layer Weights
    jjj = 0; 
    for j=LCF{i}
      jjj = jjj +1;
      Z = [LWZ(i,LCF{i},ts) IWZ(i,ICF{i},ts) BZ(i,net.biasConnect(i))]; 
      gLWZ{i,j,ts} = feval(NF{i},'dz',jjj,Z,N{i,ts},netInputParam{i}) .* gN{i,ts};
    end
  end
end

% Shortcuts
inputWeightCols = net.hint.inputWeightCols;
layerWeightCols = net.hint.layerWeightCols;

% Bias and Weight Gradients
for ts=1:TS
  for i=1:net.numLayers
    gB{i,ts} = gBZ{i,ts};
    for j=ICF{i}
       sW = feval(IWF{i,j},'dw',net.IW{i,j},PD{i,j,ts},IWZ{i,j,ts},inputWeightParam{i,j}); 
       class_WF = feval(IWF{i,j},'wfullderiv'); %mth 10/25/04
       % We work with information coming from weight size instead of layer size
       if iscell(sW) 
         temp = []; 
         for jjj=1:inputWeightCols(i,j)  
           for ss=1:size(net.IW{i,j},1) 
                temp = [temp;sW{ss}(jjj,:)];  
           end 
         end
           gIW{i,j,ts} = reprow(gIWZ{i,j,ts},inputWeightCols(i,j)) .* ...  
                     temp;  
       elseif class_WF==2,  
          temp = []; 
          for ss=1:size(net.IW{i,j},1),  
             temp = [temp; sum(reshape(sW(:,ss,:),[net.layers{i}.size(1) Q]).*gIWZ{i,j,ts},1)];  
          end  
          gIW{i,j,ts} = temp;  
       else 
         gIW{i,j,ts} = reprow(gIWZ{i,j,ts},inputWeightCols(i,j)) .* ...
                     reprowint(sW,net.inputWeights{i,j}.size(1));
       end 
       % We check for full derivative. If not we sum rows
    end
    for j=LCF{i}
    Ad = cell2mat(Ac(j,ts+numLayerDelays-net.layerWeights{i,j}.delays)');
      sW = feval(LWF{i,j},'dw',net.LW{i,j},Ad,LWZ{i,j,ts},layerWeightParam{i,j}); 
       class_WF = feval(LWF{i,j},'wfullderiv'); 
       if iscell(sW) 
         temp = []; 
         for jjj=1:layerWeightCols(i,j)  
           for ss=1:size(net.LW{i,j},1) 
                temp = [temp;sW{ss}(jjj,:)];  
           end 
         end
           gLW{i,j,ts} = reprow(gLWZ{i,j,ts},layerWeightCols(i,j)) .* ...  
                     temp;  
       elseif class_WF==2,  
          temp = []; 
          for ss=1:size(net.LW{i,j},1),  
             temp = [temp; sum(reshape(sW(:,ss,:),[net.layers{i}.size(1) Q]).*gLWZ{i,j,ts},1)];  
          end  
          gLW{i,j,ts} = temp;  
       else 
         gLW{i,j,ts} = reprow(gLWZ{i,j,ts},layerWeightCols(i,j)) .* ...
           reprowint(sW,net.layers{i}.size);
       end 
    end
  end
end

% Shortcuts
inputLearn = net.hint.inputLearn;
layerLearn = net.hint.layerLearn;
biasLearn = net.hint.biasLearn;
inputWeightInd = net.hint.inputWeightInd;
layerWeightInd = net.hint.layerWeightInd;
biasInd = net.hint.biasInd;

% gB{}, gIW{}, gLW{} -> jX()
jx = zeros(net.hint.xLen,QS*TS);
for i=1:net.numLayers
  for j=find(inputLearn(i,:))
    jx(inputWeightInd{i,j},:) = [gIW{i,j,:}];
  end
  for j=find(layerLearn(i,:))
    jx(layerWeightInd{i,j},:) = [gLW{i,j,:}];
  end
  if biasLearn(i)
    jx(biasInd{i},:) = [gB{i,:}];
  end
end

% ===========================================================
function m = repcol(m,n)
% REPLICATE COLUMNS OF Ac MATRIX

mcols = size(m,2);
m = m(:,rem(0:(mcols*n-1),mcols)+1);

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
function m = repcolint(m,n)
% REPLICATE COLUMNS OF MATRIX WITH ELEMENTS INTERLEAVED

mcols = size(m,2);
m = m(:,floor([0:(mcols*n-1)]/n)+1);

% ===========================================================
function m = reprow(m,n)
% REPLICATE ROWS OF Ac MATRIX

mrows = size(m,1);
m = m(rem(0:(mrows*n-1),mrows)+1,:);

% ===========================================================
function m = reprowint(m,n)
% REPLICATE ROWS OF MATRIX WITH ELEMENTS INTERLEAVED

mrows = size(m,1);
m = m(floor([0:(mrows*n-1)]/n)+1,:);

% ===========================================================

