% Testing gradient calculation for accuracy with numerical gradient

% Copyright 2007 The MathWorks, Inc.

[gXt] = calcjejj(net,trainV.Pd,Zb,Zi,Zl,N,Ac,El,Q,TS,mem_reduc);
[gX11] = approxGrad(net,trainV.Pd,Tl,trainV.Ai,Q,TS,1e-6);

c = iscell(El);
if c
  ee = cell2mat(El);
end
numElementsA = numel(ee);
flag_test = 1;
if isequal(net.performFcn,'msereg'),
  gXt = 2*gXt*net.performParam.ratio/numElementsA + 2*(1-net.performParam.ratio)*WB/length(WB);
elseif isequal(net.performFcn,'mse'),
  gXt = 2*gXt/numElementsA;
%elseif  isequal(net.performFcn,'mse'),
%  gXt = 2*gXt;
else
  flag_test = 0;
end
if flag_test,
  sseg = sumsqr(gXt-gX11);
  den_perc = max(abs(gX11));
  if den_perc~=0,
    gXperc = 100*abs((gXt-gX11))./den_perc;
  else
    den_perc2 = max(abs(gXt));
    if den_perc2~=0,
      gXperc = 100*abs((gXt-gX11))./den_perc2;
    else
      gXperc = zeros(size(gXt));
    end
  end

  rmseg = sqrt(sseg/length(gXperc));
  if(any(gXperc>1)&&(rmseg>1e-4))
    fprintf(['error in jacobian'  '\n'])
    zzz=clock;
    fname = cat(2,'jac_err',num2str(zzz(6)));
    fname = strrep(fname,'.','_');
    fprintf(['file name for saved data is ' fname '\n\n'])
    save(fname)
  end
end
