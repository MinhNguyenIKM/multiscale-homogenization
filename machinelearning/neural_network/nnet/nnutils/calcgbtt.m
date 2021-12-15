function [gB,gIW,gLW]=calcgbtt(net,Q,PD,BZ,IWZ,LWZ,N,Ac,gE,TS,time_base)
%CALCGBTT Calculate bias and weight performance gradients using the backpropagation through time algorithm.
%         
%
%	Synopsis
%
%	  [gB,gIW,gLW] = calcgbtt(net,Q,PD,BZ,IWZ,LWZ,N,Ac,gE,TS)
%
%	Warning!!
%
%	  This function may be altered or removed in future
%	  releases of the Neural Network Toolbox. We recommend
%	  you do not write code which calls this function.

% Orlando De Jesus, Matin Hagan, 7-20-05
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.8 $ $Date: 2008/10/31 06:25:09 $

% If last parameter missing we execute regular gradient
if nargin <11
  time_base=0;
end

% Shortcuts
numLayers=net.numLayers;
numInputs = net.numInputs;
biases=net.biases;
layerWeights=net.layerWeights;
inputWeights=net.inputWeights;
layers=net.layers;
bpLayerOrder=net.hint.bpLayerOrder;
numLayerDelays = net.numLayerDelays;
outputConnect=net.outputConnect;
biasConnect=net.biasConnect;
ICF = net.hint.inputConnectFrom;
LCF = net.hint.layerConnectFrom;
LCT = net.hint.layerConnectTo;
LCTOZD = net.hint.layerConnectToOZD;
IW = net.IW;
LW = net.LW;
layerDelays = net.hint.layerDelays;

% Functions and Parameters
TF = net.hint.transferFcn;
netInputFcn = net.hint.netInputFcn;
IWF = net.hint.inputWeightFcn;
LWF = net.hint.layerWeightFcn;
netInputParam = cell(numLayers,1);  
transferParam = cell(numLayers,1);  
inputWeightParam = cell(numLayers,numInputs);  
layerWeightParam = cell(numLayers,numLayers);  
for i=1:numLayers
  netInputParam{i} = net.layers{i}.netInputParam;
  transferParam{i} = net.layers{i}.transferParam;
  for j=ICF{i}
    inputWeightParam{i,j}=net.inputWeights{i,j}.weightParam;
  end
  for j=LCF{i}
    layerWeightParam{i,j}= net.layerWeights{i,j}.weightParam;
  end
end

LCTWD = cell(numLayers);
for i=1:numLayers
  LCTWD{i}=setxor(LCT{i},LCTOZD{i});
end

