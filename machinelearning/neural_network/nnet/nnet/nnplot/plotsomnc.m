function result = plotsomnc(varargin)
%PLOTSOMNC Plot Self-organizing map neighbor connections.
%
%  Syntax
%
%    plotsomnc(net)
%
%  Description
%
%    PLOTSOMNC(NET) plots a SOM layer showing neurons as gray-blue patches
%    and their direct neighbor relations with red lines.
%
%  Example
%
%    load iris_dataset
%    net = newsom(irisInputs,[5 5]);
%    plotsomnc(net);
%
% See also plotsomnd, plotsomplanes, plotsomhits

% Copyright 2007-2008 The MathWorks, Inc.

if nargin < 1, error('NNET:Arguments','Not enough input arguments.'); end

%% Info
if (nargin == 1) && strcmp(varargin{1},'info')
  info.name = mfilename;
  info.title = 'SOM Neighbor Connections';
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

set(fig,'name','SOM Neighbor Connections (plotsomnc)');
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
shapex = shapex*0.3;
shapey = shapey*0.3;

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
  
  % Setup edges
  ud.neighbors = sparse(tril(net.layers{1}.distances <= 1.001) - eye(numNeurons));
  ud.numEdges = sum(sum(ud.neighbors));
  ud.patches = zeros(1,ud.numEdges);
  ud.text = zeros(1,ud.numEdges);
  k = 1;
  for i=1:numNeurons
    for j=find(ud.neighbors(i,:))
      pdiff = pos(:,j)-pos(:,i);
      angle = atan2(pdiff(2),pdiff(1));
      [ex,ey] = rotate_xy(edgex,edgey,angle);
      edgePos = (pos(:,i)+pos(:,j))*0.5;
      p1 = (2*pos(:,i) + pos(:,j))./3;
      p2 = (pos(:,i) + 2*pos(:,j))./3;
      ud.patches(k) = fill(edgePos(1)+ex,edgePos(2)+ey,[1 1 1],...
        'FaceColor',[1 1 1],...
        'EdgeColor',[1 1 1]*0.5);
      plot([p1(1) p2(1)],[p1(2) p2(2)],'-','color',[1 0 0]);
      k = k + 1;
    end
  end
  
  % Setup neurons
  for i=1:numNeurons
    fill(pos(1,i)+shapex,pos(2,i)+shapey,[1 1 1], ...
      'FaceColor',[0.4 0.4 0.6], ...
      'EdgeColor',[1 1 1]*0.8)
  end
        
  set(a,'xlim',[-1 (dim1-0.5)*dx + 1]);
  set(a,'ylim',[-1 (dim2-0.5)*dy + 0.5]);
  title(a,'SOM Neighbor Connections');
  
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

function [x2,y2] = rotate_xy(x1,y1,angle)

[a,r] = cart2pol(x1,y1);
a = a + angle;
[x2,y2] = pol2cart(a,r);

