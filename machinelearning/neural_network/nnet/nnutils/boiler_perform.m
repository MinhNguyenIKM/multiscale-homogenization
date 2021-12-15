% BOILER_PERFORM Boilerplate code for performance functions.

% Copyright 2005-2008 The MathWorks, Inc.

if nargin < 1,error('NNET:Arguments','Not enough input arguments.'); end
in1 = varargin{1};
num = length(varargin);

% NNT4 SUPPORT
if ischar(in1) && strcmp(in1,'deriv')
  out1 = ['d' fn];
  nntobsu(fn,['Use ' upper(fn) ' to calculate transfer function derivatives.'], ...
    'Performance functions now calculate their own derivatives.')
  return
elseif (num == 2) && (isa(varargin{2},'struct') ) 
  varargin = {varargin{1} 0 getx(network(varargin{2})) 0};
elseif (num == 2) && (isa(varargin{2},'network'))
  nntobsu(fn,['Use ' upper(fn) ' to calculate transfer function derivatives.'], ...
    'Performance functions now take Y.')
  varargin = {varargin{1} 0 getx(varargin{2}) 0};
elseif (num == 3) && (isa(varargin{2},'struct') || isempty(varargin{3})) 
  nntobsu(fn,['Use ' upper(fn) ' to calculate transfer function derivatives.'], ...
    'Performance functions now take Y.')
  varargin = {varargin{1} 0 getX(network(varargin{2})) varargin{3}}; 
elseif (num == 3) && (isa(varargin{3},'struct') ) 
  nntobsu(fn,['Use ' upper(fn) ' to calculate transfer function derivatives.'], ...
    'Performance functions now take Y.')
  varargin = {varargin{1} 0 varargin{2} varargin{3}}; 
end

% CURRENT FUNCTIONALITY
if ischar(in1)
  switch lower(in1)
    case 'info'
      try
        out1 = function_info;
      catch me
        info.name = fn;
        info.title = name;
        info.type = 'Performance';
        info.version = 5.1;
        out1 = info;
      end
    case 'name',
      out1 = name;
    case 'pnames',
      out1 = param_names;
    case 'pdefaults',
      out1 = param_defaults;
    case 'dy',
      if (num<2), error('NNET:Arguments','Not enough input arguments for action ''dx''.'), end
      e = varargin{2};
      c = iscell(e);
      if c
        [rows,cols] = size(e);
        dim1_flag = numel(e)==1; 
        if dim1_flag, 
          e = e{1};
        else 
          colSizes = zeros(1,cols); for i=1:cols,colSizes(i) = size(e{1,i},2); end
          rowSizes = zeros(1,rows); for i=1:rows,rowSizes(i) = size(e{i,1},1); end
          e = cell2mat(e);
        end 
      elseif ~isa(e,'double')
        error('NNET:Arguments','Error E must be a double matrix or a cell array of matrices.'),
      end
      if (num<3)
        y = zeros(size(varargin{2}));
      else
        y = varargin{3};
        if isa(y,'cell') && c, 
          if numel(y)==1, y=y{1,1}; else  y=cell2mat(y); end 
        elseif ~isa(y,'double'), 
          error('NNET:Arguments','Y must be same format as E.'),
        end
      end
      if (num<4)
        x = [];
      else
        x = varargin{4};
        if strcmp(fn,'msne')
          if (~isa(x,'network')) && (~isa(x,'struct')),error('NNET:Arguments','Network argument expected'); end
        else
          if isa(x,'network') || isa(x,'struct'), x = getx(x); end
        end
      end
      if (num<5), perf=performance(e,y,x,param_defaults); else perf=varargin{5}; end
      if (num<6), fp=param_defaults; else fp=varargin{6}; end
      out1 = derivative_dperf_dy(e,y,x,perf,fp);
      if c
        if dim1_flag, 
          out1 = {out1}; 
        else 
          out1 = mat2cell(out1,rowSizes,colSizes);
        end 
      end
    case 'dx',
      e = varargin{2};
      c = iscell(e);
      if c
        if numel(e)==1, e=e{1}; else e=cell2mat(e); end
      elseif ~isa(e,'double')
        error('NNET:Arguments','Error E must be a double matrix or a cell array of matrices.')
      end
      if (num<3)
        y = zeros(size(varargin{2}));
      else
        y = varargin{3};
        if isa(y,'cell') && c
          if numel(y)==1, y=y{1}; else y=cell2mat(y); end
        elseif ~isa(y,'double')
          error('NNET:Arguments','Y must be same format as E.')
        end
      end
      if (num<4)
        x = [];
      else
        x = varargin{4};
        if strcmp(fn,'msne')
          if (~isa(x,'network')) && (~isa(x,'struct')),error('NNET:Arguments','Network argument expected'); end
        else
         if isa(x,'network') || isa(x,'struct'), x = getx(x); end
        end
      end
      if (num<5), perf =performance(e,y,x,param_defaults); else perf = varargin{5}; end
      if (num<6), fp = param_defaults; else fp = varargin{6}; end
      out1 = derivative_dperf_dx(e,y,x,perf,fp);
   otherwise,
      error('NNET:Arguments','Unrecognized code: '' in1 ''.')
  end
  return
end
e = in1;
c = iscell(e);
if c
  if numel(e)==1, e=e{1}; else e=cell2mat(e); end 
elseif ~isa(in1,'double')
  error('NNET:Arguments','E must be a matrix or a row cell array.')
end
if (num<2)
  y = zeros(size(e));
else
  y = varargin{2};
  if isa(y,'cell') && c,
    if numel(y)==1, y=y{1}; else y=cell2mat(y); end
  elseif ~isa(y,'double'), 
      error('NNET:Arguments','Y must be same format as E.'), 
  end
end
if (num<3)
  x = [];
else
  x = varargin{3};
  if strcmp(fn,'msne')
    if (~isa(x,'network')) && (~isa(x,'struct')),error('NNET:Arguments','Network argument expected'); end
  else
    if isa(x,'network') || isa(x,'struct'), x = getx(x); end
  end
end
if (num<4), fp = param_defaults; else fp=varargin{4}; end
out1 = performance(e,y,x,fp);
