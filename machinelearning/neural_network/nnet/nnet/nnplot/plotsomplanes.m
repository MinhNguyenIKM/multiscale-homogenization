function result = plotsomplanes(varargin)
%PLOTSOMPLANES Plot self-organizing map weight planes.
%
%  Syntax
%
%    plotsomplanes(net)
%
%  Description
%
%    PLOTSOMPLANES(NET) generate a set of subplots. Each ith subplot shows
%    the weights from the ith input to the layer's neurons, with the
%    most negative connections shown as blue, zero connections as
%    black, and the strongest positive connections as red.
%
%    The plot will only be shown for layers organized in one or two
%    dimensions.
%
%    This function can also be called with standardized plotting function
%    arguments used by the function TRAIN. For a description see help
%    for TEMPLATE_PLOT.
%
%  Example
%
%    load iris_dataset
%    net = newsom(irisInputs,[5 5]);
%    [net,tr] = train(net,irisInputs);
%    plotsomplanes(net);
%
% See also plotsomhits, plotsomn, plotsomnd

% Copyright 2007 The MathWorks, Inc.

if nargin < 1, error('NNET:Arguments','Not enough input arguments.'); end

%% Info
if (nargin == 1) && strcmp(varargin{1},'info')
  info.name = mfilename;
  info.title = 'SOM Weight Planes';
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
  net = v1;
  fig = new_figure('');
elseif  (isa(v1,'network') && (nargin == 3))
  % Standard Plotting Function Arguments - Recycle plot
  net = v1;
  fig = nn_find_tagged_figure(mfilename);
  if isempty(fig), fig = new_figure(mfilename); end
else
  error('NNET:Arguments','Invalid input arguments.');
end
update_figure(fig,net);
drawnow
if (nargout > 0), result = fig; end

%% New Figure
function fig = new_figure(tag)

fig = figure;
ud.axis = gca;
ud.numInputs = 0;
ud.numNeurons = 0;
ud.topologyFcn = '';

set(fig,'name','SOM Weight Planes (plotsomplanes)');
set(fig,'menubar','none','toolbar','none','NumberTitle','off');
set(fig,'tag',tag,'UserData',ud)

%% Update Figure
function update_figure(fig,net)

ok = true;

if ok
  plot_figure(fig,net);
else
  clear_figure(fig);
end
drawnow

%% Plot Figure
function plot_figure(fig,net)

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

if (ud.numInputs ~= numInputs) || (ud.numNeurons ~= numNeurons) ...
    || ~strcmp(ud.topologyFcn,topologyFcn)
  clf(fig);
  set(fig,'nextplot','replace');
  
  ud.numInputs = numInputs;
  ud.numNeurons = numNeurons;
  ud.topologyFcn = topologyFcn;
  
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
  
  plotcols = ceil(sqrt(numInputs));
  plotrows = ceil(numInputs/plotcols);
  
  ud.patches = cell(numInputs);
  for i=1:plotrows
    for j=1:plotcols
      k = (i-1)*plotcols+j;
      if (k<=numInputs)
        a = subplot(plotrows,plotcols,k);
        set(a,...
          'dataaspectratio',[1 1 1], ...
          'box','on',...
          'color',[1 1 1]*0.5)
        hold on
    
        ud.patches{k} = zeros(1,numNeurons);
        for ii=1:numNeurons
          z = fill(pos(1,ii)+shapex,pos(2,ii)+shapey,[1 1 1]);
          set(z,'EdgeColor','none');
          ud.patches{k}(ii) = z;
        end
        
        set(a,'xlim',[-1 (dim1-0.5)*dx + 1]);
        set(a,'ylim',[-1 (dim2-0.5)*dy + 0.5]);
        title(a,['Weights from Input ' num2str(k)]);
      end
    end
  end
  
  set(fig,'userdata',ud);
  set(fig,'nextplot','new');
  
  screenSize = get(0,'ScreenSize');
  screenSize = screenSize(3:4);
  windowSize = 700 * [1 (plotrows/plotcols)];
  pos = [(screenSize-windowSize)/2 windowSize];
  set(fig,'position',pos);
end

iw = net.iw{1,1};
%min_neg = min(0,min(iw,[],1));
%max_pos = max(0,max(iw,[],1));
mn = min(iw,[],1);
mx = max(iw,[],1);
rng = mx-mn;
for i=1:numInputs
  for j=1:numNeurons
    level = net.iw{1,1}(j,i);
    %if level<0, level = -level/min_neg(i); end
    %if level>0, level = level/max_pos(i); end
    %red = min(1,max(0,level)*2); % positive
    %blue = -max(-1,min(0,level)*2); % negative
    %green = max(0,abs(level)*2-1); % very positive/negative
    level = (level-mn(i))/rng(i);
    red = min(1,level*2);
    green = max(0,level*2-1);
    blue = 0;
    set(ud.patches{i}(j),'FaceColor',[red green blue]);
  end
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

