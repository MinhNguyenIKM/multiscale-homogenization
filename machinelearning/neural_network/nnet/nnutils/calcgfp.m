function [gB,gIW,gLW]=calcgfp(net,Q,PD,BZ,IWZ,LWZ,N,Ac,gE,TS,time_base)
%CALCGFP Calculate bias and weight performance gradients.
%
%	Synopsis
%
%	  [gB,gIW,gLW] = calcgfp(net,Q,PD,BZ,IWZ,LWZ,N,Ac,gE,TS,time_base)
%
%	Warning!!
%
%	  This function may be altered or removed in future
%	  releases of the Neural Network Toolbox. We recommend
%	  you do not write code which calls this function.

% Orlando De Jesus, Matin Hagan, 7-20-05
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.5 $ $Date: 2007/11/09 20:55:34 $

% If last parameter missing we execute regular gradient
if nargin <11
    time_base=0;
end
    
% Shortcuts
numLayers = net.numLayers;
numInputs = net.numInputs;
numLayerDelays = net.numLayerDelays;
layerWeights=net.layerWeights;
bpLayerOrder=net.hint.bpLayerOrder;
outputConnect=net.outputConnect;
biasConnect=net.biasConnect;
biases=net.biases;
inputWeights=net.inputWeights;
layers=net.layers;
simLayerOrder=net.hint.simLayerOrder;
inputConnect=net.inputConnect;
ICF = net.hint.inputConnectFrom;
LCF = net.hint.layerConnectFrom;
LCT = net.hint.layerConnectTo;
LCTOZD = net.hint.layerConnectToOZD;
layerDelays = net.hint.layerDelays;
IW = net.IW;
LW = net.LW;

% Functions and Parameters
TF = net.hint.transferFcn;
netInputFcn = net.hint.netInputFcn;
IWF = net.hint.inputWeightFcn;
LWF = net.hint.layerWeightFcn;
netInputParam = cell(numLayers,1);  
transferParam = cell(numLayers,1);  
inputWeightParam = cell(numLayers,numInputs);  
layerWeightParam = cell(numLayers,numLayers);  
LWsize1 = zeros(numLayers,numLayers);  
LWsize2 = zeros(numLayers,numLayers);  
IWsize1 = zeros(numLayers,numInputs);  
IWsize2 = zeros(numLayers,numInputs);  
for i=1:numLayers
  netInputParam{i}=net.layers{i}.netInputParam;
  transferParam{i} = net.layers{i}.transferParam;
   for j=ICF{i}
      inputWeightParam{i,j}=net.inputWeights{i,j}.weightParam;
      IWsize1(i,j) = inputWeights{i,j}.size(1);  
      IWsize2(i,j) = inputWeights{i,j}.size(2);  
    end
   for j=LCF{i}
      layerWeightParam{i,j}=net.layerWeights{i,j}.weightParam;
      LWsize1(i,j) = layerWeights{i,j}.size(1);  
      LWsize2(i,j) = layerWeights{i,j}.size(2);
    end
end

SS = net.hint.totalOutputSize;
QS=Q*SS;
forw_redun_order=[];

LCTWD = cell(numLayers);
LCFWD = cell(numLayers);
for i=simLayerOrder
   LCTWD{i}=setxor(LCT{i},LCTOZD{i});
   LCFWD{i}=[];
   for j=LCF{i}
      if any(layerWeights{i,j}.delays~=0)
         LCFWD{i}=[LCFWD{i} j];
      end
   end
   if outputConnect(i) || size(LCTWD{i},1)~=0
      forw_redun_order=[forw_redun_order i];
   end
end

% Variables used to save partial gradient values
gIWZ = cell(numLayers,net.numInputs,numLayers,Q);
gLWZ = cell(numLayers,numLayers,numLayers);
gyB = cell(numLayers,numLayers,numLayerDelays + 1,Q);
gyIW = cell(numLayers,net.numInputs,numLayers,numLayerDelays + 1,Q);
gyLW = cell(numLayers,numLayers,numLayers,numLayerDelays + 1,Q);

