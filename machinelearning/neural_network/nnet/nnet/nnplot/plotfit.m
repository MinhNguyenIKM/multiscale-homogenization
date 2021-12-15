function result = plotfit(varargin)
%PLOTFIT Plot function fit.
%
%  Syntax
%
%    plotfit(net,inputs,targets)
%    plotfit(net,inputs1,targets1,'name1',inputs2,targets2,'name2',...)
%
%  Description
%
%    PLOTFIT(NET,INPUTS,TARGETS) plots the output function of a network across the
%    range of the inputs X, and also plots target T and output data points
%    associated with values in X. Error bars show the difference between
%    outputs and T.
%
%    The plot will only be shown for networks with 1 input.
%    Only the first output/targets are shown if the network has more than
%    one output.
%
%    PLOTFIT(targets1,outputs1,'name1',...) plots a series of plots.
%
%  Example
%
%    load simplefit_dataset
%    net = newfit(simplefitInputs,simplefitTargets,20);
%    [net,tr] = train(net,simplefitInputs,simplefitTargets);
%    plotfit(net,simplefitInputs,simplefitTargets);
%
% See also plottrainstate

% Copyright 2007-2008 The MathWorks, Inc.

if nargin < 1, error('NNET:Arguments','Not enough input arguments.'); end

%% Info
if (nargin == 1) && strcmp(varargin{1},'info')
  info.name = mfilename;
  info.title = 'Fit';
  info.type = 'Plot';
  info.version = 6;
  result = info;
  return;
end

if nargin < 3, error('NNET:Arguments','Incorrect number of input arguments.'); end

%% Plot
v2 = varargin{2};
if (isnumeric(v2) || iscellmat(v2))
  % User arguments - New plot
  net = varargin{1};
  count = round((nargin-1)/3);
  xx = cell(1,count);
  tt = cell(1,count);
  names = cell(1,count);
  for i=1:count
    xx{i} = varargin{i*3-1};
    tt{i} = varargin{i*3};
    if nargin >= (i*3+1)
      names{i} = varargin{i*3+1};
    else
      names{i} = '';
    end
  end
  fig = new_figure('');
else
  % Standard Plotting Function Arguments - Recycle plot
  [net,tr,signals] = deal(varargin{:});
  xx={};
  tt={};
  names = {};
  for i=1:length(signals)
    signal = signals{i};
    if ~isempty(signal.indices)
      xx = [xx {signal.X}];
      tt = [tt {signal.T}];
      names = [names {signal.name}];
    end
  end
  if length(names) > 1
    xx = [xx {cell2mat([xx{:}])}];
    tt = [tt {cell2mat([tt{:}])}];
    names = [names {'All'}];
  end
  fig = nn_find_tagged_figure(mfilename);
  if isempty(fig), fig = new_figure(mfilename); end
end
update_figure(fig,net,xx,tt,names);
if (nargout > 0), result = fig; end

%% New Figure
function fig = new_figure(tag)

fig = figure;
ud.ok = -1;
ud.numSignals = 0;
set(fig,'name','Fit (plotfit)');
set(fig,'menubar','none','toolbar','none','NumberTitle','off');
set(fig,'tag',tag,'UserData',ud)

windowSize = [900 600];
screenSize = get(0,'ScreenSize');
screenSize = screenSize(3:4);
pos = [(screenSize-windowSize)/2 windowSize];
set(gcf,'position',pos);


%% Update Figure
function update_figure(fig,net,xx,tt,names)

x = xx{1}; if iscell(x),x = x{1}; end
ok = true;
if (size(x,1) ~= 1), ok = false; end
if net.numInputDelays > 0, ok = false; end
if net.numLayerDelays > 0, ok = false; end

plot_figure(fig,net,xx,tt,names,ok);
drawnow

%% Plot Figure
function plot_figure(fig,net,xx,tt,names,ok)

set(0,'CurrentFigure',fig);
ud = get(fig,'userdata');

numSignals = length(names);

if (ud.ok ~= ok) || (ud.numSignals ~= numSignals)
  clf(fig);
  set(fig,'nextplot','replace');
  
  ud.ok = ok;
  ud.numSignals = numSignals;
  
  ud.axis = subplot(1,1,1);
  hold on
  
  errorColor = [1 0.6 0];
  fitColor = [0 0 0];
  colors = {[0 0 1],[0 0.8 0],[1 0 0],[1 1 1]*0.5};

  ud.errorLine = plot([NaN NaN],[NaN NaN],'linewidth',2,'Color',errorColor);
  ud.fitLine = plot([NaN NaN],[NaN NaN],'LineWidth',2,'Color',fitColor);
  ud.targetLines = zeros(1,numSignals);
  ud.outputLines = zeros(1,numSignals);
  targetLegends = cell(1,numSignals);
  outputLegends = cell(1,numSignals);
  for i=1:numSignals
    c = colors{min(i,4)};
    ud.targetLines(i) = plot([NaN NaN],[NaN NaN],'o','LineWidth',1.5,'Color',c);
    ud.outputLines(i) = plot([NaN NaN],[NaN NaN],'+','Markersize',8,'linewidth',1.5,'Color',c);
    if ~isempty(names{1})
      targetLegends{i} = [names{i} ' Targets'];
      outputLegends{i} = [names{i} ' Outputs'];
    else
      targetLegends{i} = 'Targets';
      outputLegends{i} = 'Outputs';
    end
  end
  
  ud.title = title('Function Fit');
  ud.ylabel = ylabel('Output and Targets');
  ud.xlabel = xlabel('Input');
  
  legend([interleave(ud.targetLines,ud.outputLines),ud.errorLine,ud.fitLine], ...
    [interleave(targetLegends, outputLegends), {'Errors','Fit'}]);
  
  if (~ok)
    text(0.5,0.55,'Data has too many dimensions to plot.', ...
      'horizontalalignment','center','fontweight','bold', ...
      'units','normalized');
    text(0.5,0.45,'Only static networks with 1 input can be plotted.', ...
      'horizontalalignment','center','fontweight','bold', ...
      'units','normalized');
  end

  set(fig,'userdata',ud);
  set(fig,'nextplot','new');
  drawnow
end

if (~ok), return, end

X = [];
T = [];
Y = [];
for i=1:numSignals
  x = xx{i}; if iscell(x),x = x{1}; end
  t = tt{i}; if iscell(t),t = t{1}; end, t = t(1,:);
  
  y = sim(net,x);
  
  X = [X x];
  T = [T t];
  Y = [Y y];
  
  if (i==1)
    xmin = min(x);
    xmax = max(x);
  else
    xmin = min(xmin,min(x));
    xmax = max(xmax,max(x));
  end
  
  set(ud.outputLines(i),'xdata',x,'ydata',y);
  set(ud.targetLines(i),'xdata',x,'ydata',t);
end

extend = (xmax-xmin)*0;
xlim = [xmin-extend,xmax+extend];
x = linspace(xlim(1),xlim(2),1000);
y = sim(network(net),x);
set(ud.fitLine,'xdata',x,'ydata',y);

numPoints = length(X);
spaces = nan(1,numPoints);
x = [X; X; spaces];
y = [Y; T; spaces];
x = x(:)';
y = y(:)';
set(ud.errorLine,'xdata',x,'ydata',y);

set(ud.axis,'xlim',xlim);
set(ud.axis,'ylimmode','auto');

function y = interleave(a,b)

y = reshape([a;b],1,2*length(a));

