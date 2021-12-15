function [err,c] = formatt(net,m,Q,TS)
%FORMATT Format matrix T.
%
%  Synopsis
%
%    [err,T] = formatt(net,T,Q)
%
%  Warning!!
%
%    This function may be altered or removed in future
%    releases of the Neural Network Toolbox. We recommend
%    you do not write code dependant on this function.

%  Mark Beale, 11-31-97
%  Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.8.4.3 $

err = [];
c = [];

if isempty(m)
  % [] -> zeros
  c = cellmat(net.numOutputs,TS,net.hint.outputSizes,Q);
elseif (size(m,1) ~= net.hint.totalOutputSize)
  err = sprintf('Targets are incorrectly sized for network.\nMatrix must have %g rows.',net.hint.totalOutputSize);
elseif (size(m,2) ~= Q)
  err = sprintf('Targets are incorrectly sized for network.\nMatrix must have %g columns.',Q);
else
  % Cell -> Matrix
  c = mat2cell(m,net.hint.outputSizes);
end