% We create gradient variables in case we want each gradient per sample and time
if time_base
   gB = cell(numLayers,TS*QS);
   gIW = cell(numLayers,net.numInputs,TS*QS);
   gLW = cell(numLayers,numLayers,TS*QS);
else   % Full gradient will be returned
   gB = cell(numLayers,1);
   gIW = cell(numLayers,net.numInputs);
   gLW = cell(numLayers,numLayers);
end

% Variable to save delays between layers
input_delays = cell(numLayers,numLayers);

% Variable to save sensitivities.
S = cell(numLayers,numLayers);

% We include calculation of Ad (input at each layer in time)
Ad = cell(numLayers,numLayers,TS);
for i=1:numLayers
  for j = LCF{i}
    for ts = 1:TS
      Ad{i,j,ts} = cell2mat(Ac(j,ts+numLayerDelays-layerDelays{i,j})');
    end
  end
end

% All output layers concentrated in an element per layer.
Ae = cell(numLayers,1);
for i=1:numLayers
  Ae{i} = [Ac{i,(1+numLayerDelays):end}];
end

% Set of all layers where the sensitivity is different from zero.
ES = cell(1,numLayers);
% Set of all input layers where the sensitivity is different from zero.
ESx = cell(1,numLayers);

% This loop is only done once to initialize common variables
for i=bpLayerOrder
   % Bias initialization
   if biasConnect(i)
      if time_base
         [gB{i,1:TS*QS}]=deal(zeros(biases{i}.size,1));
      else
         gB{i}=zeros(biases{i}.size,1);
      end
      if numLayerDelays
         for jz2=forw_redun_order
            [gyB{i,jz2,1:numLayerDelays,1:Q}]=deal(zeros(biases{i}.size,layers{jz2}.size));
         end
      end
   end
   % Input weight initialization
   for j=ICF{i}
      if time_base
         [gIW{i,j,1:TS*QS}]=deal(zeros(inputWeights{i,j}.size));
      else
         gIW{i,j}=zeros(inputWeights{i,j}.size);
      end
      if numLayerDelays
         for jz2=forw_redun_order
            [gyIW{i,j,jz2,1:numLayerDelays,1:Q}]=deal(zeros(layers{jz2}.size, ...
                                                 IWsize1(i,j)*IWsize2(i,j)));   
         end
      end
   end
   % Layer weight initialization
   for j=LCF{i}
      if time_base
         [gLW{i,j,1:TS*QS}]=deal(zeros(layerWeights{i,j}.size));
      else
         gLW{i,j}=zeros(layerWeights{i,j}.size);
      end
      if numLayerDelays
         for jz2=forw_redun_order
            [gyLW{i,j,jz2,1:numLayerDelays,1:Q}]=deal(zeros(layers{jz2}.size, ...
                                                 LWsize1(i,j)*LWsize2(i,j)));  
         end
      end
      % We save delays between layers
      input_delays{i,j}=layerWeights{i,j}.delays;
   end
end

% Backpropagate Derivatives...
for ts=1:TS
   % initialization of common variables after each iteration
   for i=bpLayerOrder
      % Bias initialization
      if biasConnect(i)
         for jz2=forw_redun_order
            [gyB{i,jz2,numLayerDelays+1,1:Q}]=deal(zeros(biases{i}.size,layers{jz2}.size));
         end
      end
      % Input weight initialization
      for j=ICF{i}
         for jz2=forw_redun_order
            [gyIW{i,j,jz2,numLayerDelays+1,1:Q}]=deal(zeros(layers{jz2}.size, ...
                                                      IWsize1(i,j)*IWsize2(i,j)));  
         end
      end
      % layer weight initialization
      for j=LCF{i}
         for jz2=forw_redun_order
            for qq=1:Q
               gyLW{i,j,jz2,numLayerDelays+1,qq}=zeros(layers{jz2}.size, ...
                                                 LWsize1(i,j)*LWsize2(i,j));  
            end
         end
      end
   end % of for i=bpLayerOrder
  
   % We must clear this variable here for each iteration.
   % Set of output layers with sensitivity Sm,m was calculated.
   Uprime = [];
  
   % We follow backpropagation order
   for i=bpLayerOrder
      % For all layer with sensitivity Sm,m calculated
      for u=Uprime
         S_temp = calcfdot(i,TF,transferParam,ts,Q,Ae,numLayerDelays,N,0);
         
         % ...through Layer Weights with only zero delays
         for k=LCTOZD{i}
            if size(S{u,k},1)>0 && size(S{u,k},4)>=ts && size(gLWZ{k,i,u},4)>=ts
               % We initialize new S if needed.
               if size(S{u,i},1)==0
                  S{u,i} = zeros(layers{u}.size,layers{i}.size,Q,TS);
               end
               % Weight function derivative is calculated
               switch func2str(LWF{k,i})   
               case 'dotprod'   
                 for qq=1:Q  
                   S{u,i}(:,:,qq,ts) = S{u,i}(:,:,qq,ts) + ...
                                   ((gLWZ{k,i,u}(:,:,qq,ts)'.*S{u,k}(:,:,qq,ts)) * LW{k,i} * S_temp(:,:,qq,ts)); 
                 end
	           otherwise    
                  for qq=1:Q
                     temp = feval(LWF{k,i},'dp',LW{k,i},Ae{i}(:,(ts-1)*Q+qq),LWZ{k,i,ts}(:,qq),layerWeightParam{k,i}); 
                     % If derivative is a cell we select special cell qq.
                     if iscell(temp)
                        S{u,i}(:,:,qq,ts) = S{u,i}(:,:,qq,ts) + ((gLWZ{k,i,u}(:,:,qq,ts)'.*S{u,k}(:,:,qq,ts)) * temp{1} * S_temp(:,:,qq,ts));
                     else
                        S{u,i}(:,:,qq,ts) = S{u,i}(:,:,qq,ts) + ((gLWZ{k,i,u}(:,:,qq,ts)'.*S{u,k}(:,:,qq,ts)) * temp * S_temp(:,:,qq,ts));
                     end
                  end
               end
               % We save layer in set of all layers where the sensitivity is different from zero.
               ES{i}=nnunion(ES{i},i);  
               % If layer connected to an input we save in ESx
               if any(inputConnect(i,:)) || any(LCFWD{i})
                  ESx{u}=nnunion(ESx{u},i);   
               end
            end
         end
      end
     
      % If layer connected to a target or not connected to layer with delays
      if outputConnect(i) || size(LCTWD{i},1)~=0
         % We evaluate sensitivity
         S{i,i} = calcfdot(i,TF,transferParam,ts,Q,Ae,numLayerDelays,N,0);
         % We save in set of output layers with sensitivity Sm,m was calculated.
         Uprime = nnunion(Uprime,i);  
         % We save layer in set of all layers where the sensitivity is different from zero.
         ES{i}=nnunion(ES{i},i);  
         % If layer connected to an input we save in ESx
         if any(inputConnect(i,:)) || any(LCFWD{i})
            ESx{i}=nnunion(ESx{i},i);  
         end
      end
    
      % ...to Bias
      if biasConnect(i)
         % For all layers where the sensitivity Sk,i exist.
         switch func2str(netInputFcn{i})  
         case 'netsum'  
           dz = ones(size(N{i,ts}));  
         otherwise  
           Z = [BZ(i) IWZ(i,ICF{i},ts) LWZ(i,LCF{i},ts)];  
           dz = feval(netInputFcn{i},'dz',1,Z,N{i,ts},netInputParam{i});  
         end  
         for k=Uprime
            if size(S{k,i},1)>0
               % For all batches
               for qq=1:Q
                  % Derivative is sensitivity by net input function derivative.
                  gyB{i,k,numLayerDelays+1,qq} = (S{k,i}(:,:,qq,ts) * diag(dz(:,qq)))';
               end
            end
         end
      end
    
      % ...to Input Weights
      jjj = 0; 
      for j=ICF{i}
         jjj = jjj +1; 
         % For all layers where the sensitivity Sk,i exist.
        Z = [IWZ(i,ICF{i},ts) LWZ(i,LCF{i},ts) BZ(i,biasConnect(i))];  
        switch func2str(netInputFcn{i})  
        case 'netsum'  
          dz = ones(size(N{i,ts}));  
        otherwise  
          dz = feval(netInputFcn{i},'dz',jjj,Z,N{i,ts},netInputParam{i});  
        end  
        dotprod_flag = strcmp(func2str(IWF{i,j}),'dotprod');  
        if dotprod_flag,
            class_WF = 0;
        else
            class_WF = feval(IWF{i,j},'wfullderiv');
        end
        for k=Uprime
            if size(S{k,i},1)>0
               % Calculation continues for all batches ...
               for qq=1:Q
                  % Derivative is sensitivity by net input function derivative.
                  gIWZ = S{k,i}(:,:,qq,ts) * diag(dz(:,qq));  
                  % Input Weight function derivative
                  if dotprod_flag,  
                    temp = PD{i,j,ts}(:,qq)';  
                  else  
                    temp = feval(IWF{i,j},'dw',IW{i,j},PD{i,j,ts}(:,qq),IWZ{i,j,ts}(:,qq),inputWeightParam{i,j})';  
                  end  
                  % If a cell is returned we have a derivative for each batch.
                  if iscell(temp)
                     temp2=[];
                      for jj=1:size(gIWZ,2)
                        temp3=[];
                        for ii=1:size(gIWZ,1)
                           temp3=[temp3;[temp{jj}]'*gIWZ(ii,jj)];
                        end
                        temp2=[temp2 temp3];
                     end
                  % General Weight Functions
                  elseif class_WF==2 
                     temp2=gIWZ*temp';
                  else  % Regular case if returned value is a matrix.
                     temp2 = kron(gIWZ,temp);
                  end 
                  % Final derivative of layer output respect to input Weight
                  gyIW{i,j,k,numLayerDelays+1,qq}=temp2;
               end
            end
         end
      end
	  
      % ...to Layer Weights
      jjj = 0; 
      for j=LCF{i}
         jjj = jjj +1; 
         Z = [LWZ(i,LCF{i},ts) IWZ(i,ICF{i},ts) BZ(i,biasConnect(i))];    
         switch func2str(netInputFcn{i})    
         case 'netsum'    
           dz = ones(size(N{i,ts}));    
         otherwise    
           dz = feval(netInputFcn{i},'dz',jjj,Z,N{i,ts},netInputParam{i});  
         end    
         dotprod_flag = strcmp(func2str(LWF{i,j}),'dotprod');  
         if dotprod_flag,
            class_WF = 0;
         else
            class_WF = feval(LWF{i,j},'wfullderiv');
         end
         for k=Uprime
            if size(S{k,i},1)>0
               % Calculation continues for all batches ...
               for qq=1:Q
                  % Derivative is sensitivity by net input function derivative.
                  gLWZ{i,j,k}(:,:,qq,ts)=kron(dz(:,qq),ones(1,layers{k}.size));
                  % Layer Weight function derivative
                  if dotprod_flag,  
                    temp = Ad{i,j,ts}(:,qq)';  
                  else   
                    temp = feval(LWF{i,j},'dw',LW{i,j},Ad{i,j,ts}(:,qq),LWZ{i,j,ts}(:,qq),layerWeightParam{i,j})';  
                  end   
                  % If a cell is returned we have a derivative for each batch.
                  if iscell(temp)
                     temp2=[];
                     for jj=1:size(gLWZ{i,j,k}(:,:,qq,ts),1)
                        temp3=[];
                        for ii=1:size(gLWZ{i,j,k}(:,:,qq,ts),2)
                           temp4=gLWZ{i,j,k}(jj,ii,qq,ts)*S{k,i}(ii,jj,qq,ts);
                           temp3=[temp3;[temp{jj}]'*temp4]; 
                        end
                        temp2=[temp2 temp3];
                     end
                     % General case for weight functions.
                  elseif class_WF==2 
                     temp3=gLWZ{i,j,k}(:,:,qq,ts)'.*S{k,i}(:,:,qq,ts);
                     temp2=temp3*temp';
                  else    % Regular case if returned value is a matrix.
                     temp3=gLWZ{i,j,k}(:,:,qq,ts)'.*S{k,i}(:,:,qq,ts);
                     temp2=kron(temp3,temp);
                  end
                  % Final derivative of layer output respect to layer Weight
                  gyLW{i,j,k,numLayerDelays+1,qq}=temp2;
               end
            end
         end
      end
   end
   % Loop to obtain derivative values.
   % We move over simulation order
   for jz=simLayerOrder
      % For all input layers where the sensitivity is different from zero.
      for jj=ESx{jz}
         % ... and are connected forward with delays.
         for xx=LCFWD{jj}
            % Extra check for existing sensitivities
            if size(S{jz,jj},2)~=0
               % We obtain the derivative of the layer weight function respect to the input.
               switch func2str(LWF{jj,xx})   
               case 'dotprod'   
                   gLWc = LW{jj,xx};   
               otherwise   
                   gLWc = feval(LWF{jj,xx},'dp',LW{jj,xx},[Ad{jj,xx,ts}],LWZ{jj,xx,ts},layerWeightParam{jj,xx});
               end   
               % We move over the simulation order.
               for i=simLayerOrder
                  % ... Bias
                  if biasConnect(i)
                     for qq=1:Q
                        % We use a temporary variable to load previous bias gradient based on time
                        temp=[];
                        for nx=1:size(input_delays{jj,xx},2) 
                           nd=input_delays{jj,xx}(nx);
                           temp=[temp gyB{i,xx,numLayerDelays+1-nd,qq}];
                        end
                        % We check if derivative of layer weight function respect to the input is a cell.
                        if iscell(gLWc)
                           gyB{i,jz,numLayerDelays+1,qq}=gyB{i,jz,numLayerDelays+1,qq} + ...
                               ((S{jz,jj}(:,:,qq,ts) .* gLWZ{jj,xx,jz}(:,:,qq,ts)')*gLWc{qq}*temp')';
                        else
                           gyB{i,jz,numLayerDelays+1,qq}=gyB{i,jz,numLayerDelays+1,qq} + ...
                               ((S{jz,jj}(:,:,qq,ts) .* gLWZ{jj,xx,jz}(:,:,qq,ts)')*gLWc*temp')';
                        end
                     end
                  end
                  % ... Input Weights
                  for j=ICF{i}
                     for qq=1:Q
                        % We use a temporary variable to load previous input Weight gradient based on time
                        temp=[];
                        for nx=1:size(input_delays{jj,xx},2)
                           nd=input_delays{jj,xx}(nx);
                           temp=[temp;gyIW{i,j,xx,numLayerDelays+1-nd,qq}];
                        end
                        % We check if derivative of layer weight function respect to the input is a cell.
                        if iscell(gLWc)
                           gyIW{i,j,jz,numLayerDelays+1,qq}=gyIW{i,j,jz,numLayerDelays+1,qq} + ...
                                (S{jz,jj}(:,:,qq,ts) .* gLWZ{jj,xx,jz}(:,:,qq,ts)')*gLWc{qq}*temp;
                        else
                           gyIW{i,j,jz,numLayerDelays+1,qq}=gyIW{i,j,jz,numLayerDelays+1,qq} + ...
                                (S{jz,jj}(:,:,qq,ts) .* gLWZ{jj,xx,jz}(:,:,qq,ts)')*gLWc*temp;
                        end
                     end
                  end
                  % ... Layer Weights
                  for j=LCF{i}
                     for qq=1:Q
                        % We use a temporary variable to load previous layer Weight gradient based on time
                        temp=[];
                        for nx=1:size(input_delays{jj,xx},2)
                           nd=input_delays{jj,xx}(nx);
                           temp=[temp;gyLW{i,j,xx,numLayerDelays+1-nd,qq}];
                        end
                        % We check if derivative of layer weight function respect to the input is a cell.
                        if size(temp,1)
                           if iscell(gLWc)
                              gyLW{i,j,jz,numLayerDelays+1,qq}=gyLW{i,j,jz,numLayerDelays+1,qq} + ...
                                   (S{jz,jj}(:,:,qq,ts) .* gLWZ{jj,xx,jz}(:,:,qq,ts)')*gLWc{qq}*temp;
                           else
                              gyLW{i,j,jz,numLayerDelays+1,qq}=gyLW{i,j,jz,numLayerDelays+1,qq} + ...
                                   (S{jz,jj}(:,:,qq,ts) .* gLWZ{jj,xx,jz}(:,:,qq,ts)')*gLWc*temp;
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
  
   % Final loop to evaluate gradients
   for jz=find(outputConnect)
      % We get error derivatives for specific target
      gEE=gE{jz,ts};
      % We follow backpropagation order
      for i=bpLayerOrder
         % ... for all batches
         for qq=1:Q
            % ... for all biases
            if biasConnect(i)
               % If it's time-batch based we save each gradient independently
               if time_base
                  for ss=1:SS
                    gB{i,(ts-1)*QS+(qq-1)*SS+ss}=gB{i,(ts-1)*QS+(qq-1)*SS+ss}+gyB{i,jz,numLayerDelays+1,qq}*gEE(:,(qq-1)*SS+ss);
                  end
               else  % Full gradient
                  gB{i}=gB{i}+gyB{i,jz,numLayerDelays+1,qq}*gEE(:,qq);
               end
            end
            % ... for all input Weights
            for j=ICF{i}
               % If it's time-batch based we save each gradient independently
               if time_base
                  for ss=1:SS
                     temp=gEE(:,(qq-1)*SS+ss)'*gyIW{i,j,jz,numLayerDelays+1,qq};
                     temp2=[];
                     for zzz=1:IWsize1(i,j)   
                        temp2=[temp2;temp((1:IWsize2(i,j))+(zzz-1)*IWsize2(i,j))]; 
                     end
                     gIW{i,j,(ts-1)*QS+(qq-1)*SS+ss}=gIW{i,j,(ts-1)*QS+(qq-1)*SS+ss}+temp2;
                  end
               else
                  temp=gEE(:,qq)'*gyIW{i,j,jz,numLayerDelays+1,qq};
                  temp2=[];
                  for zzz=1:IWsize1(i,j)   
                     temp2=[temp2;temp((1:IWsize2(i,j))+(zzz-1)*IWsize2(i,j))];  
                  end
                  gIW{i,j}=gIW{i,j}+temp2;
               end
            end
            % ... for all layer Weights
            for j=LCF{i}
               % We check derivative exist
               if size(gyLW{i,j,jz,numLayerDelays+1,qq})
                  % If it's time-batch based we save each gradient independently
                  if time_base
                     for ss=1:SS
                        temp=gEE(:,(qq-1)*SS+ss)'*gyLW{i,j,jz,numLayerDelays+1,qq};
                        temp2=[];
                        for zzz=1:LWsize1(i,j)  
                           temp2=[temp2;temp((1:LWsize2(i,j))+(zzz-1)*LWsize2(i,j))]; 
                        end
                        gLW{i,j,(ts-1)*QS+(qq-1)*SS+ss}=gLW{i,j,(ts-1)*QS+(qq-1)*SS+ss}+temp2;
                     end
                  else
                     temp=gEE(:,qq)'*gyLW{i,j,jz,numLayerDelays+1,qq};
                     temp2=[];
                     for zzz=1:LWsize1(i,j)   
                        temp2=[temp2;temp((1:LWsize2(i,j))+(zzz-1)*LWsize2(i,j))]; 
                     end
                     gLW{i,j}=gLW{i,j}+temp2;
                  end
               end
            end
         end
      end
   end
   
   % We shift the gradients of targets respect to weights and biases backwards in time
   for i=bpLayerOrder
      if numLayerDelays
         if biasConnect(i)
            [gyB{i,forw_redun_order,1:numLayerDelays,1:Q}]=deal(gyB{i,forw_redun_order,(1:numLayerDelays)+1,1:Q});
         end
         for j=ICF{i}
            [gyIW{i,j,forw_redun_order,1:numLayerDelays,1:Q}]=deal(gyIW{i,j,forw_redun_order,(1:numLayerDelays)+1,1:Q});
         end
         for j=LCF{i}
            [gyLW{i,j,forw_redun_order,1:numLayerDelays,1:Q}]=deal(gyLW{i,j,forw_redun_order,(1:numLayerDelays)+1,1:Q});
         end
      end
   end
 
end

% ===========================================================
function u = nnunion(u,i)

if ~any(u==i),
    u = [u i];
end
