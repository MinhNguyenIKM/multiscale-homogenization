function result = plotconfusion(varargin)
%PLOTCONFUSION Plot classification confusion matrix.
%
%  Syntax
%
%    plotconfusion(targets,outputs)
%    plotconfusion(targets1,outputs1,'name1',targets,outputs2,'name2', ...)
%
%  Description
%
%    PLOTCONFUSION(targets,outputs) displays the classification confusion grid.
%
%    PLOTCONFUSION(targets1,outputs1,'name1',...) plots a series of plots.
%    
%  Example
%
%    load simpleclass_dataset
%    net = newpr(simpleclassInputs,simpleclassTargets,20);
%    net = train(net,simpleclassInputs,simpleclassTargets);
%    simpleclassOutputs = sim(net,simpleclassInputs);
%    plotconfusion(simpleclassTargets,simpleclassOutputs);
%
% See also plotreg, template_plot

% Copyright 2007-2008 The MathWorks, Inc.

if nargin < 1, error('NNET:Arguments','Not enough input arguments.'); end

%% Info
if (nargin == 1) && strcmp(varargin{1},'info')
  info.name = mfilename;
  info.title = 'Confusion';
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
      names{i} = '';
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
ud.numClasses = 0;
ud.axes = [];

set(fig,'name','Confusion (plotconfusion)');
set(fig,'menubar','none','toolbar','none','NumberTitle','off');
set(fig,'tag',tag,'UserData',ud)

screenSize = get(0,'ScreenSize');
screenSize = screenSize(3:4);
windowSize = [(100+300*3) 400];
pos = [(screenSize-windowSize)/2 windowSize];
set(gcf,'position',pos);

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
colors = {trainColor valColor testColor};

set(0,'CurrentFigure',fig);
ud = get(fig,'userdata');

t = tt{1}; if iscell(t), t = cell2mat(t); end
numSignals = length(names);
[numClasses,numSamples] = size(t);
numClasses = max(numClasses,2);
numColumns = numClasses+1;
  
% Rebuild figure
if (ud.numSignals ~= numSignals) || (ud.numClasses ~= numClasses)
  clf(fig);
  set(fig,'nextplot','replace');
  ud.numSignals = numSignals;
  ud.numClasses = numClasses;
  ud.axes = zeros(1,numSignals);
  
  pos = get(fig,'position');
  windowSize = [350*numSignals, 300];
  pos(3:4) = windowSize;
  if (ud.numSignals == 0)
    screenSize = get(0,'ScreenSize');
    screenSize = screenSize(3:4);
    pos(1:2)= (screenSize-windowSize)/2;
  end
  set(fig,'position',pos);
  
  plotcols = ceil(sqrt(numSignals));
  plotrows = ceil(numSignals/plotcols);
  
  for plotrow=1:plotrows
    for plotcol=1:plotcols
      i = (plotrow-1)*plotcols+plotcol;
      if (i<=numSignals)
        
        a = subplot(plotrows,plotcols,i);
        set(a,'ydir','reverse')
        set(a,'ticklength',[0 0])
        %set(a,'XAxisLocation','top')
        set(a,'dataaspectratio',[1 1 1])
        hold on

        mn = 0.5;
        mx = numColumns+0.5;
        labels = cell(1,numColumns);
        for j=1:numClasses, labels{j} = num2str(j); end
        labels{numColumns} = '';
        set(a,'xlim',[mn mx],'xtick',1:(numColumns+1));
        set(a,'ylim',[mn mx],'ytick',1:(numColumns+1));
        set(a,'xticklabel',labels);
        set(a,'yticklabel',labels);
        %aa = reshape(repmat((0:numColumns)+0.5,3,1),1,3*(numColumns+1));
        %bb = repmat([mn mx NaN],1,numColumns+1);
        %plot([aa bb],[bb aa]);

        nngray = [167 167 167]/255;

        axisdata.number = zeros(numColumns,numColumns);
        axisdata.percent = zeros(numColumns,numColumns);
        for j=1:numColumns
          for k=1:numColumns
          if (j==numColumns) && (k==numColumns)
            c = nnblue;
            topcolor = [0 0.4 0];
            bottomcolor = [0.4 0 0];
            topbold = 'bold';
            bottombold = 'bold';
          elseif (j==k)
            c = nngreen;
            topcolor = [0 0 0];
            bottomcolor = [0 0 0];
            topbold = 'bold';
            bottombold = 'normal';
          elseif (j<numColumns) && (k<numColumns)
            c = nnred;
            topcolor = [0 0 0];
            bottomcolor = [0 0 0];
            topbold = 'bold';
            bottombold = 'normal';
          elseif (j<numColumns)
            c = nngray;
            topcolor = [0 0.4 0];
            bottomcolor = [0.4 0 0];
            topbold = 'normal';
            bottombold = 'normal';
          else
            c = nngray;
            topcolor = [0 0.4 0];
            bottomcolor = [0.4 0 0];
            topbold = 'normal';
            bottombold = 'normal';
          end
          fill([0 1 1 0]-0.5+j,[0 0 1 1]-0.5+k,c);
          axisdata.number(j,k) = text(j,k,'', ...
            'horizontalalignment','center',...
            'verticalalignment','bottom',...
            'FontWeight',topbold,...
            'color',topcolor); %,...
            %'FontSize',8);
          axisdata.percent(j,k) = text(j,k,'', ...
            'horizontalalignment','center',...
            'verticalalignment','top',...
            'FontWeight',bottombold,...
            'color',bottomcolor); %,...
            %'FontSize',8);
          end
        end

        plot([0 0]+numColumns-0.5,[mn mx],'linewidth',2,'color',[0 0 0]+0.25);
        plot([mn mx],[0 0]+numColumns-0.5,'linewidth',2,'color',[0 0 0]+0.25);

        xlabel('Target Class');
        ylabel('Output Class');
        title([names{i} ' Confusion Matrix'])

        set(a,'userdata',axisdata);
        ud.axes(i) = a;
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

% Fill axes
for i=1:numSignals
  a = ud.axes(i);
  set(fig,'CurrentAxes',a);
  axisdata = get(a,'userdata');
  
  y = yy{i}; if iscell(y), y = cell2mat(y); end
  t = tt{i}; if iscell(t), t = cell2mat(t); end
  numSamples = size(t,2);
  [c,cm] = confusion(t,y);
  
  for j=1:numColumns
    for k=1:numColumns
      if (j==numColumns) && (k==numColumns)
        correct = sum(diag(cm));
        perc = correct/numSamples;
        top = percent_string(perc);
        bottom = percent_string(1-perc);
      elseif (j==k)
        num = cm(j,k);
        top = num2str(num);
        perc = num/numSamples;
        bottom = percent_string(perc);
      elseif (j<numColumns) && (k<numColumns)
        num = cm(j,k);
        top = num2str(num);
        perc = num/numSamples;
        bottom = percent_string(perc);
      elseif (j<numColumns)
        correct = cm(j,j);
        total = sum(cm(j,:));
        perc = correct/total;
        top = percent_string(perc);
        bottom = percent_string(1-perc);
      else
        correct = cm(k,k);
        total = sum(cm(:,k));
        perc = correct/total;
        top = percent_string(perc);
        bottom = percent_string(1-perc);
      end
      set(axisdata.number(j,k),'string',top);
      set(axisdata.percent(j,k),'string',bottom);
    end
  end
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

function ps = percent_string(p)

if (p==1)
  ps = '100%';
else
  ps = [sprintf('%2.1f',p*100) '%'];
end
