function result = nprtool(command,varargin)
%NPRTool Neural network pattern recognition tool
%
%  Syntax
%
%    nprtool
%    nprtool('close')
%
%  Description
%
%    NPRTOOL launches a neural network pattern recognition wizard and
%    leads the user through solving a pattern recognition
%    classification problem using a two-layer feed-forward network
%    with sigmoid output neurons.
%
%    NPRTOOL('close') closes the window.

% Copyright 2007-2008 The MathWorks, Inc.

if nargout > 0, result = []; end

persistent STATE;
if isempty(STATE)
  STATE.tool = nnjava('nprtool');
end
  
try
  if (nargout > 0), result = []; end
  if nargin == 0, command = 'select'; end
  switch command

    case {'handle','tool'}
      if nargout > 0
        result = STATE.tool;
      end

    case 'select',
      launch(STATE.tool);
      if nargout > 0
        result = STATE.tool;
      end
      
    case {'hide','close'}
      if usejava('swing')
        STATE.tool.setVisible(false);
      end

    case 'state', result = STATE;

    case 'cacheData'
      data = varargin{1};
      inputName = data.get(0);
      targetName = data.get(1);
      sampleByColumn = varargin{2};
      STATE = cacheData(STATE,inputName,targetName,sampleByColumn);

    case 'createNetwork'
      varargin = fill_defaults(varargin,{20});
      s1 = varargin{1};
      STATE = createNetwork(STATE,s1);

    case 'trainNetwork'
      varargin = fill_defaults(varargin,{20 20});
      percentValidate = varargin{1};
      percentTest = varargin{2};
      STATE = trainNetwork(STATE,percentValidate,percentTest);
      result = nnjava('vector');
      addElement(result,nnjava('double',STATE.info.train.performance));
      addElement(result,nnjava('double',STATE.info.validation.performance));
      addElement(result,nnjava('double',STATE.info.test.performance));
      addElement(result,nnjava('double',STATE.info.train.confusion*100));
      addElement(result,nnjava('double',STATE.info.validation.confusion*100));
      addElement(result,nnjava('double',STATE.info.test.confusion*100));
      addElement(result,nnjava('string',sprintf('%f',STATE.rand_seed)));
      
    case 'viewTrainPlot'
      plotFunction = varargin{1};
      viewTrainPlot(STATE,plotFunction)
      
    case 'testNetwork'
      data = varargin{1};
      inputName = data.get(0);
      targetName = data.get(1);
      sampleByColumn = varargin{2};
      STATE = testNetwork(STATE,inputName,targetName,sampleByColumn);
      result = nnjava('vector');
      addElement(result,nnjava('double',STATE.optionalTest.performance));
      addElement(result,nnjava('double',STATE.optionalTest.confusion*100));

    case 'viewTestPlot'
      plotFunction = varargin{1};
      viewTestPlot(STATE,plotFunction)
      
    case 'exportToWorkspace'
      names = varargin{1};
      exportToWorkspace(STATE,names);
      
    case 'generateSimulinkBlock'
      generateSimulinkBlock(STATE);
      
    otherwise
      error('NNET:nprtool:Arguments',['Unrecognized command: ' command]);
  end
catch me
  errmsg = me.message;
  errmsg(errmsg<32) = ',';
  errmsg = nnjava('string',errmsg);
  result = nnjava('error',errmsg);
end

%%
function STATE = cacheData(STATE,inputName,targetName,sampleByColumn)

inputs = evalin('base',inputName);
if ~is_nn_matrix(inputs)
  error('NNET:nprtool:Arguments',['Workspace variable "' inputName '" is not a valid nn matrix.'])
end
targets = evalin('base',targetName);
if ~is_nn_matrix(targets)
  error('NNET:nprtool:Arguments',['Workspace variable "' targetName '" is not a valid nn matrix.'])
end
if (~sampleByColumn)
  inputs = inputs';
  targets = targets';
end

STATE.inputName = inputName;
STATE.targetName = targetName;
STATE.sampleByColumn = sampleByColumn;
STATE.inputs = inputs;
STATE.targets = targets;

%%
function STATE = createNetwork(STATE,s1);

net1 = newpr(STATE.inputs,STATE.targets,s1);
STATE.net1 = net1;

%%
function STATE = trainNetwork(STATE,percentValidate,percentTest)

% Data
P = STATE.inputs;
T = STATE.targets;

% Data division parameters
STATE.net1.divideParam.trainRatio = (100-percentValidate-percentTest)/100;
STATE.net1.divideParam.valRatio = percentValidate/100;
STATE.net1.divideParam.testRatio = percentTest/100;

% Record random seed so it can be reproduced in exported scripts
if isfield(STATE,'fix_seed')
  STATE.rand_seed = STATE.fix_seed;
  %rand('seed',STATE.fix_seed);
else
  STATE.rand_seed = pi; %rand('seed');
  %rand('seed',STATE.rand_seed);
end
STATE.net1 = init(STATE.net1);

% Trained network
[net2,tr] = train(STATE.net1,P,T); %Y=sim(net2,P); plotconfusion(T,Y);
STATE.net2 = net2;

