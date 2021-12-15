function helptext = nnetbhelp(fileStr,htmlfile)
% NNETBHELP Neural Network Blockset on-line help function.
%   Points Web browser to the HTML help file corresponding to this
%   Neural Network Blockset block.  The current block is queried
%   for its MaskType.
%
%   Typical usage:
%      set_param(gcb,'MaskHelp','web(nnetbhelp);');

%   $Revision: 1.2.4.8 $  $Date: 2008/10/31 06:25:10 $
% Copyright 1992-2007 The MathWorks, Inc.

d = docroot;

if isempty(d),
   % Help system not present:
   helpview([matlabroot,'/toolbox/local/helperr.html']);
elseif (nargin == 1)
   htitle = sprintf('Neural Network Toolbox: %s Block', fileStr);
   html = sprintf(['<html><head><title>%s</title>' ...
             '<base href=""></head><body><font size=+3 color="#990000">' ...
             'Neural Network Toolbox:  %s Block</font>' ...
             '<p>The %s block is a Simulink implementation of the ' ...
             '%s function.  See <a href="matlab:doc(''%s'')">%s</a> ' ...
             'for more information.</body>'], ...
                  htitle, fileStr, fileStr, fileStr, fileStr, fileStr);
   web(['text://' html], '-helpbrowser');
elseif (nargin == 2)
   helpview([d '/toolbox/nnet/' htmlfile]);
else
   error('NNET:nnetbhelp:Arguments','Block name not specified'); % should not happen
end
