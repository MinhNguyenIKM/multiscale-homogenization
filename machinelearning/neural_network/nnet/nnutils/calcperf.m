function [perf,El,Ac,N,BZ,IWZ,LWZ]=calcperf(net,X,PD,T,Ai,Q,TS)
%CALCPERF Calculate network outputs, signals, and performance.
%
%	Synopsis
%
%	  [perf,El,Ac,N,BZ,IWZ,LWZ]=calcperf(net,X,Pd,Tl,Ai,Q,TS)
%
%	Description
%
%	  This function calculates the outputs of each layer in
%	  response to a networks delayed inputs and initial layer
%	  delay conditions.
%
%	  [perf,El,Ac,N,LWZ,IWZ,BZ] = CALCPERF(NET,X,Pd,Tl,Ai,Q,TS) takes,
%	    NET - Neural network.
%	    X   - Network weight and bias values in a single vector.
%	    Pd  - Delayed inputs.
%	    Tl  - Layer targets.
%	    Ai  - Initial layer delay conditions.
%	    Q   - Concurrent size.
%	    TS  - Time steps.
%	  and returns,
%	    perf - Network performance.
%	    El   - Layer errors.
%	    Ac   - Combined layer outputs = [Ai, calculated layer outputs].
%	    N    - Net inputs.
%	    LWZ  - Weighted layer outputs.
%	    IWZ  - Weighted inputs.
%	    BZ   - Concurrent biases.
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
%	  two neurons are defined.
%
%	    Ai = {[0.5; 0.1] [0.6; 0.5]};
%
%	  Here we define the layer targets for the two neurons for
%	  each of the five time steps.
%	  
%	    Tl = {[0.1;0.2] [0.3;0.1], [0.5;0.6] [0.8;0.9], [0.5;0.1]};
%
%	  Here the network's weight and bias values are extracted.
%
%	    X = getx(net);
%
%	  Here we calculate the network's combined outputs Ac, and other
%	  signals described above..
%
%	    [perf,El,Ac,N,BZ,IWZ,LWZ] = calcperf(net,X,Pd,Tl,Ai,1,5)

% Mark Beale, 11-31-97
% Mark Beale, Updated help, 5-25-98
% Orlando De Jesús, Martin Hagan, Updated for parameters 7-20-05
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.9.4.7 $ $Date: 2007/11/09 20:55:45 $

% CALCA: [Ac,N,LWZ,IWZ,BZ] = calca(net,PD,Ai,Q,TS)
%=================================================

% Concurrent biases
BZ = cell(net.numLayers,1);
ones1xQ = ones(1,Q);
for i=net.hint.biasConnectTo
  BZ{i} = net.b{i}(:,ones1xQ);
end

% Signals
IWZ = cell(net.numLayers,net.numInputs,TS);
LWZ = cell(net.numLayers,net.numLayers,TS);
Ac = [Ai cell(net.numLayers,TS)];
N = cell(net.numLayers,TS);

% Shortcuts
numLayers = net.numLayers;
numInputs = net.numInputs;
OC = net.outputConnect;
numLayerDelays = net.numLayerDelays;
inputConnectFrom = net.hint.inputConnectFrom;
layerConnectFrom = net.hint.layerConnectFrom;
inputWeightFcn = net.hint.inputWeightFcn;
netInputFcn = net.hint.netInputFcn;
transferFcn = net.hint.transferFcn;
layerWeightFcn = net.hint.layerWeightFcn;
layerDelays = net.hint.layerDelays;
IW = net.IW;
LW = net.LW;

% Function parameters
netInputParam = cell(numLayers,1);  
transferParam = cell(numLayers,1);  
inputWeightParam = cell(numLayers,numInputs);  
layerWeightParam = cell(numLayers,numLayers);  
for i=1:net.numLayers
   netInputParam{i}=net.layers{i}.netInputParam;
   transferParam{i}=net.layers{i}.transferParam;
   for j=inputConnectFrom{i}
      inputWeightParam{i,j}=net.inputWeights{i,j}.weightParam;
   end
   for j=layerConnectFrom{i}
      layerWeightParam{i,j}=net.layerWeights{i,j}.weightParam;
   end
end

% Simulation
for ts=1:TS
  for i=net.hint.simLayerOrder
    ts2 = numLayerDelays + ts;
  
    % Input Weights -> Weighed Inputs
	  inputInds = inputConnectFrom{i};
    for j=inputInds
      switch func2str(inputWeightFcn{i,j})  
      case 'dotprod'  
        IWZ{i,j,ts} = IW{i,j} * PD{i,j,ts};  
      otherwise  
        IWZ{i,j,ts} = feval(inputWeightFcn{i,j},IW{i,j},PD{i,j,ts},inputWeightParam{i,j});
      end  
    end
    
    % Layer Weights -> Weighted Layer Outputs
	  layerInds = layerConnectFrom{i};
    for j=layerInds
	    thisLayerDelays = layerDelays{i,j};
	    if (length(thisLayerDelays) == 1) && (thisLayerDelays == 0)
	      Ad = Ac{j,ts2};
      else
	      Ad = cell2mat(Ac(j,ts2-layerDelays{i,j})');
      end
      switch func2str(layerWeightFcn{i,j})  
      case 'dotprod'  
        LWZ{i,j,ts} = LW{i,j} * Ad; 
      otherwise  
        LWZ{i,j,ts} = feval(layerWeightFcn{i,j},LW{i,j},Ad,layerWeightParam{i,j});
      end 
    end
  
    % Net Input Function -> Net Input
    Z = [IWZ(i,inputInds,ts) LWZ(i,layerInds,ts) BZ(i,net.biasConnect(i))];
    switch func2str(netInputFcn{i})  
    case 'netsum'  
      N{i,ts} = Z{1};  
      for k=2:length(Z)  
        N{i,ts} = N{i,ts} + Z{k}; 
      end  
    case 'netprod'  
      N{i,ts} = Z{1};  
      for k=2:length(Z)  
        N{i,ts} = N{i,ts} .* Z{k};  
      end  
    otherwise  
      N{i,ts} = feval(netInputFcn{i},Z,netInputParam{i});
    end  
	
    % Transfer Function -> Layer Output
    switch func2str(transferFcn{i})  
    case 'purelin'  
      Ac{i,ts2} = N{i,ts};  
    case 'tansig'  
      n = N{i,ts};  
      a = 2 ./ (1 + exp(-2*n)) - 1;  
      k = find(~isfinite(a));  
      a(k) = sign(n(k));  
      Ac{i,ts2} = a;  
    case 'logsig'  
      n = N{i,ts};  
      a = 1 ./ (1 + exp(-n));  
      k = find(~isfinite(a));  
      a(k) = sign(n(k));  
      Ac{i,ts2} = a;  
    otherwise  
      Ac{i,ts2} = feval(transferFcn{i},N{i,ts},transferParam{i});
    end  
  end
end

% Process Outputs
% ===============
Al = Ac(:,(numLayerDelays+1):end);
Yl = processoutputs(net,Al);

% Errors
%===============================
El = cell(net.numLayers,TS);
for ts = 1:TS
  for i=net.hint.outputInd
    el_i_ts = T{i,ts} - Yl{i,ts};
    %el_i_ts(isnan(el_i_ts)) = 0; % Clear unknown/don't-care errors
    El{i,ts} = el_i_ts;
  end
end

% Performance
%============
performFcn = net.performFcn;
if isempty(performFcn);  
  performFcn = 'nullpf';
end
perf = feval(performFcn,El(OC,:),Yl(OC,:),net,net.performParam);

