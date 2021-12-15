function gE2=processperfoutputderiv(net,A,gE1,Q)
%PROCESSOUTPUTDERIV Applies a network's preprocessing settings to target values
%
% Syntax
%   
%   t2 = processoutputderiv(net,t1)
%
% Description
%
%   PROCESSOUTPUTDERIV(net,t1) takes a network and target values (either a
%   matrix or a cell array of matrices) and returns those values after
%   applying the network's preprocessing settings.
%
%   If T is a cell array, it may have as many rows as network targets,
%   or as many rows as network layers.

% Copyright 2007 The MathWorks, Inc.

if nargin < 4, error('NNET:Arguments','Not enough arguments.'); end

TS = size(A,2);
gE2 = cell(size(gE1));
for i=1:net.numLayers
  if ~net.outputConnect(i) || isempty(net.outputs{i}.processFcns)
    gE2(i,:) = gE1(i,:);
  else
    PF = net.outputs{i}.processFcns;
    PS = net.outputs{i}.processSettings;
    numPF = length(PF);
    for ts=1:TS
      AA = cell(1,numPF+1);
      AA{1} = A{i,ts};
      for j=1:numPF
        pf_index = numPF+1-j;
        AA{j+1} = feval(PF{pf_index},'reverse',AA{j},PS{pf_index});
      end
      ge1 = gE1{i,ts};
      for j=numPF:-1:1
        ge2 = zeros(PS{pf_index}.yrows,Q);
        pf_index = numPF+1-j;
        dpf = feval(PF{pf_index},'dx_dy',AA{j+1},AA{j},PS{pf_index});
        for q=1:Q
          ge2(:,q) = dpf(:,:,q)' * ge1(:,q);
        end
        ge1 = ge2;
      end
      gE2{i,ts} = ge1;
    end
  end
end
