function result = plottrainstate(varargin)
%PLOTTRAINSTATE Plot training state values.
%
%  Syntax
%
%    plottrainstate(tr)
%
%  Description
%
%    PLOTTRAINSTATE(TR) plots the training state from a training record TR
%    returned by TRAIN.
%
%  Example
%
%    load housing
%    net = newff(p,t,20);
%    [net,tr] = train(net,p,t);
%    plottrainstate(tr);
%
% See also plottrainstate

% Copyright 2007-2008 The MathWorks, Inc.

if nargin < 1, error('NNET:Arguments','Not enough input arguments.'); end

%% Info
if (nargin == 1) && strcmp(varargin{1},'info')
  info.name = mfilename;
  info.title = 'Training State';
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

ud.trainFcn = '';

fig = figure;

set(fig,'name','Training State (plottrainstate)');
set(fig,'menubar','none','toolbar','none','NumberTitle','off');
set(fig,'tag',tag,'UserData',ud)

%% Update Figure
function update_figure(fig,tr)

set(0,'CurrentFigure',fig);
ud = get(fig,'userdata');

trainInfo = feval(tr.trainFcn,'info');
numAxes = length(trainInfo.training_states);

if ~strcmp(ud.trainFcn,tr.trainFcn);
  clf(fig);
  ud.trainFcn = tr.trainFcn;
  
  ud.numAxes = numAxes;
  ud.axes = zeros(1,numAxes);
  ud.lines = zeros(1,numAxes);
  ud.titles = zeros(1,numAxes);
  for i=1:numAxes
    state = trainInfo.training_states(i);
    name = state.name;
    name(name == '_') = ' ';
    ud.axes(i) = subplot(numAxes,1,i);
    ud.lines(i) = plot([NaN NaN],[NaN NaN],'linewidth',2,'markerfacecolor',[1 0 0]);
    ylabel(name);
    if (i == numAxes), xlabel('Epochs'); end
    if (i < numAxes), set(gca,'xticklabel',[]); end
    ud.titles(i) = title([state.title ' = ?']);
    hold on
  end
  
  set(fig,'UserData',ud)
  set(fig,'nextplot','new');
end

numEpochs = tr.num_epochs;
len = numEpochs+1;
ind = 1:len;

numAxes = length(trainInfo.training_states);
epochs = tr.epoch(ind);
for i=1:numAxes
  state = trainInfo.training_states(i);
  name = state.name;
  values = tr.(name)(ind);
  
  set(ud.lines(i),'Xdata',epochs,'Ydata',values);
  if strcmp(state.form,'discrete')
    set(ud.lines(i),'marker','diamond','linestyle','none','linewidth',1);
  else
    set(ud.lines(i),'marker','none','linestyle','-','linewidth',2);
  end

  set(ud.axes(i),'xlim',[0 max(numEpochs,1)])
  set(ud.axes(i),'yscale',state.scale);
  set(ud.titles(i),'string',[state.title ' = ' ...
    num2str(values(end)) ', at epoch ' num2str(numEpochs)]);
  
  axis(ud.axes(i));
  if (i == numAxes)
    xlabel([num2str(numEpochs) ' Epochs']);
  else 
    xlabel('');
  end
end

drawnow

%% Update Figure
function clear_figure(fig)

drawnow
