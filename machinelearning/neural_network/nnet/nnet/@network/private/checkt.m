function [err,t] = checkt(net,t,Q,TS)
%CHECKT Check T dimensions.
%
%  Synopsis
%
%    [err,T] = checkp(net,T,Q,TS)
%
%  Warning!!
%
%    This function may be altered or removed in future
%    releases of the Neural Network Toolbox. We recommend
%    you do not write code dependant on this function.

%  Mark Beale, 11-31-97
%  Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.8.4.3 $

if any(size(t) == 0)
  t = cellmat(net.numOutputs,TS,net.hint.outputSizes,Q);
  err = '';
else
  err = cellmat_checksizes(t,net.numOutputs,TS,net.hint.outputSizes,Q);
  if ~isempty(err), err = ['T: ' err]; end
end
