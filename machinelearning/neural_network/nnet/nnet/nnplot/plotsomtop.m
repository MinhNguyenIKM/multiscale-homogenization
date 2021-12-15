function result = plotsomtop(varargin)
%PLOTSOMTOP Plot self-organizing map topology.
%
%  Syntax
%
%    plotsomtop(net)
%
%  Description
%
%    PLOTSOMTOP(NET) plots the topology of a SOM layer.
%
%  Example
%
%    load iris_dataset
%    net = newsom(irisInputs,[8 8]);
%    plotsomtop(net);
%
% See also plotsomnd, plotsomplanes, plotsomhits

% Copyright 2007 The MathWorks, Inc.

if nargin < 1, error('NNET:Arguments','Not enough input arguments.'); end

%% Info
if (nargin == 1) && strcmp(varargin{1},'info')
  info.name = mfilename;
  info.title = 'SOM Topology';
  info.type = 'Plot';
  info.version = 6;
  result = info;
  return;
end

if nargin < 1, error('NNET:Arguments','Incorrect number of input arguments.'); end

%% Plot
v1 = varargin{1};
if (isa(v1,'network') && (nargin == 1))
  % User arguments - New plot
  [net,inputs] = deal(varargin{:});
  fig = new_figure('');
elseif  (isa(v1,'network') && (nargin == 3))
  % Standard Plotting Function Arguments - Recycle plot
  [net,tr,signals] = deal(varargin{:});
  trainV = signals{1};
  inputs = trainV.X;
  fig = nn_find_tagged_figure(mfilename);
  if isempty(fig), fig = new_figure(mfilename); end
else
  error('NNET:Arguments','Invalid input arguments.');
end
update_figure(fig,net,inputs);
drawnow
if (nargout > 0), result = fig; end

%% New Figure
function fig = new_figure(tag)

fig = figure;
ud.axis = gca;
ud.numInputs = 0;
ud.numNeurons = 0;
ud.topologyFcn = '';

set(fig,'name','SOM Topology (plotsomtop)');
set(fig,'menubar','none','toolbar','none','NumberTitle','off');
set(fig,'tag',tag,'UserData',ud)

%% Update Figure
function update_figure(fig,net,inputs)

ok = true;

if ok
  plot_figure(fig,net,inputs);
else
  clear_figure(fig);
end
drawnow

%% Plot Figure
function plot_figure(fig,net,inputs)

% Standardize inputs
if iscellmat(inputs), inputs = inputs{1,1}; end

set(0,'CurrentFigure',fig);
ud = get(fig,'userdata');

numInputs = net.inputs{1}.processedSize;
numNeurons = net.layers{1}.size;
topologyFcn = net.layers{1}.topologyFcn;

if strcmp(topologyFcn,'gridtop')  
  symmetry = 4;
  shapex = [-1 1 1 -1]*0.5;
  shapey = [1 1 -1 -1]*0.5;
  dx = 1;
  dy = 1;
  edgex = [-1 0 1 0]*0.5;
  edgey = [0 1 0 -1]*0.5;
elseif strcmp(topologyFcn,'hextop')
  symmetry = 6;
  z = sqrt(0.75)/3;
  shapex = [-1 0 1 1 0 -1]*0.5;
  shapey = [1 2 1 -1 -2 -1]*z;
  dx = 1;
  dy = sqrt(0.75);
  edgex = [-1 0 1 0]*0.5;
  edgey = [0 1 0 -1]*z;
end

pos = net.layers{1}.positions;
dimensions = net.layers{1}.dimensions;
numDimensions = length(dimensions);
if (numDimensions == 1)
  dim1 = dim(1);
  dim2 = 1;
  pos = [pos; zeros(1,size(pos,2))];
elseif (numDimensions > 2)
  pos = pos(1:2,:);
  dim1 = dimensions(1);
  dim2 = dimensions(2);
else
  dim1 = dimensions(1);
  dim2 = dimensions(2);
end

if (ud.numInputs ~= numInputs) || any(ud.dimensions ~= dimensions) ...
    || ~strcmp(ud.topologyFcn,topologyFcn)
  clf(fig);
  set(fig,'nextplot','replace');
  ud.numInputs = numInputs;
  ud.dimensions = dimensions;
  ud.topologyFcn = topologyFcn;
    
  a = axes;
  set(a,...
    'dataaspectratio',[1 1 1],...
    'box','on',...
    'color',[1 1 1]*0.5)
  hold on
  
  % Setup neurons
  for i=1:numNeurons
    fill(pos(1,i)+shapex,pos(2,i)+shapey,[1 1 1], ...
      'FaceColor',[0.4 0.4 0.6], ...
      'EdgeColor',[1 1 1]*0.8)
  end
        
  set(a,'xlim',[-1 (dim1-0.5)*dx + 1]);
  set(a,'ylim',[-1 (dim2-0.5)*dy + 0.5]);
  title(a,'SOM Topology');
  
  set(fig,'userdata',ud);
  set(fig,'nextplot','new');
end

%% Clear Figure
function clear_figure(fig)

ud = get(fig,'userdata');
set(ud.outputLine,'Xdata',[NaN NaN],'Ydata',[NaN NaN]);
set(ud.targetLine,'Xdata',[NaN NaN],'Ydata',[NaN NaN]);
set(ud.fitLine,'Xdata',[NaN NaN],'Ydata',[NaN NaN]);
set(ud.errorLine,'Xdata',[NaN NaN],'Ydata',[NaN NaN]);

set(ud.axis,'xlim',[0 1]);
set(ud.axis,'ylim',[0 1]);
set(ud.warning1,'visible','on');
set(ud.warning2,'visible','on');


