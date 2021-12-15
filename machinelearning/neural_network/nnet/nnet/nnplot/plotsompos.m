function result = plotsompos(varargin)
%PLOTSOMPOS Plot self-organizing map weight positions.
%
%  Syntax
%
%    plotsompos(net)
%    plotsompos(net,inputs)
%
%  Description
%
%    PLOTSOMPOS(NET) plots the input vectors as green dots, and shows how
%    the SOM classifies the input space by showing blue-gray dots for each
%    neuron's weight vector and connecting neighboring neurons with red lines.
%
%  Example
%
%    load simplecluster_dataset
%    net = newsom(simpleclusterInputs,[10 10]);
%    net = train(net,simpleclusterInputs);
%    plotsompos(net,simpleclusterInputs);
%
% See also plotsomnd, plotsomplanes, plotsomhits

% Copyright 2007-2008 The MathWorks, Inc.

if nargin < 1, error('NNET:Arguments','Not enough input arguments.'); end

%% Info
if (nargin == 1) && strcmp(varargin{1},'info')
  info.name = mfilename;
  info.title = 'SOM Weight Positions';
  info.type = 'Plot';
  info.version = 6;
  result = info;
  return;
end

if nargin < 1, error('NNET:Arguments','Incorrect number of input arguments.'); end

%% Plot
v1 = varargin{1};
if (nargin < 3) || (~ isa(varargin{2},'struct'))
  % User arguments - New plot
  varargin = fill_defaults(varargin,[]);
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
ud.created = false;

set(fig,'name','SOM Weight Positions (plotsompos)');
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

if (~ud.created)
  clf(fig);
  set(fig,'nextplot','replace');
  
  a = axes;
  set(a,...
    'dataaspectratio',[1 1 1],...
    'box','on',...
    'color',[1 1 1])
  hold on
  
  % Setup neurons
  ud.inputs = plot([NaN NaN],[NaN NaN],'.g','markersize',10);
  ud.links = plot([NaN NaN],[NaN NaN],'r');
  ud.weights = plot([NaN NaN],[NaN NaN],'.','markersize',20,'color',[0.4 0.4 0.6]);
  
  title(a,'SOM Weight Positions');
  xlabel(a,'Weight 1');
  ylabel(a,'Weight 2');
  ud.axis = a;
  
  set(fig,'userdata',ud);
  set(fig,'nextplot','new');
end

weights = net.iw{1,1};
[numNeurons,numDimensions] = size(weights);
if numDimensions > 3
  weights = weights(:,1:3);
else
  weights = [weights zeros(numNeurons,3-numDimensions)];
end

% Inputs
if ~isempty(inputs)
  [numInputs,numSamples] = size(inputs);
  if numDimensions == 1
    fillInputs = zeros(1,numSamples);
    set(ud.inputs,'xdata',inputs(1,:),'ydata',fillInputs,'zdata',fillInputs-1);
  elseif numDimensions == 2
    fillInputs = zeros(1,numSamples);
    set(ud.inputs,'xdata',inputs(1,:),'ydata',inputs(2,:),'zdata',fillInputs-1);
  else
    set(ud.inputs,'xdata',inputs(1,:),'ydata',inputs(2,:),'zdata',inputs(3,:));
  end
else
  set(ud.inputs,'xdata',[NaN NaN],'ydata',[NaN NaN],'zdata',[NaN NaN]);
end

% Links
neighbors = sparse(tril(net.layers{1}.distances <= 1.001) - eye(numNeurons));
numEdges = sum(sum(neighbors));

linkx = nan(3,numEdges);
linky = nan(3,numEdges);
linkz = nan(3,numEdges);
k = 1;
for i=1:numNeurons
  for j=find(neighbors(i,:))
    linkx(1:2,k) = weights([i j],1);
    linky(1:2,k) = weights([i j],2);
    linkz(1:2,k) = weights([i j],3);
    k = k + 1;
  end
end
set(ud.links,'xdata',linkx(:)','ydata',linky(:)','zdata',linkz(:)');

% Weights
if numDimensions == 3
  set(ud.weights,'xdata',weights(:,1)','ydata',weights(:,2)','zdata',weights(:,3)');
else
  fillWeights = ones(1,numNeurons);
  set(ud.weights,'xdata',weights(:,1)','ydata',weights(:,2)','zdata',fillWeights);
end

% Axis
if numDimensions == 2
  set(ud.axis,'view',[0 90])
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


