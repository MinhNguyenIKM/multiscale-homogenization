function result = plotsomhits(varargin)
%PLOTSOMHITS Plot self-organizing map sample hits.
%
%  Syntax
%
%    plotsomhits(net,inputs)
%    plotsomhits(net,inputs,targets)
%
%  Description
%
%    PLOTSOMHITS(NET,INPUTS) plots a SOM layer, with each neuron showing
%    the number of input vectors that it classifies. The relative number
%    of vectors for each neuron is shown via the size of a colored patch.
%
%  Example
%
%    load iris_dataset
%    net = newsom(irisInputs,[5 5]);
%    [net,tr] = train(net,irisInputs);
%    plotsomhits(net,irisInputs);
%
% See also plotsomplanes

% Copyright 2007 The MathWorks, Inc.

if nargin < 1, error('NNET:Arguments','Not enough input arguments.'); end

%% Info
if (nargin == 1) && strcmp(varargin{1},'info')
  info.name = mfilename;
  info.title = 'SOM Sample Hits';
  info.type = 'Plot';
  info.version = 6;
  result = info;
  return;
end

if nargin < 1, error('NNET:Arguments','Incorrect number of input arguments.'); end

%% Plot
v1 = varargin{1};
if isa(v1,'network') && (nargin == 2)
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

set(fig,'name','SOM Sample Hits (plotsomhits)');
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
  shapex = [-1 1 1 -1]*0.5;
  shapey = [1 1 -1 -1]*0.5;
  dx = 1;
  dy = 1;
elseif strcmp(topologyFcn,'hextop')
  z = sqrt(0.75);
  shapex = [-1 0 1 1 0 -1]*0.5;
  shapey = [1 2 1 -1 -2 -1]*(z/3);
  dx = 1;
  dy = sqrt(0.75);
end

pos = net.layers{1}.positions;
dim = net.layers{1}.dimensions;
numDimensions = length(dim);
if (numDimensions == 1)
  dim1 = dim(1);
  dim2 = 1;
  pos = [pos; zeros(1,size(pos,2))];
elseif (numDimensions > 2)
  pos = pos(1:2,:);
  dim1 = dim(1);
  dim2 = dim(2);
else
  dim1 = dim(1);
  dim2 = dim(2);
end

if (ud.numInputs ~= numInputs) || (ud.numNeurons ~= numNeurons) ...
    || ~strcmp(ud.topologyFcn,topologyFcn)
  clf(fig);
  set(fig,'nextplot','replace');
  
  ud.numInputs = numInputs;
  ud.numNeurons = numNeurons;
  ud.topologyFcn = topologyFcn;
    
  a = axes;
  set(a,...
    'dataaspectratio',[1 1 1],...
    'box','on',...
    'color',[1 1 1]*0.5)
  hold on
    
  ud.patches = zeros(1,numNeurons);
  ud.text = zeros(1,numNeurons);
  for i=1:numNeurons
    fill(pos(1,i)+shapex,pos(2,i)+shapey,[1 1 1], ...
      'EdgeColor',[1 1 1]*0.8, ...
      'FaceColor',[1 1 1]);
    ud.patches(i) = fill(pos(1,i)+shapex,pos(2,i)+shapey,[1 1 1],...
      'EdgeColor','none');
    ud.text(i) = text(pos(1,i),pos(2,i),'', ...
      'HorizontalAlignment','center',...
      'VerticalAlignment','middle',...
      'FontWeight','bold',...
      'color',[1 1 1], ...
      'FontSize',8);
  end
        
  set(a,'xlim',[-1 (dim1-0.5)*dx + 1]);
  set(a,'ylim',[-1 (dim2-0.5)*dy + 0.5]);
  title(a,'Hits');
  
  set(fig,'userdata',ud);
  set(fig,'nextplot','new');
end

outputs = sim(net,inputs);
hits = sum(outputs,2);
norm_hits = sqrt(hits/max(hits));

for i=1:numNeurons
  set(ud.patches(i), ...
    'xdata',pos(1,i)+shapex*norm_hits(i),...
    'ydata',pos(2,i)+shapey*norm_hits(i),...
    'FaceColor',[0.4 0.4 0.6], ...
    'EdgeColor',[1 1 1]*0.8);
  set(ud.text(i),'String',num2str(hits(i)));
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

