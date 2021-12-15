function result = plotperform(varargin)
%PLOTPERFORM Plot network performance.
%
%  Syntax
%
%    plotperform(tr)
%
%  Description
%
%    PLOTPERFORM(TR) plots the training, validation and test performances
%    given the training record TR returned by the function TRAIN.
%    
%  Example
%
%    load simplefit_dataset
%    net = newff(simplefitInputs,simplefitTargets,20);
%    [net,tr] = train(net,simplefitInputs,simplefitTargets);
%    plotperform(tr);
%
% See also plottrainstate

% Copyright 2007 The MathWorks, Inc.

if nargin < 1, error('NNET:Arguments','Not enough input arguments.'); end

%% Info
if (nargin == 1) && strcmp(varargin{1},'info')
  info.name = mfilename;
  info.title = 'Performance';
  info.type = 'Plot';
  info.version = 6;
  result = info;
  return;
end

%% Plot
if nargin == 1
  % User arguments - New plot
  tr = varargin{1};
  fig = new_figure('');
  update_figure(fig,tr);
else
  % Standard Plotting Function Arguments - Recycle plot
  [net,tr,signals] = deal(varargin{:});
  fig = nn_find_tagged_figure(mfilename);
  if isempty(fig), fig = new_figure(mfilename); end
end
update_figure(fig,tr);
if (nargout > 0), result = fig; end

%% New Figure
function fig = new_figure(tag)

trainColor = [0 0 1];
valColor = [0 0.8 0];
testColor = [1 0 0];
goalColor = [0 0 0];

fig = figure;
ud.trainLine = plot([NaN NaN],[NaN NaN],'b','LineWidth',2,'Color',trainColor);
hold on
ud.valLine = plot([NaN NaN],[NaN NaN],'g','LineWidth',2,'Color',valColor);
ud.testLine = plot([NaN NaN],[NaN NaN],'r','LineWidth',2,'Color',testColor);
ud.bestLine = plot([NaN NaN],[NaN NaN],':','Color',valColor);
ud.bestSpot = plot([NaN NaN],[NaN NaN],'o','Color',valColor,'markersize',16,'linewidth',1.5);
ud.goalLine = plot([NaN NaN],[NaN NaN],':','Color',goalColor);

ud.title = title('Best Performance');
ud.ylabel = ylabel('Performance');
ud.xlabel = xlabel('Epochs');

ud.axis = gca;
set(ud.axis,'yscale','log');

set(fig,'name','Performance (plotperform)');
set(fig,'NumberTitle','off','menubar','none','toolbar','none');
set(fig,'UserData',ud,'tag',tag);
set(fig,'nextplot','new');

%% Update Figure
function update_figure(fig,tr)

set(0,'CurrentFigure',fig);
ud = get(fig,'userdata');

trainColor = [0 0 1];
valColor = [0 0.8 0];

numEpochs = tr.num_epochs;
ind = 1:(numEpochs+1);
goal = tr.goal;
if (goal <= 0), goal = NaN; end
epochs = tr.epoch(ind);
perf = tr.perf(ind);
vperf = tr.vperf(ind);
tperf = tr.tperf(ind);
bestEpoch = tr.best_epoch;
if isnan(vperf(1))
  bestPerf = tperf(bestEpoch+1);
  bestColor = trainColor * 0.6;
  bestMode = 'Training';
else
  bestPerf = vperf(bestEpoch+1);
  bestColor = valColor * 0.6;
  bestMode = 'Validation';
end
xlim = [0 max(1,numEpochs)];
ylim = calculate_y_limit(perf,vperf,tperf,goal);

set(ud.trainLine,'Xdata',epochs,'Ydata',perf);
set(ud.valLine,'Xdata',epochs,'Ydata',vperf);
set(ud.testLine,'Xdata',epochs,'Ydata',tperf);
set(ud.bestLine,'Xdata',[bestEpoch bestEpoch NaN xlim])
set(ud.bestLine,'Ydata',[ylim NaN bestPerf bestPerf]);
set(ud.bestLine,'Color',bestColor);
set(ud.bestSpot,'Xdata',bestEpoch,'Ydata',bestPerf);
set(ud.bestSpot,'Color',bestColor);
set(ud.goalLine,'Xdata',xlim,'Ydata',[goal goal]);

set(ud.axis,'xlim',xlim);
set(ud.axis,'ylim',ylim);

legendLines = [ud.trainLine];
legendNames = {'Train'};
if ~isnan(vperf(1))
  legendLines = [legendLines ud.valLine];
  legendNames = [legendNames 'Validation'];
end
if ~isnan(tperf(1))
  legendLines = [legendLines ud.testLine];
  legendNames = [legendNames 'Test'];
end
legendLines = [legendLines ud.bestLine];
legendNames = [legendNames 'Best'];
if ~isnan(goal)
  legendLines = [legendLines ud.goalLine];
  legendNames = [legendNames 'Goal'];
end
legend(legendLines,legendNames);

performInfo = feval(tr.performFcn,'info');
set(ud.title,'String',['Best ' bestMode ' Performance is ' num2str(bestPerf) ' at epoch ' num2str(bestEpoch)])
set(ud.ylabel,'String',[performInfo.title '  (' performInfo.function ')'])
set(ud.xlabel,'String',[num2str(numEpochs) ' Epochs'])

drawnow

%% Calculate Y Min
function ylim = calculate_y_limit(perf,vperf,tperf,goal)

ymax = max([perf vperf tperf goal]);
ymin = min([perf vperf tperf goal]);
ymax = 10^ceil(log10(ymax));
ymin = 10^fix(log10(ymin)-1);
ylim = [ymin*0.9 ymax*1.1];
