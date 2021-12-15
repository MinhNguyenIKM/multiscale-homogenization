function [result,result2] = nntraintool(command,varargin)
%NNTRAINTOOL Neural network training tool
%
%  Syntax
%
%    nntraintool
%    nntraintool('close')
%
%  Description
%
%    NNTRAINTOOL opens the training window GUI. This is launched
%    automatically when TRAIN is called.
%
%    To disable the training window set the following network training
%    property.
%
%      net.trainParam.showWindow = false;
%
%    To enable command line training instead.
%
%      net.trainParam.showCommandLine = true;
%
%    NNTRAINTOOL('close') closes the window.

% Copyright 2007-2008 The MathWorks, Inc.

if nargin == 0, command = 'select'; end

if nargin > 0, result = []; end
if nargin > 2, result2 = []; end

persistent net;
persistent tr;
persistent signals;

persistent trainTool;
if isempty(trainTool)
  if usejava('swing')
    trainTool = nnjava('nntraintool');
    pause(0.2);
  else
    trainTool = [];
  end
end

switch command
  
  case {'handle','tool'}
    result = trainTool;
  
  case 'ignore'
  
  case 'show'
    if usejava('swing')
      trainTool.setVisible(true);
    end
    
  case {'hide','close'}
    if usejava('swing')
      trainTool.setVisible(false);
    end
    
  case 'select'
    if usejava('swing')
      trainTool.setVisible(true);
      toFront(trainTool);
    end
  
  case 'set'
    [net,tr,signals] = varargin{:};
    net = network(net);
    
  case 'get'
    result = {net tr signals};
    
  case 'start'
    if usejava('swing')
      [net,algorithmNames,status] = varargin{:};
      start(trainTool,net,algorithmNames,status);
    end
    
  case 'check'
    if usejava('swing')
      result = trainTool.isStopped;
      result2 = trainTool.isCancelled;
    else
      result = false;
      result2 = false;
    end
    
  case 'update'
    if usejava('swing')
      [net,tr,signals,statusValues] = varargin{:};
      net = network(net);
      trainTool.updateStatus(doubleArray2JavaArray(statusValues));

      epoch = tr.num_epochs;
      plotDelay = trainTool.getPlotDelay;
      refresh = ((~rem(epoch,plotDelay) || ~isempty(tr.stop)));
      if refresh, refresh_open_plots(trainTool,net,tr,signals); end
      if ~isempty(tr.stop)
        done(trainTool,tr.stop);
      end
    end
    
  case 'plot'
    if ~isempty(net)
      plotFcn = varargin{1};
      fig = feval(plotFcn,net,tr,signals);
      figure(fig);
    end
    
  otherwise, error('NNET:Arguments','Unrecognized command.');
end

%%
function start(trainTool,net,algorithmNames,status)

diagram = nnjava('diagram',net);
    
numAlgorithms = length(algorithmNames);
emptyNames = false(1,numAlgorithms);
for i=1:numAlgorithms, emptyNames(i) = isempty(algorithmNames{i}); end
algorithmNames = algorithmNames(~emptyNames);
numAlgorithms = length(algorithmNames);

algorithmTypes = cell(1,length(algorithmNames));
algorithmTitles = cell(1,length(algorithmNames));
for i=1:numAlgorithms
 info = feval(algorithmNames{i},'info');
 algorithmTypes{i} = info.type;
 algorithmTitles{i} = info.title;
end

plotNames = net.plotFcns;
numPlots = length(plotNames);
plotTitles = cell(1,numPlots);
for i=1:numPlots
  info = feval(plotNames{i},'info');
  plotTitles{i} = info.title;
end

x1 = diagram;
x2 = stringCellArray2JavaArray(algorithmTypes);
x3 = stringCellArray2JavaArray(algorithmNames);
x4 = stringCellArray2JavaArray(algorithmTitles);
x5 = stringCellArray2JavaArray({status(:).name});
x6 = stringCellArray2JavaArray({status(:).units});
x7 = stringCellArray2JavaArray({status(:).scale});
x8 = stringCellArray2JavaArray({status(:).form});
x9 = doubleArray2JavaArray([status(:).min]);
x10 = doubleArray2JavaArray([status(:).max]);
x11 = doubleArray2JavaArray([status(:).value]);
x12 = stringCellArray2JavaArray(plotNames);
x13 = stringCellArray2JavaArray(plotTitles);
  
trainTool.launch(x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13);
pause(0.25);

%%
function refresh_open_plots(trainTool,net,tr,signals)

for i=1:length(net.plotFcns)
  plotFcn = net.plotFcns{i};
  userSelected = getPlotFlag(trainTool,i-1);
  fig = find_tagged_figure(plotFcn);
  if userSelected || ~isempty(fig), fig = feval(plotFcn,net,tr,signals); end
  if userSelected, figure(fig); end
end

%%
function fig = find_tagged_figure(tag)

for object = get(0,'children')'
  if strcmp(get(object,'type'),'figure') 
    if strcmp(get(object,'tag'),tag)
     fig = object;
     return
   end
  end
end
fig = [];

%%
function y = stringCellArray2JavaArray(x)

count = length(x);
y = nnjava('stringarray',count);
for i=1:count, y(i) = nnjava('string',x{i}); end

%%
function y = doubleArray2JavaArray(x)

count = length(x);
y = nnjava('doublearray',count);
for i=1:count, y(i) = nnjava('double',x(i)); end
