function gX2=processperfinputderiv(net,x,gX1,Q)
%PROCESSPERFINPUTDERIV

% Copyright 2007 The MathWorks, Inc.

if nargin < 4, error('NNET:Arguments','Not enough arguments.'); end

TS = size(x,2);
d = processinputderiv(net,x);
gX2 = cell(size(gX1));
for i=1:net.numInputs
  % Multiply gradient by process derivatives
  for ts=1:TS
    gx1 = gX1{i,ts};
    dits = d{i,ts};
    gx2 = zeros(net.inputs{i}.size,Q);
    for q=1:Q
      gx2(:,q) = dits(:,:,q)'*gx1(:,q);
    end
    gX2{i,ts} = gx2;
  end
end