% indices and performance data
info=[];
info.train.indices = tr.trainInd;
info.validation.indices = tr.valInd;
info.test.indices = tr.testInd;

[Y1,Pf,Af,E,info.train.performance] = sim(net2,P(:,tr.trainInd),[],[],T(:,tr.trainInd));
[Y2,Pf,Af,E,info.validation.performance] = sim(net2,P(:,tr.valInd),[],[],T(:,tr.valInd));
[Y3,Pf,Af,E,info.test.performance] = sim(net2,P(:,tr.testInd),[],[],T(:,tr.testInd));

info.train.confusion = confusion(T(:,tr.trainInd),Y1);
info.validation.confusion = confusion(T(:,tr.valInd),Y2);
info.test.confusion = confusion(T(:,tr.testInd),Y3);
STATE.info = info;

% Outputs and Errors
Y = sim(net2,P,[],[],T);
STATE.outputs = Y;
STATE.errors = T-Y;

%%
function viewTrainPlot(STATE,plotFunction)

switch plotFunction
  case 'plotconfusion'
    i1 = STATE.info.train.indices;
    t1 = STATE.targets(:,i1);
    y1 = STATE.outputs(:,i1);
    i2 = STATE.info.validation.indices;
    t2 = STATE.targets(:,i2);
    y2 = STATE.outputs(:,i2);
    i3 = STATE.info.test.indices;
    t3 = STATE.targets(:,i3);
    y3 = STATE.outputs(:,i3);
    t4 = [t1 t2 t3];
    y4 = [y1 y2 y3];
    plotconfusion(t1,y1,'Training',t2,y2,'Validation',t3,y3,'Test',t4,y4,'All');
    
  case 'plotroc'
    i1 = STATE.info.train.indices;
    t1 = STATE.targets(:,i1);
    y1 = STATE.outputs(:,i1);
    i2 = STATE.info.validation.indices;
    t2 = STATE.targets(:,i2);
    y2 = STATE.outputs(:,i2);
    i3 = STATE.info.test.indices;
    t3 = STATE.targets(:,i3);
    y3 = STATE.outputs(:,i3);
    t4 = [t1 t2 t3];
    y4 = [y1 y2 y3];
    plotroc(t1,y1,'Training',t2,y2,'Validation',t3,y3,'Test',t4,y4,'All');
end
drawnow

%%
function STATE = testNetwork(STATE,inputName,targetName,sampleByColumn)

STATE.optionalTest.performance = -1;
STATE.optionalTest.regression = -1;

x = evalin('base',inputName);
if ~is_nn_matrix(x)
  error('NNET:nprtool:Arguments',['Workspace variable "' inputName '" is not a valid nn matrix.'])
end
t = evalin('base',targetName);
if ~is_nn_matrix(t)
  error('NNET:nprtool:Arguments',['Workspace variable "' targetName '" is not a valid nn matrix.'])
end
if (~sampleByColumn)
  x = x';
  t = t';
end

STATE.optionalTest.inputs = x;
STATE.optionalTest.inputName = inputName;
STATE.optionalTest.targets = t;
STATE.optionalTest.targetName = targetName;

[STATE.optionalTest.outputs,Pf,Af,E,STATE.optionalTest.performance] = ...
  sim(STATE.net2,x,[],[],t);
STATE.optionalTest.confusion = confusion(t,STATE.optionalTest.outputs);

%%
function viewTestPlot(STATE,plotFunction)

switch plotFunction
  case 'plotconfusion'
    plotconfusion(STATE.optionalTest.targets,STATE.optionalTest.outputs);
    
  case 'plotroc'
    plotroc(STATE.optionalTest.targets,STATE.optionalTest.outputs)
end
drawnow

%%
function exportToWorkspace(STATE,names)

networkName = names{1};
perfName = names{2};
outputName = names{3};
errorName = names{4};
inputName = names{5};
targetName = names{6};
structName = names{7};

if isempty(structName)
  if ~isempty(networkName),assignin('base',networkName,STATE.net2); end
  if ~isempty(perfName), assignin('base',perfName,STATE.info); end
  if ~isempty(outputName), assignin('base',outputName,STATE.outputs); end
  if ~isempty(errorName), assignin('base',errorName,STATE.errors); end
  if ~isempty(inputName), assignin('base',inputName,STATE.inputs); end
  if ~isempty(targetName), assignin('base',targetName,STATE.targets); end
else
  s = struct;
  if ~isempty(networkName), s.(networkName) = STATE.net2; end
  if ~isempty(perfName), s.(perfName) = STATE.info; end
  if ~isempty(outputName), s.(outputName) = STATE.outputs; end
  if ~isempty(errorName), s.(errorName) = STATE.errors; end
  if ~isempty(inputName), s.(inputName) = STATE.inputs; end
  if ~isempty(targetName), s.(targetName) = STATE.targets; end
  assignin('base',structName,s);
end

%%
function generateSimulinkBlock(STATE)

gensim(STATE.net2)
