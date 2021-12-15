function nntobsf(fcn,varargin)
%NNTOBSF Warn that a function is obsolete.
%
%  nntobsf(fcnName,line1,line2,...)
%  
%  *WARNING*: This function is undocumented as it may be altered
%  at any time in the future without warning.

% Mark Beale, 11-31-97
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.7.4.3 $

w = warning('query','NNET:Obsolete');
if ~strcmp(w.state,'on'), return, end

NNTWARNFLAG = nntwarn('query');
if isempty(NNTWARNFLAG)
  warning('NNET:Obsolete',[upper(fcn) ' is an obsolete function.'])
  for i=1:length(varargin)
    disp(['          ' varargin{i}])
  end
  disp(' ')
elseif strcmp(NNTWARNFLAG,'error')
  error('NNET:Obsolete',[upper(fcn) ' is an obsolete function.'])
end