% We create a cell array to save the input being applied to each weight
Ad = cell(numLayers,numLayers,TS);
for i=1:numLayers
  for j = LCF{i}
    for ts = 1:TS
      Ad{i,j,ts} = cell2mat(Ac(j,ts+numLayerDelays-layerDelays{i,j})');
    end
  end
end

% Compress Time
Ae = cell(numLayers,1);
for i=1:numLayers
  Ae{i} = [Ac{i,(1+numLayerDelays):end}];
end

% Signals
gA = cell(numLayers,1);
gBZ = [];
gIWZ = cell(numLayers,numInputs);
gLWZ = cell(numLayers,numLayers);
geIW = cell(numLayers,numInputs,Q,TS);  
geLW = cell(numLayers,numLayers,Q,TS);  
SS = net.hint.totalOutputSize;
gTa = cell(numLayers,Q,TS+1+numLayerDelays,TS+1+numLayerDelays,SS);
QS=Q*SS;

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
S = cell(numLayers,numLayers);

Uprime = [];
% Cell array for layers connected to a targets
ES = cell(1,numLayers);

% We calculate explicit derivatives of output versus previous outputs.   
for i=bpLayerOrder

  for u=Uprime
    % We calculate the derivative of the transfer function
    S_temp = calcfdot(i,TF,transferParam,1:TS,Q,Ae,numLayerDelays,N,1,net.layers{i}.size);
    
    % ...through Layer Weights with only zero delays
    for k=LCTOZD{i}
      if size(S{u,k},1)>0
        % We initialize new S if needed.
        if size(S{u,i},1)==0
          S{u,i} = zeros(layers{u}.size,layers{i}.size,Q,TS);
        end
        % We calculate derivative for the matrix to input operation
        switch func2str(LWF{k,i})
        case 'dotprod'   % Default dotproduct operation
          for qq=1:Q
            for ts=1:TS
              S{u,i}(:,:,qq,ts) = S{u,i}(:,:,qq,ts) + ...
                                   ((gLWZ{k,i,u}(:,:,qq,ts)'.*S{u,k}(:,:,qq,ts)) * LW{k,i} * S_temp(:,:,qq,ts));
            end
          end
	    otherwise        % Other Operations
          for ts=1:TS
            for qq=1:Q
              % For each sequence we calculate the matric to input derivative
              dp = feval(LWF{k,i},'dp',LW{k,i},Ae{i}(:,(ts-1)*Q+qq),LWZ{k,i,ts}(:,qq),layerWeightParam{k,i}); 
              % Some derivative functions may return a cell array
              if iscell(dp)
                S{u,i}(:,:,qq,ts) = S{u,i}(:,:,qq,ts) + ((gLWZ{k,i,u}(:,:,qq,ts)'.*S{u,k}(:,:,qq,ts)) * dp{1} * S_temp(:,:,qq,ts));
              else
                S{u,i}(:,:,qq,ts) = S{u,i}(:,:,qq,ts) + ((gLWZ{k,i,u}(:,:,qq,ts)'.*S{u,k}(:,:,qq,ts)) * dp * S_temp(:,:,qq,ts));
              end
            end
          end
        end
        % We initialize sensitivities over sequence total time with zero
        for ts=TS+1:TS+1+numLayerDelays
          S{u,i}(:,:,qq,ts) = zeros(layers{u}.size,layers{i}.size);
        end
      end
    end
  end
  
  % If we are connected to target or actual layer is connected to a delay, we initialize sensitivities.
  if outputConnect(i) || size(LCTWD{i},1)~=0
    S{i,i} = calcfdot(i,TF,transferParam,1:TS,Q,Ae,numLayerDelays,N,1,net.layers{i}.size);
    % We save layers used as targets.
    Uprime = [Uprime i];
    % Layer connectd to a target
    ES{i}=[ES{i} i];
  end
  
  % ...to Bias
  if biasConnect(i)
    for ts=1:TS
      Z = [BZ(i) IWZ(i,ICF{i},ts) LWZ(i,LCF{i},ts)];
      switch func2str(netInputFcn{i})  
      case 'netsum'  
        dz = ones(size(N{i,ts}));  
      otherwise  
        dz = feval(netInputFcn{i},'dz',1,Z,N{i,ts},netInputParam{i});  
      end  
      for qq=1:Q
        % We save derivatives with respect to the targets
        for k=Uprime
          gBZ{i,k}(:,:,qq,ts) = dz(:,qq+zeros(1,layers{k}.size));
        end
      end
    end
    % We initialize bias gradient with zero
    if time_base
      [gB{i,1:TS*QS}]=deal(zeros(biases{i}.size,1));
    else
      gB{i} = zeros(biases{i}.size,1);
    end
  end
  
  % ...to Input Weights
  jjj = 0; 
  for j=ICF{i}
   jjj = jjj +1; 
    for ts=1:TS
      % We calculate for all sequences
      Z = [IWZ(i,ICF{i},ts) LWZ(i,LCF{i},ts) BZ(i,biasConnect(i))];
      switch func2str(netInputFcn{i})  
      case 'netsum'  
        dz = ones(size(N{i,ts}));  
      otherwise  
        dz = feval(netInputFcn{i},'dz',jjj,Z,N{i,ts},netInputParam{i});  
      end  
      % We save derivatives respect to the targets
      for k=Uprime
        layerSize = layers{k}.size;
        for qq=1:Q
          gIWZ{i,j,k}(:,:,qq,ts) = dz(:,qq+zeros(1,layerSize));
        end
      end
      
      % We calculate explicit input derivaties
      dotprod_flag = strcmp(func2str(IWF{i,j}),'dotprod');  
      for qq=1:Q
        if dotprod_flag,  
          geIW{i,j,qq,ts} = PD{i,j,ts}(:,qq)';  
        else  
          geIW{i,j,qq,ts} = feval(IWF{i,j},'dw',IW{i,j},PD{i,j,ts}(:,qq),IWZ{i,j,ts}(:,qq),inputWeightParam{i,j})';  
        end  
      end
    end
    % We fill extra numbers with zero.
    for ts=TS+1:TS+1+numLayerDelays
      for qq=1:Q
        for k=Uprime
          gIWZ{i,j,k}(:,:,qq,ts) = zeros(size(gIWZ{i,j,k}(:,:,1,1)));
        end
      end
    end
    % We save information about the subnet where the input weight is located.
    if time_base
      [gIW{i,j,1:TS*QS}]=deal(zeros(inputWeights{i,j}.size));
    else
      gIW{i,j} = zeros(inputWeights{i,j}.size);
    end
  end
  
  % ...to Layer Weights
  jjj = 0; 
  for j=LCF{i}
    jjj = jjj +1; 
    for ts=1:TS
      % We calculate the derivative respect to the internal network operation (netsum or netprod)
      % We calcuate for all sequences
      Z = [LWZ(i,LCF{i},ts) IWZ(i,ICF{i},ts) BZ(i,biasConnect(i))];

      switch func2str(netInputFcn{i})  
      case 'netsum'  
        dz = ones(size(N{i,ts}));  
      otherwise  
        dz = feval(netInputFcn{i},'dz',jjj,Z,N{i,ts},netInputParam{i}); 
      end  

      for qq=1:Q
        % We calculate the derivative respect to the internal network operation (netsum or other)
        % We save derivatives respect to the targets
        for k=Uprime
          gLWZ{i,j,k}(:,:,qq,ts) = dz(:,qq+zeros(1,layers{k}.size));
        end
      end
      
      % We calculate explicit weight derivaties
      dotprod_flag = strcmp(func2str(LWF{i,j}),'dotprod');  
      for qq=1:Q
        if dotprod_flag,  
          geLW{i,j,qq,ts} = Ad{i,j,ts}(:,qq)';  
        else  
          geLW{i,j,qq,ts} = feval(LWF{i,j},'dw',LW{i,j},Ad{i,j,ts}(:,qq),LWZ{i,j,ts}(:,qq),layerWeightParam{i,j})';  
        end  
      end
    end
    % We fill derivatives over sequence time with zero.
    for ts=TS+1:TS+1+numLayerDelays
      for qq=1:Q
        for k=Uprime
          gLWZ{i,j,k}(:,:,qq,ts) = zeros(size(gLWZ{i,j,k}(:,:,1,1)));
        end
      end
    end
    % We initialize weight gradient with zero
    if time_base
      [gLW{i,j,1:TS*QS}]=deal(zeros(layerWeights{i,j}.size));
    else
      gLW{i,j}=zeros(layerWeights{i,j}.size);
    end
  end
end

if time_base
  for jz=fliplr(Uprime)
    % We initialize final gradient over sequence time with zeros.
    zzeros = zeros(layers{jz}.size,1);
    for qq=1:Q,
      for tt1=1:TS+1+numLayerDelays,
        for tt2=1:TS+1+numLayerDelays,
          for ss=1:SS,
            gTa{jz,qq,tt1,tt2,ss}=zzeros;
          end
        end
      end
    end
     
    % We initialize explicit derivative of cost function respect to targets
    if outputConnect(jz) 
      for ts=1:TS
        for qq=1:Q
          for ss=1:SS
            % We only initialize the last time for each subsequence.
            gTa{jz,qq,ts,ts,ss}=gE{jz,ts}(:,(qq-1)*SS+ss);  
          end
        end
      end
    end
  end
else  % Full Gradient
  for jz=fliplr(Uprime)
    % We initialize final gradient over sequence time with zeros.
    [gTa{jz,1:Q,1:TS+1+numLayerDelays}]=deal(zeros(layers{jz}.size,1));
    % We initialize explicit derivative of cost function respect to targets
    if outputConnect(jz) 
      for ts=1:TS
        for qq=1:Q
          gTa{jz,qq,ts}=gE{jz,ts}(:,qq);   
        end
      end
    end
  end
end


% We calculate Final Backpropagation Through Time derivatives.
% We go from final time to initial time
for ts=TS:-1:1
  if time_base
    for ss=1:SS
      for ts2=ts:-1:1
        for jj=Uprime
          for qq=1:Q
            for xx=LCTWD{jj}
              dotprod_flag = strcmp(func2str(LWF{xx,jj}),'dotprod');  
              for u2=Uprime
                if size([gTa{ES{u2},qq,ts,ts,ss}],2)~=0 && size(S{ES{u2},xx},2)~=0
                  if dotprod_flag, 
                    gLWc = LW{xx,jj}; 
                  else 
                    gLWc = feval(LWF{xx,jj},'dp',LW{xx,jj},[Ad{xx,jj,:}],[LWZ{xx,jj,:}],layerWeightParam{xx,jj});
                  end 
                  for k1=1:size(layerWeights{xx,jj}.delays,2)
                    k2=layerWeights{xx,jj}.delays(k1);
                    if iscell(gLWc)
                      if (ts2+k2)<=TS
                        gTa{jj,qq,ts,ts2,ss}=gTa{jj,qq,ts,ts2,ss} ...
                          +gLWc{(ts2-1)*Q+qq+k2*Q}(:,1+(k1-1)*layers{jj}.size:k1*layers{jj}.size)' ...
                          *(gLWZ{xx,jj,ES{u2}}(:,:,qq,ts2+k2) ...
                          .*S{ES{u2},xx}(:,:,qq,ts2+k2)')*[gTa{ES{u2},qq,ts,ts2+k2,ss}];
                      end
                    else
                      gTa{jj,qq,ts,ts2,ss}=gTa{jj,qq,ts,ts2,ss} ...
                        +gLWc(:,1+(k1-1)*layers{jj}.size:k1*layers{jj}.size)' ...
                        *(gLWZ{xx,jj,ES{u2}}(:,:,qq,ts2+k2) ...
                        .*S{ES{u2},xx}(:,:,qq,ts2+k2)')*[gTa{ES{u2},qq,ts,ts2+k2,ss}];
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  else  % Full Gradient 
    for jj=Uprime
      for qq=1:Q
        for xx=LCTWD{jj}
          dotprod_flag = strcmp(func2str(LWF{xx,jj}),'dotprod');  
          for u2=Uprime
            if size([gTa{ES{u2},qq,ts}],2)~=0 && size(S{ES{u2},xx},2)~=0
              if dotprod_flag, 
                gLWc = LW{xx,jj}; 
              else 
                gLWc = feval(LWF{xx,jj},'dp',LW{xx,jj},[Ad{xx,jj,:}],[LWZ{xx,jj,:}],layerWeightParam{xx,jj});
              end 
              for k1=1:size(layerWeights{xx,jj}.delays,2)
                k2=layerWeights{xx,jj}.delays(k1);
                if iscell(gLWc)
                  if (ts+k2)<=TS
                    gTa{jj,qq,ts}=gTa{jj,qq,ts} ...
                      +gLWc{(ts-1)*Q+qq+k2*Q}(:,1+(k1-1)*layers{jj}.size:k1*layers{jj}.size)' ...
                      *(gLWZ{xx,jj,ES{u2}}(:,:,qq,ts+k2) ...
                      .*S{ES{u2},xx}(:,:,qq,ts+k2)')*[gTa{ES{u2},qq,ts+k2}];
                  end
                else
                  gTa{jj,qq,ts}=gTa{jj,qq,ts} ...
                    +gLWc(:,1+(k1-1)*layers{jj}.size:k1*layers{jj}.size)' ...
                    *(gLWZ{xx,jj,ES{u2}}(:,:,qq,ts+k2) ...
                    .*S{ES{u2},xx}(:,:,qq,ts+k2)')*[gTa{ES{u2},qq,ts+k2}];
                end
              end
            end
          end
        end
      end
    end
  end
  for i=bpLayerOrder
    for u2=Uprime
      if size([gTa{ES{u2},qq,ts}],2)~=0 && size(S{ES{u2},i},2)~=0
        % ...from Performance
        % ...to Bias
        if biasConnect(i)
          for qq=1:Q
            if time_base
              for ss=1:SS
                for ts2=ts:-1:1
                  gB{i,(ts-1)*QS+(qq-1)*SS+ss}=gB{i,(ts-1)*QS+(qq-1)*SS+ss} + ...
                    (gBZ{i,ES{u2}}(:,:,qq,ts2).*S{ES{u2},i}(:,:,qq,ts2)')*gTa{ES{u2},qq,ts,ts2,ss}; 
                end
              end
            else  % Full gradient
              gB{i}=gB{i}+(gBZ{i,ES{u2}}(:,:,qq,ts).*S{ES{u2},i}(:,:,qq,ts)')*gTa{ES{u2},qq,ts}; 
            end
          end
        end
        
        % ...to Input Weights
        for j=ICF{i}
          class_WF = feval(IWF{i,j},'wfullderiv');
          for qq=1:Q
            if iscell(geIW{i,j,qq,ts})
              if time_base
                for ss=1:SS
                  for ts2=ts:-1:1
                    temp=[];
                    for k=1:layers{i}.size   
                      temp=[temp; (gIWZ{i,j,ES{u2}}(k,:,qq,ts2).*S{ES{u2},i}(:,k,qq,ts2)') * ...
                          gTa{ES{u2},qq,ts,ts2,ss}*geIW{i,j,qq,ts2}{k}'];  
                    end
                    gIW{i,j,(ts-1)*QS+(qq-1)*SS+ss}=gIW{i,j,(ts-1)*QS+(qq-1)*SS+ss}+temp;
                  end
                end
              else
                temp=[];
                for k=1:layers{i}.size  
                  temp=[temp; (gIWZ{i,j,ES{u2}}(k,:,qq,ts).*S{ES{u2},i}(:,k,qq,ts)') * ...
                      gTa{ES{u2},qq,ts}*geIW{i,j,qq,ts}{k}']; 
                end
                gIW{i,j}=gIW{i,j}+temp;
              end
            elseif class_WF==2 
              if time_base
                for ss=1:SS
                  for ts2=ts:-1:1
                    gIW{i,j,(ts-1)*QS+(qq-1)*SS+ss}=gIW{i,j,(ts-1)*QS+(qq-1)*SS+ss} + ...
                      geIW{i,j,qq,ts2} * (gIWZ{i,j,ES{u2}}(:,:,qq,ts2).*S{ES{u2},i}(:,:,qq,ts2)')*gTa{ES{u2},qq,ts,ts2,ss};
                  end
                end
              else
                gIW{i,j}=gIW{i,j}+geIW{i,j,qq,ts} * ...
                  (gIWZ{i,j,ES{u2}}(:,:,qq,ts).*S{ES{u2},i}(:,:,qq,ts)')*gTa{ES{u2},qq,ts};
              end
            else
              if time_base
                for ss=1:SS
                  for ts2=ts:-1:1
                    gIW{i,j,(ts-1)*QS+(qq-1)*SS+ss}=gIW{i,j,(ts-1)*QS+(qq-1)*SS+ss} + ...
                      (gIWZ{i,j,ES{u2}}(:,:,qq,ts2).*S{ES{u2},i}(:,:,qq,ts2)') * gTa{ES{u2},qq,ts,ts2,ss}*geIW{i,j,qq,ts2};
                  end
                end
              else
                gIW{i,j}=gIW{i,j}+(gIWZ{i,j,ES{u2}}(:,:,qq,ts).*S{ES{u2},i}(:,:,qq,ts)') * ...
                  gTa{ES{u2},qq,ts}*geIW{i,j,qq,ts};
              end
            end
          end
        end
        
        % ...to Layer Weights
        for j=LCF{i}
          class_WF = feval(LWF{i,j},'wfullderiv');
          for qq=1:Q
            if iscell(geLW{i,j,qq,ts})
              if time_base
                for ss=1:SS
                  for ts2=ts:-1:1
                    temp=[];
                    for k=1:layers{i}.size  
                      temp=[temp; (gLWZ{i,j,ES{u2}}(k,:,qq,ts2).*S{ES{u2},i}(:,k,qq,ts2)')* ...
                          gTa{ES{u2},qq,ts,ts2,ss}*geLW{i,j,qq,ts2}{k}'];  
                    end
                    gLW{i,j,(ts-1)*QS+(qq-1)*SS+ss}=gLW{i,j,(ts-1)*QS+(qq-1)*SS+ss}+temp; 
                  end
                end
              else
                temp=[];
                for k=1:net.layers{i}.size      
                  temp=[temp; (gLWZ{i,j,ES{u2}}(k,:,qq,ts).*S{ES{u2},i}(:,k,qq,ts)')* ...
                      gTa{ES{u2},qq,ts}*geLW{i,j,qq,ts}{k}'];   
                end
                gLW{i,j}=gLW{i,j}+temp; 
              end
            elseif class_WF==2
              if time_base
                for ss=1:SS
                  for ts2=ts:-1:1
                    gLW{i,j,(ts-1)*QS+(qq-1)*SS+ss}=gLW{i,j,(ts-1)*QS+(qq-1)*SS+ss} + ...
                      geLW{i,j,qq,ts2}*(gLWZ{i,j,ES{u2}}(:,:,qq,ts2).*S{ES{u2},i}(:,:,qq,ts2)')*gTa{ES{u2},qq,ts,ts2,ss};
                  end
                end
              else
                gLW{i,j}=gLW{i,j} +  geLW{i,j,qq,ts}*(gLWZ{i,j,ES{u2}}(:,:,qq,ts).*S{ES{u2},i}(:,:,qq,ts)')*gTa{ES{u2},qq,ts};
              end
            else
              if time_base
                for ss=1:SS
                  for ts2=ts:-1:1
                    gLW{i,j,(ts-1)*QS+(qq-1)*SS+ss}=gLW{i,j,(ts-1)*QS+(qq-1)*SS+ss} + ...
                      (gLWZ{i,j,ES{u2}}(:,:,qq,ts2).*S{ES{u2},i}(:,:,qq,ts2)')*gTa{ES{u2},qq,ts,ts2,ss}*geLW{i,j,qq,ts2}; 
                  end
                end
              else
                gLW{i,j}=gLW{i,j} +  (gLWZ{i,j,ES{u2}}(:,:,qq,ts).*S{ES{u2},i}(:,:,qq,ts)')*gTa{ES{u2},qq,ts}*geLW{i,j,qq,ts}; 
              end
            end
          end
        end   
      end
    end
  end
end


