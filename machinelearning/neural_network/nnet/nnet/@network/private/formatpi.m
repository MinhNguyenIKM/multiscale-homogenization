function [err,c] = formatpi(net,m,Q)
%FORMATPI Format matrix Pi.
%
%  Synopsis
%
%    [err,Pi] = formatpi(net,Pi,Q)
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

if isempty(m)
  % [] -> zeros
  c = cellmat(net.numInputs,net.numInputDelays,net.hint.inputSizes,Q);
elseif (size(m,1) ~= net.hint.totalInputSize)
  err = sprintf('Input states are incorrectly sized for network.\nMatrix must have %g rows.',net.hint.totalInputSize);
elseif (size(m,2) ~= Q*net.numInputDelays)
  err = sprintf('Input states are incorrectly sized for network.\nMatrix must have %g columns.',Q*net.numInputDelays);
else
  % Cell -> Matrix
  c = mat2cell(m,net.hint.inputSizes,zeros(1,net.numInputDelays)+Q);
end