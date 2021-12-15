function m=processforward(processFcns,processSettings,m)
%PROCESSFORWARD Applies processing functions and settings to a matrix.
%
% Syntax
%   
%   m2 = processforward(processFcns,processSettings,m1)
%
% Description
%
%   PROCESSFORWARD(processFcns,processParams,d1) takes:
%     processFcns - row cell array of N processing function names
%     processParams - row cell array of N associated processing settings
%     d1 - matrix or cell array of matrices to be processed
%   and returns the processed matrix (or matrices) m2.

% Copyright 2007 The MathWorks, Inc.

if isnumeric(m)
  m = processMatrix(processFcns,processSettings,m);
else
  m = processCell(processFcns,processSettings,m);
end

%================================================
function m=processMatrix(processFcns,processSettings,m)

for i=1:length(processFcns)
  m = feval(processFcns{i},'apply',m,processSettings{i});
end

%================================================
function m=processCell(processFcns,processSettings,m)

[rows,cols] = size(m);
for i=1:rows
  for j=1:cols
    m{i,j} = processMatrix(processFcns,processSettings,m{i,j});
  end
end
