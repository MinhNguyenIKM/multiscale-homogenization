%BOILER_NET Boilerplate script for net input functions.

% Copyright 2005-2007 The MathWorks, Inc.

if nargin < 1,error('NNET:Arguments','Not enough input arguments.'); end
in1 = varargin{1};
num = length(varargin);

% NNT4 SUPPORT
if ~(ischar(in1) || iscell(in1))
  if isa(varargin{end},'struct')
    in1 = varargin(1:(end-1));
    varargin = { in1, varargin{end} };
    num = 2;
  else
    in1 = varargin;
    varargin = { in1 };
    num = 1;
  end
elseif ischar(in1)
  if strcmp(in1,'deriv')
    out1 = ['d' fn];
    nntobsu(fn,['Use ' upper(fn) ' to calculate transfer function derivatives.'], ...
      'Net input functions now calculate their own derivatives.')
    return
  end
end

% CURRENT FUNCTIONALITY
if ischar(in1)
  switch in1
  case 'name'
    out1 = name;
  case 'type'
    out1 = 'net_input_function';
  case 'fpnames'
     if (num > 1), error('NNET:Arguments','Too many input arguments for action ''fpnames''.'), end
    out1 = param_names;
  case 'fpdefaults'
    if (num > 1), error('NNET:Arguments','Too many input arguments for action ''fpdefaults''.'), end
    out1 = param_defaults;
  case 'fpcheck'
    if (num > 2), error('NNET:Arguments','Too many input arguments for action ''fpcheck''.'), end
    err = param_check(varargin{2});
    if (nargout > 0)
      out1 = err;
    elseif ~isempty(err)
      error('NNET:Arguments',err);
    end
  case 'dz',
    if (num > 5), error('NNET:Arguments','Too many input arguments for action ''dz''.'), end
    if (num < 3), error('NNET:Arguments','Not enough input arguments for action ''dz''.'), end
    if (num < 5) || isempty(varargin{5}), varargin{5} = param_defaults; elseif isa(varargin{5},'cell'), varargin{5}=nnt_fpc2s(varargin{5},param_defaults); end
    if (num < 4), varargin{4} = apply(varargin{[3,5]}); end
    out1 = derivative_dn_dzj(varargin{2:end});
  otherwise, error('NNET:Arguments',['Unrecognized code: ''' in1 ''''])
  end
  return
end
if (num > 2), error('NNET:Arguments','Too many input arguments'), end
if (num < 2), varargin{2} = param_defaults; elseif isa(varargin{2},'cell'), varargin{2}=nnt_fpc2s(varargin{2},param_defaults);end
out1 = apply(varargin{1:2});
