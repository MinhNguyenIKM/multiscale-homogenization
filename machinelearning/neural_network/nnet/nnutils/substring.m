function str=substring(str,first,varargin)


% SUBSTRING Return part of a Java string.

% Copyright 1992-2004 The MathWorks, Inc.
% $Revision: 1.4.4.1 $  $Date: 2004/08/17 21:42:23 $


if isempty(varargin)
  str=str(first+1:end);
else
  str=str(first+1:varargin{1}+1);
end
