function [gB,gIW,gLW,gA]=calcgrad(net,Q,PD,BZ,IWZ,LWZ,N,Ac,gE,TS)
%CALCGRAD Calculate bias and weight performance gradients.
%
%	Synopsis
%
%	  [gB,gIW,gIW] = calcgrad(net,Q,PD,BZ,IWZ,LWZ,N,Ac,gE,TS)
%
%	Warning!!
%
%	  This function may be altered or removed in future
%	  releases of the Neural Network Toolbox. We recommend
%	  you do not write code which calls this function.

% Mark Beale, 11-31-97
% Orlando De Jesus, Martin Hagan, Changes for General Weight and Transfer
% Functions, 7-20-05
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.11.4.5 $ $Date: 2007/11/09 20:55:36 $

% Shortcuts
numLayers = net.numLayers;
numInputs = net.numInputs;
numLayerDelays = net.numLayerDelays;
layerWeights=net.layerWeights; 
inputWeights=net.inputWeights; 
TF = net.hint.transferFcn;
NF = net.hint.netInputFcn;
IWF = net.hint.inputWeightFcn;
LWF = net.hint.layerWeightFcn;
ICF = net.hint.inputConnectFrom;
LCF = net.hint.layerConnectFrom;
LCTOZD = net.hint.layerConnectToOZD;
LCTWZD = net.hint.layerConnectToWZD;
IW = net.IW;
LW = net.LW;
layerDelays = net.hint.layerDelays;

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

