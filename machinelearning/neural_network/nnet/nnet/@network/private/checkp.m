function [err] = checkp(net,p,Q,TS)
%CHECKP Check P dimensions.
%
%  Synopsis
%
%    [err] = checkp(net,P,Q,TS)
%
%  Warning!!
%
%    This function may be altered or removed in future
%    releases of the Neural Network Toolbox. We recommend
%    you do not write code dependant on this function.

%  Mark Beale, 11-31-97
%  Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.8.4.1 $

err = cellmat_checksizes(p,net.numInputs,TS,net.hint.inputSizes,Q);
if ~isempty(err), err = ['P: ' err]; end
