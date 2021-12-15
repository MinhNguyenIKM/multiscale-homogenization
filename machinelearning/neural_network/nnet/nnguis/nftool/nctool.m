function result = nctool(command,varargin)
%NCTool Neural network classification tool
%  Syntax
%    
%    nctool
%    nctool('close')
%    
%  Description
%    
%    NCTOOL launches the neural network clustering wizard and leads
%    the user through solving a clustering problem using a self-organizing map.
%    The map forms a compressed representation of the inputs space, reflecting
%    both the relative density of input vectors in that space, and a
%    two-dimension compressed representation of the input space topology.
%
%    NCTOOL('close') closes the window.

% Copyright 2007-2008 The MathWorks, Inc.

if nargout > 0, result = []; end

persistent STATE;
if isempty(STATE)
  STATE.tool = nnjava('nctool');
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
      sampleByColumn = varargin{2};
      STATE = cacheData(STATE,inputName,sampleByColumn);

    case 'createNetwork'
      varargin = fill_defaults(varargin,{20});
      s1 = varargin{1};
      STATE = createNetwork(STATE,s1);

    case 'trainNetwork'
      STATE = trainNetwork(STATE);
      result = nnjava('vector');
      
      addElement(result,nnjava('string',sprintf('%f',STATE.rand_seed)));
      addElement(result,nnjava('string',STATE.net2.trainFcn));

    case 'viewTrainPlot'
      plotFunction = varargin{1};
      viewTrainPlot(STATE,plotFunction)
      
    case 'viewTrainSensativities'
      viewTrainSensativities(STATE)
      
    case 'testNetwork'
      data = varargin{1};
      inputName = data.get(0);
      sampleByColumn = varargin{2};
      STATE=testNetwork(STATE,inputName,sampleByColumn);
      result = nnjava('vector');
      
    case 'viewTestPlot'
      plotFunction = varargin{1};
      viewTestPlot(STATE,plotFunction)
      
    case 'viewTestSensativities'
      viewTrainSensativities(STATE)
      
    case 'exportToWorkspace'
      names = varargin{1};
      exportToWorkspace(STATE,names);
      
    case 'generateSimulinkBlock'
      generateSimulinkBlock(STATE);
      
    otherwise
      error('NNET:nctool:Arguments',['Unrecognized command: ' command]);
  end
catch me
  errmsg = me.message;
  errmsg(errmsg<32) = ',';
  errmsg = nnjava('string',errmsg);
  result = nnjava('error',errmsg);
end

%% Cache Data
function STATE = cacheData(STATE,inputName,sampleByColumn)

inputs = evalin('base',inputName);
if ~is_nn_matrix(inputs)
  error('NNET:nctool:Arguments',['Workspace variable "' inputName '" is not a valid nn matrix.'])
end
%targets = evalin('base',targetName);
%if ~is_nn_matrix(targets)
%  error('NNET:nctool:Arguments',['Workspace variable "' targetName '" is not a valid nn matrix.'])
%end
if (~sampleByColumn)
  inputs = inputs';
%  targets = targets';
end

STATE.inputName = inputName;
%STATE.targetName = targetName;
STATE.sampleByColumn = sampleByColumn;
STATE.inputs = inputs;
%STATE.targets = targets;

%% Create Network
function STATE = createNetwork(STATE,s1);

net1 = newsom(STATE.inputs,[s1 s1]);
STATE.net1 = net1;

%% Train Network

function STATE = trainNetwork(STATE)

% Data
P = STATE.inputs;

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
net2 = train(STATE.net1,P);

drawnow
STATE.net2 = net2;

% indices and performance data
STATE.net2 = net2;

%[Y1,Pf,Af,E,info.train.performance] = sim(net2,P(:,tr.trainInd),[],[],T(:,tr.trainInd));
%[Y2,Pf,Af,E,info.validation.performance] = sim(net2,P(:,tr.valInd),[],[],T(:,tr.valInd));
%[Y3,Pf,Af,E,info.test.performance] = sim(net2,P(:,tr.testInd),[],[],T(:,tr.testInd));

%[m,b,info.train.regression] = postreg(Y1,T(:,tr.trainInd),'hide');
%[m,b,info.validation.regression] = postreg(Y2,T(:,tr.valInd),'hide');
%[m,b,info.test.regression] = postreg(Y3,T(:,tr.testInd),'hide');
%STATE.info = info;

% Outputs and Errors
Y = sim(net2,P);
STATE.outputs = Y;

%%
function viewTrainPlot(STATE,plotFunction)

switch plotFunction
  
  case 'plotsomnd'
    plotsomnd(STATE.net2);

  case 'plotsomplanes'
    plotsomplanes(STATE.net2);
    
  case 'plotsomhits'
    plotsomhits(STATE.net2,STATE.inputs);
    
  case 'plotsompos'
    plotsompos(STATE.net2,STATE.inputs);
  
end
drawnow

%%
function STATE = testNetwork(STATE,inputName,sampleByColumn)

STATE.optionalTest.performance = -1;
STATE.optionalTest.regression = -1;

x = evalin('base',inputName);
if ~is_nn_matrix(x)
  error('NNET:nctool:Arguments',['Workspace variable "' inputName '" is not a valid nn matrix.'])
end
if (~sampleByColumn)
  x = x';
end

STATE.optionalTest.inputs = x;
STATE.optionalTest.inputName = inputName;

STATE.optionalTest.outputs= sim(STATE.net2,x);

%%
function viewTestPlot(STATE,plotFunction)

switch plotFunction
  
  case 'plotsomnd'
    plotsomnd(STATE.net2);

  case 'plotsomplanes'
    plotsomplanes(STATE.net2);
    
  case 'plotsomhits'
    plotsomhits(STATE.net2,STATE.optionalTest.inputs);
    
  case 'plotsompos'
    plotsompos(STATE.net2,STATE.optionalTest.inputs);
  
end
drawnow

%%
function exportToWorkspace(STATE,names)

networkName = names{1};
outputName = names{2};
inputName = names{3};
structName = names{4};

if isempty(structName)
  if ~isempty(networkName),assignin('base',networkName,STATE.net2); end
  if ~isempty(outputName), assignin('base',outputName,STATE.outputs); end
  if ~isempty(inputName), assignin('base',inputName,STATE.inputs); end
else
  s = struct;
  if ~isempty(networkName), s.(networkName) = STATE.net2; end
  if ~isempty(outputName), s.(outputName) = STATE.outputs; end
  if ~isempty(inputName), s.(inputName) = STATE.inputs; end
  assignin('base',structName,s);
end

%%
function generateSimulinkBlock(STATE)

gensim(STATE.net2)