% AD
Ad = cell(numLayers,numLayers,TS);
for i=1:numLayers
  for j = LCF{i}
    for ts = 1:TS
      Ad{i,j,ts} = cell2mat(Ac(j,ts+numLayerDelays-layerDelays{i,j})');
    end
  end
end

% Compress Time for Elman backprop
Ae = cell(numLayers,1);
for i=1:numLayers
  Ae{i} = [Ac{i,(1+numLayerDelays):end}];
end
LWZe = cell(numLayers,1);
for i=1:numLayers
  for j=LCF{i}
    LWZe{i,j} = [LWZ{i,j,:}];
  end
end
Q = size(Ae{1},2); 

% Signals
gA = cell(numLayers,1);
gN = cell(numLayers,1);
gLWZ = cell(numLayers,numLayers);
gB = cell(numLayers,1);
gIW = cell(numLayers,numInputs);
gLW = cell(numLayers,numLayers);

% Backpropagate Elman Derivatives...
for i=net.hint.bpLayerOrder

  % ...from Performance
  if net.outputConnect(i)
    gA{i} = [gE{i,:}];
  else
    gA{i} = zeros(net.layers{i}.size,Q); 
  end

  % ...through Layer Weights with only zero delays
  Nc = [N{i,:}];
  for k=LCTOZD{i}
    switch func2str(LWF{k,i})  
    case 'dotprod'  
      gA{i} = gA{i} + LW{k,i}' * gLWZ{k,i};  
    otherwise  
      temp = feval(LWF{k,i},'dp',LW{k,i},Ae{i},LWZe{k,i},layerWeightParam{k,i})'; 
      if iscell(temp)
        for qq=1:Q
          gA{i}(:,qq) = gA{i}(:,qq) + temp{qq}' * gLWZ{k,i}(:,qq); 
        end
      else
        gA{i} = gA{i} + temp * gLWZ{k,i};
      end
    end  
  end

  % ...through Layer Weights with zero delays + others too be ignored
  for k=LCTWZD{i}
    ZeroDelayW = LW{k,i}(:,1:net.layers{i}.size);
    switch func2str(LWF{k,i})  
    case 'dotprod' 
      gA{i} = gA{i} + ZeroDelayW' * gLWZ{k,i};
    otherwise 
	  gA{i} = gA{i} + feval(LWF{k,i},'dp',ZeroDelayW,Ae{k},LWZe{k,i},layerWeightParam{k,i})' * gLWZ{k,i}; 
    end
  end

  % ...through Transfer Functions
  switch func2str(TF{i})
  case 'purelin'
    gN{i} = gA{i};
  case 'tansig'
    gN{i} = (1-(Ae{i}.*Ae{i})) .* gA{i};
  case 'logsig'
    gN{i} = Ae{i}.*(1-Ae{i}) .* gA{i};
      otherwise
    Fdot = feval(TF{i},'dn',Nc,Ae{i},transferParam{i}); 
    if iscell(Fdot)  
      for qq=1:Q
        gN{i}(:,qq) = Fdot{qq} * gA{i}(:,qq);
      end
    else
      gN{i} = Fdot .* gA{i};
    end  
  end
  
  % ...to Bias
  if net.biasConnect(i)
    Z = [BZ(i) IWZ(i,ICF{i}) LWZ(i,LCF{i})];
    switch func2str(NF{i})  
    case 'netsum'  
        NderivZ = ones(size(Nc)); 
    otherwise  
        NderivZ = feval(NF{i},'dz',1,Z,Nc,netInputParam{i}); 
    end  
    gB{i} = sum(NderivZ .* gN{i},2);  
  end

  % ...to Input Weights
  jjj = 0; 
  for j=ICF{i}
    gIW{i,j} = zeros(inputWeights{i,j}.size); 
    jjj = jjj+1; 
    IWZc = [IWZ{i,j,:}];
    Z = [IWZ(i,ICF{i}) LWZ(i,LCF{i}) BZ(i,net.biasConnect(i))]; 
    
    % Find derivative of net input function
    switch func2str(NF{i})  
    case 'netsum'  
      NderivZ = ones(size(Nc));
    otherwise  
      NderivZ = feval(NF{i},'dz',jjj,Z,Nc,netInputParam{i});  
    end       
    temp1 = NderivZ .* gN{i};

    % Find derivative of weight function
    switch func2str(IWF{i,j})
    case 'dotprod'
      IWderivW = [PD{i,j,:}];
      class_WF = 0;
    otherwise
      IWderivW = feval(IWF{i,j},'dw',IW{i,j},[PD{i,j,:}],IWZc,inputWeightParam{i,j}); 
      class_WF = feval(IWF{i,j},'wfullderiv'); 
    end  
    if iscell(IWderivW)
      for ss=1:size(gN{i},1)
        gIW{i,j}(ss,:) = temp1(ss,:) * IWderivW{ss}';  
      end
    elseif class_WF==2,  
      for qq=1:Q,  
        gIW{i,j} = gIW{i,j} + IWderivW(:,:,qq)' * temp1(:,qq);  
      end  
    else
      gIW{i,j} = temp1 * IWderivW';
    end
  end

  % ...to Layer Weights
  jjj = 0; 
  for j=LCF{i}
    gLW{i,j} = zeros(layerWeights{i,j}.size); 
    jjj = jjj +1; 
    Z = [LWZ(i,LCF{i}) IWZ(i,ICF{i}) BZ(i,net.biasConnect(i))]; 
     
    % Find derivative of net input function
    switch func2str(NF{i})  
    case 'netsum'  
      NderivZ = ones(size(Nc)); 
    otherwise 
      NderivZ = feval(NF{i},'dz',jjj,Z,Nc,netInputParam{i});  
    end       
    gLWZ{i,j} = NderivZ .* gN{i};  

    % Find derivative of weight function
    switch func2str(LWF{i,j})  
    case 'dotprod'  
      LWderivW = [Ad{i,j,:}];  
      class_WF = 0;  
    otherwise  
      LWderivW = feval(LWF{i,j},'dw',LW{i,j},[Ad{i,j,:}],LWZe{i,j},layerWeightParam{i,j});  
      class_WF = feval(LWF{i,j},'wfullderiv'); 
    end  
          
    if iscell(LWderivW)
      for ss=1:size(gLWZ{i,j},1)
        gLW{i,j}(ss,:) = gLWZ{i,j}(ss,:) * LWderivW{ss}';  
      end
    elseif class_WF==2,  
      for qq=1:Q,  
        gLW{i,j} = gLW{i,j} + LWderivW(:,:,qq)' * gLWZ{i,j}(:,qq);  
      end  
    else
      gLW{i,j} = gLWZ{i,j} * LWderivW';
    end
  end
end

