function S = calcfdot(i,TF,transferParam,TS,Q,Ae,numLayerDelays,N,extrazeros,layerSize)
%CALCFDOT Calculate derivatives of transfer functions for use in dynamic gradient functions.
%
%	Synopsis
%
%	  [S] = calcfdot(i,TF,transferParam,TS,Q,Ae,numLayerDelays,N,extrazeros,layerSize)
%
%	Warning!!
%
%	  This function may be altered or removed in future
%	  releases of the Neural Network Toolbox. We recommend
%	  you do not write code which calls this function.

% Copyright 2005 The MathWorks, Inc.


TFi = TF{i};  
Aei = Ae{i};  
tP = transferParam{i}; 
Ni = N(i,:);  
fullderiv = feval(TFi,'fullderiv');
for ts=TS
  ts1Q = (ts-1)*Q; 
  Nit = Ni{ts};  
  OneNit = ones(size(Nit));
  Aeit = Aei(:,ts1Q+(1:Q)); 
  switch func2str(TFi)  
  case 'purelin' 
    AderivN = OneNit;  
  case 'tansig'  
    AderivN = (1-(Aeit.*Aeit));  
  case 'logsig'  
    AderivN = Aeit.*(1-Aeit);  
  otherwise  
    AderivN = feval(TFi,'dn',Nit,Aeit,tP);  
  end
  for qq=1:Q
    if fullderiv
        S(:,:,qq,ts) = AderivN{qq};
    else
        S(:,:,qq,ts) = diag(AderivN(:,qq));
    end
  end
end

if extrazeros
  for ts=(max(TS)+1+(0:numLayerDelays))
    S(:,:,:,ts) = zeros(layerSize,layerSize,Q);
  end
end
