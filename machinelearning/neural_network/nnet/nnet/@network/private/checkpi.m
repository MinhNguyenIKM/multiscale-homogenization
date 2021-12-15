function [err,pi] = checkpi(net,pi,Q)
%CHECKPI Check Pi dimensions.
%
%  Synopsis
%
%    [err,pi] = checkpi(net,Pi,Q)
%
%  Warning!!
%
%    This function may be altered or removed in future
%    releases of the Neural Network Toolbox. We recommend
%    you do not write code dependant on this function.

%  Mark Beale, 11-31-97
%  Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.8.4.1 $

if isempty(pi)
  pi = cellmat(net.numInputs,net.numInputDelays,net.hint.inputSizes,Q);
  err = '';
else
  err = cellmat_checksizes(pi,net.numInputs,net.numInputDelays,net.hint.inputSizes,Q);
  if ~isempty(err), err = ['Pi: ' err]; end
end
