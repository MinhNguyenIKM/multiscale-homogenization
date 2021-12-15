function [err,ai] = checkai(net,ai,Q)
%CHECKAI Check Ai dimensions.
%
%  Synopsis
%
%    [err,Ai] = checkai(net,Ai,Q)
%
%  Warning!!
%
%    This function may be altered or removed in future
%    releases of the Neural Network Toolbox. We recommend
%    you do not write code dependant on this function.

%  Mark Beale, 11-31-97
%  Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.8.4.1 $

if isempty(ai)
  ai = cellmat(net.numLayers,net.numLayerDelays,net.hint.layerSizes,Q);
  err = '';
else
  err = cellmat_checksizes(ai,net.numLayers,net.numLayerDelays,net.hint.layerSizes,Q);
  if ~isempty(err), err = ['Pi: ' err]; end
end