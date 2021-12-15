function [Ac,N,LWZ,IWZ,BZ]=calca(net,PD,Ai,Q,TS)
%CALCA Calculate network outputs and other signals.
%
%	Syntax
%
%	  [Ac,N,LWZ,IWZ,BZ] = calca(net,Pd,Ai,Q,TS)
%
%	Description
%
%	  This function calculates the outputs of each layer in
%	  response to a networks delayed inputs and initial layer
%	  delay conditions.
%
%	  [Ac,N,LWZ,IWZ,BZ] = CALCA(NET,Pd,Ai,Q,TS) takes,
%	    NET - Neural network.
%	    Pd  - Delayed inputs.
%	    Ai  - Initial layer delay conditions.
%	    Q   - Concurrent size.
%	    TS  - Time steps.
%	  and returns,
%	    Ac  - Combined layer outputs = [Ai, calculated layer outputs].
%	    N   - Net inputs.
%	    LWZ - Weighted layer outputs.
%	    IWZ - Weighted inputs.
%	    BZ  - Concurrent biases.
%
%	Examples
%
%	  Here we create a linear network with a single input element
%	  ranging from 0 to 1, three neurons, and a tap delay on the
%	  input with taps at 0, 2, and 4 timesteps.  The network is
%	  also given a recurrent connection from layer 1 to itself with
%	  tap delays of [1 2].
%
%	    net = newlin([0 1],3,[0 2 4]);
%	    net.layerConnect(1,1) = 1;
%	    net.layerWeights{1,1}.delays = [1 2];
%
%	  Here is a single (Q = 1) input sequence P with 8 timesteps (TS = 8),
%	  and the 4 initial input delay conditions Pi, combined inputs Pc,
%	  and delayed inputs Pd.
%
%	    P = {0 0.1 0.3 0.6 0.4 0.7 0.2 0.1};
%	    Pi = {0.2 0.3 0.4 0.1};
%	    Pc = [Pi P];
%	    Pd = calcpd(net,8,1,Pc)
%
%	  Here the two initial layer delay conditions for each of the
%	  three neurons are defined:
%
%	    Ai = {[0.5; 0.1; 0.2] [0.6; 0.5; 0.2]};
%
%	  Here we calculate the network's combined outputs Ac, and other
%	  signals described above..
%
%	    [Ac,N,LWZ,IWZ,BZ] = calca(net,Pd,Ai,1,8)

% Mark Beale, 11-31-97
% Mark Beale, Updated help, 5-25-98
% Copyright 1992-2005 The MathWorks, Inc.
% $Revision: 1.8.4.2 $ $Date: 2005/12/22 18:22:17 $

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
numLayerDelays = net.numLayerDelays;
inputConnectFrom = net.hint.inputConnectFrom;
layerConnectFrom = net.hint.layerConnectFrom;
biasConnectFrom = net.hint.biasConnectFrom;
layerDelays = net.hint.layerDelays;
IW = net.IW;
LW = net.LW;

% Functions & Parameters
inputWeightFcn = net.hint.inputWeightFcn;
netInputFcn = net.hint.netInputFcn;
transferFcn = net.hint.transferFcn;
layerWeightFcn = net.hint.layerWeightFcn;
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
      IWZ{i,j,ts} = feval(inputWeightFcn{i,j},IW{i,j},PD{i,j,ts},inputWeightParam{i,j});
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
      LWZ{i,j,ts} = feval(layerWeightFcn{i,j},LW{i,j},Ad,layerWeightParam{i,j});
    end
  
    % Net Input Function -> Net Input
    Z = [IWZ(i,inputInds,ts) LWZ(i,layerInds,ts) BZ(i,net.biasConnect(i))];
    N{i,ts} = feval(netInputFcn{i},Z,netInputParam{i});
	
    % Transfer Function -> Layer Output
    Ac{i,ts2} = feval(transferFcn{i},N{i,ts},transferParam{i});
  end
end
