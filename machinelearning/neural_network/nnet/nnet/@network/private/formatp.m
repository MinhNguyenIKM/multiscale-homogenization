function [err,c] = formatp(net,m,Q)
%FORMATP Format matrix  P.
%
%  Synopsis
%
%    [err,P] = formatp(net,P,Q)
%
%  Warning!!
%
%    This function may be altered or removed in future
%    releases of the Neural Network Toolbox. We recommend
%    you do not write code dependant on this function.

%  Mark Beale, 11-31-97
%  Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.8.4.1 $

err = [];
c = [];

% Check number of rows
if (size(m,1) ~= net.hint.totalInputSize)
  err = sprintf('Inputs are incorrectly sized for network.\nMatrix must have %g rows.',net.hint.totalInputSize);
elseif (size(m,2) ~= Q)
  err = sprintf('Inputs are incorrectly sized.\nMatrix must have %g columns.',Q);
else
  % Cell -> Matrix
  c = mat2cell(m,net.hint.inputSizes);
end
