function result = plotregression(varargin)
%PLOTREGRESSION Plot linear regression.
%
%  Syntax
%
%    plotreg(targets,outputs)
%    plotreg(targets1,outputs1,'name1',targets,outputs2,'name2', ...)
%
%  Description
%
%    PLOTREGRESSION(TARGETS,OUTPUTS) plots the linear regression
%    of TARGETS relative to OUTPUTS.
%
%    PLOTREGRESSION(TARGETS1,OUTPUTS2,'name1',...) generates multiple plots.
%    
%  Example
%
%    load simplefit_dataset
%    net = newff(simplefitInputs,simplefitTargets,20);
%    [net,tr] = train(net,simplefitInputs,simplefitTargets);
%    simplefitOutputs = sim(net,simplefitInputs);
%    plotregression(simplefitTargets,simplefitOutputs);
%
% See also plottrainstate

% Copyright 2007-2008 The MathWorks, Inc.

if nargin < 1, error('NNET:Arguments','Not enough input arguments.'); end

%% Info
if (nargin == 1) && strcmp(varargin{1},'info')
  info.name = mfilename;
  info.title = 'Regression';
  info.type = 'Plot';
  info.version = 6;
  result = info;
  return;
end

if nargin < 2, error('NNET:Arguments','Incorrect number of input arguments'); end

%% Plot
if ~isa(varargin{1},'network')
  % User arguments - New plot
  count = round(nargin/3);
  tt = cell(1,count);
  yy = cell(1,count);
  names = cell(1,count);
  for i=1:count
    tt{i} = varargin{i*3-2};
    yy{i} = varargin{i*3-1};
    if nargin >= (i*3)
      names{i} = varargin{i*3};
    else
      names{i} = 'Regression';
      if (count > 1), names{i} = [names{i} ' ' num2str(i)]; end;
    end
  end
  fig = new_figure('');
else
  % Standard Plotting Function Arguments - Recycle plot
  [net,tr,signals] = deal(varargin{:});
  tt={};
  yy={};
  names = {};
  for i=1:length(signals)
    signal = signals{i};
    if ~isempty(signal.indices)
      tt = [tt {signal.T}];
      yy = [yy {signal.Y}];
      names = [names {signal.name}];
    end
  end
  if length(names) > 1
    tt = [tt {cell2mat([tt{:}])}];
    yy = [yy {cell2mat([yy{:}])}];
    names = [names {'All'}];
  end
  fig = nn_find_tagged_figure(mfilename);
  if isempty(fig), fig = new_figure(mfilename); end
end
update_figure(fig,tt,yy,names);
if (nargout > 0), result = fig; end

%% New Figure
function fig = new_figure(tag)

fig = figure;
ud.numSignals = 0;

set(fig,'name','Regression (plotregression)');
set(fig,'menubar','none','toolbar','none','NumberTitle','off');
set(fig,'tag',tag,'UserData',ud)

%% Update Figure
function update_figure(fig,tt,yy,names)

ok = check_data(tt,yy,names);
if ok
  plot_figure(fig,tt,yy,names);
else
  clear_figure(fig);
end

%% Plot Figure
function plot_figure(fig,tt,yy,names)

trainColor = [0 0 1];
valColor = [0 1 0];
testColor = [1 0 0];
allColor = [1 1 1] * 0.4;
colors = {trainColor valColor testColor allColor};

set(0,'CurrentFigure',fig);
ud = get(fig,'userdata');

numSignals = length(names);

% Create axes
if (ud.numSignals ~= numSignals)
  clf(fig);
  set(fig,'nextplot','replace');
  
  ud = struct;
  ud.numSignals = numSignals;
  
  plotcols = ceil(sqrt(numSignals));
  plotrows = ceil(numSignals/plotcols);
  
  for plotrow=1:plotrows
    for plotcol=1:plotcols
      i = (plotrow-1)*plotcols+plotcol;
      if (i<=numSignals)
        
        a = subplot(plotrows,plotcols,i);
        set(a,...
          'dataaspectratio',[1 1 1], ...
          'box','on');
        xlabel(a,'Target');
        hold on
        ud.axes(i) = a;
      
        ud.eqLine(i) = plot([NaN NaN],[NaN NaN],':k');
        color = colors{rem(i-1,length(colors))+1};
        ud.regLine(i) = plot([NaN NaN],[NaN NaN],'linewidth',2,'Color',color);
        ud.dataPoints(i) = plot([NaN NaN],[NaN NaN],'ok');
        legend([ud.dataPoints(i),ud.regLine(i),ud.eqLine(i)], ...
          {'Data','Fit','Y = T'},'Location','NorthWest');
        
      end
    end
  end
  
  set(fig,'UserData',ud)
  set(fig,'nextplot','new');
  
  screenSize = get(0,'ScreenSize');
  screenSize = screenSize(3:4);
  windowSize = 700 * [1 (plotrows/plotcols)];
  pos = [(screenSize-windowSize)/2 windowSize];
  set(fig,'position',pos);
  drawnow
end

% Fill axes
for i=1:numSignals
  set(fig,'CurrentAxes',ud.axes(i));
  
  y = yy{i}; if iscell(y), y = cell2mat(y); end, y = y(:)';
  t = tt{i}; if iscell(t), t = cell2mat(t); end, t = t(:)';
  name = names{i};
  
  [m,b,r] = postreg(y,t,'hide');
  lim = [min([y t]) max([y t])];
  line = m*lim + b;

  set(ud.dataPoints(i),'xdata',t,'ydata',y);
  set(ud.regLine(i),'xdata',lim,'ydata',line)
  set(ud.eqLine(i),'xdata',lim,'ydata',lim);
  
  set(gca,'xlim',lim);
  set(gca,'ylim',lim);
  axis('square')
  
  ylabel(['Output~=',num2str(m,2),'*Target+', num2str(b,2)]);
  title([name ': R=' num2str(r)])
end

drawnow

%% Clear Figure
function clear_figure(fig)

ud = get(fig,'userdata');

for i=1:3
  set(ud.dataPoints(i),'xdata',[NaN NaN],'ydata',[NaN NaN]);
  axisi = ud.axes(i);
  set(axisi,'xlim',[0 1]);
  set(axisi,'ylim',[0 1]);
end

%set(ud.warning1,'visible','on');
%set(ud.warning2,'visible','on');

drawnow

%% Check Data
function ok = check_data(tt,yy,names)

ok = true;
return

for i=1:length(signals)
  
  signal = signals{i};
  
  y = signal.Y;
  t = signal.T;

  [yS,yTS] = size(y);
  [tS,tTS] = size(t);
  if (yS ~= tS), ok = false; end
  if (yTS ~= tTS), ok = false; end

  [yrows,ycols] = size(y{1});
  [trows,tcols] = size(t{1});
  if (trows ~= yrows), ok = false; end
  if (tcols ~= ycols), ok = false; end
  for i=2:yTS
    [yrowsi,ycolsi] = size(y{2});
    [trowsi,tcolsi] = size(t{2});
    if (yrowsi ~= yrows), ok = false; end
    if (ycolsi ~= ycols), ok = false; end
    if (trowsi ~= yrows), ok = false; end
    if (tcolsi ~= ycols), ok = false; end
  end
end

