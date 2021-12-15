function m=processdx(processFcns,processSettings,m)
%PROCESSDX Applies processing functions and settings to a matrix.
%
% Syntax
%   
%   d = processdx(processFcns,processSettings,m)
%
% Description
%
%   PROCESSDX(processFcns,processParams,m1) takes:
%     processFcns - row cell array of N processing function names
%     processParams - row cell array of N associated processing settings
%     m - unprocessed NxQ matrix.
%   and returns the MxNxQ derivative of MxQ processed m with
%   respect to the NxQ unprocessed m.

% Copyright 2007 The MathWorks, Inc.

if isnumeric(m)
  m = processMatrix(processFcns,processSettings,m);
else
  m = processCell(processFcns,processSettings,m);
end

%================================================
function d1=processMatrix(processFcns,processSettings,m)

[M,Q] = size(m);
d1 = eye(M);
d1 = d1(:,:,ones(1,Q));
m1 = m;

for i=length(processFcns):-1:1
  pf = processFcns{i};
  ps = processSettings{i};
  m2 = feval(pf,'reverse',m,ps);
  di = feval(pf,'dx',m2,m1,ps);
  
  N = size(m2,1);
  d2 = zeros(M,N,Q);
  for q=1:Q
    d2(:,:,q) = d1(:,:,q) * di(:,:,q);
  end
  
  m1 = m2; d1 = d2;
end

%================================================
function m=processCell(processFcns,processSettings,m)

[rows,cols] = size(m);
for i=1:rows
  for j=1:cols
    m{i,j} = processMatrix(processFcns,processSettings,m{i,j});
  end
end
