function x = nftool_v51(command,varargin)
%NFTOOL_v51 Neural Network Fitting Tool version 5.1

% Copyright 2005-2008 The MathWorks, Inc.

if nargout > 0
  x = [];
end

% Check that the Neural Network Toolbox is installed
if ~license('test', 'Neural_Network_Toolbox')
  error('nnet:nftool:noLicense',...
    'The use of the function NFTool requires the Neural Network Toolbox.');
end

% NFTool Data
persistent nftooldata;

% Can't proceed unless we have desktop java support
if ~usejava('swing')
  error('nnet:nftool:missingJavaSwing',...
    'Cannot use nftool unless you have Java and Swing available.');
end

% No command and arguments -> Launch Tool
if nargin == 0
  nnjava('initialize');
  nftool_handle = com.mathworks.toolbox.nnet.nftool.NFTool.launchInstance;
  if nargout == 1, x = nftool_handle; end
  return
end

if ~ischar(command)
  error('NNET:Arguments','Callback command is not a string.');
end

% Command -> Callback functions
% Perform all required Java<-->Matlab conversions here.
switch(command)
  
  case 'state'
    x = nftooldata;
    
  case 'fixSeed'
    nftooldata.fix_seed = varargin{1};
    
  case 'getWorkspaceVariables'
    x = getWorkspaceVariables();
    
  case 'getWorkspaceDataVariables'
    [names,sizes] = getWorkspaceDataVariables();
    x = java.util.Vector();
    addElement(x,names);
    addElement(x,sizes);
    
  case 'importData'
    [names,sizes,name] = importData();
    x = java.util.Vector();
    if ~isempty(names)
      addElement(x,names);
      addElement(x,sizes);
      addElement(x,name);
    end
    
  case 'cacheData'
    inputName = ['' varargin{1} ''];
    targetName = ['' varargin{2} ''];
    inputTranspose = varargin{3};
    targetTranspose = varargin{4};
    nftooldata=cacheData(nftooldata,inputName,targetName,inputTranspose,targetTranspose);
    
  case 'createNetwork'
    if length(varargin) >= 1
      s1 = varargin{1};
    else
      s1 = 20;
    end
    nftooldata = createNetwork(nftooldata,s1);
    
  case 'trainNetwork'
    if length(varargin) >= 1
      percentValidate = varargin{1};
    else
      percentValidate = 20;
    end
    if length(varargin) >= 2
      percentTest = varargin{2};
    else
      percentTest = 20;
    end
    nftooldata = trainNetwork(nftooldata,percentValidate,percentTest);
    x = java.util.Vector;
    addElement(x,java.lang.Double(nftooldata.info.train.performance));
    addElement(x,java.lang.Double(nftooldata.info.validation.performance));
    addElement(x,java.lang.Double(nftooldata.info.test.performance));
    addElement(x,java.lang.Double(nftooldata.info.train.regression));
    addElement(x,java.lang.Double(nftooldata.info.validation.regression));
    addElement(x,java.lang.Double(nftooldata.info.test.regression));
    addElement(x,java.lang.String(sprintf('%f',nftooldata.rand_seed)));
    addElement(x,java.lang.String(nftooldata.net2.trainFcn));
    
  case 'showTrainRegression'
    showTrainRegression(nftooldata)
    
  case 'testNetwork'
    inputName = ['' varargin{1} ''];
    targetName = ['' varargin{2} ''];
    inputTranspose = varargin{3};
    targetTranspose = varargin{4};
    nftooldata=testNetwork(nftooldata,inputName,targetName,inputTranspose,targetTranspose);
    x = java.util.Vector;
    addElement(x,java.lang.Double(nftooldata.optionalTest.performance));
    addElement(x,java.lang.Double(nftooldata.optionalTest.regression));
    
  case 'showTestRegression'
    showTestRegression(nftooldata)
    
  case 'exportData'
    names = varargin{1};
    exportData(nftooldata,names)
    
  otherwise, error('NNET:Arguments',['Unrecognized call back: ' command]);
end

%==========================================================
%                     CALLBACK FUNCTIONS
%----------------------------------------------------------
function names = getWorkspaceVariables()
names = java.util.Vector;
variables = evalin('base','who');
for i=1:length(variables)
  name = variables{i};
  addElement(names,java.lang.String(name));
end
%----------------------------------------------------------
function [names,sizes] = getWorkspaceDataVariables()
names = java.util.Vector;
sizes = java.util.Vector;
variables = evalin('base','who');
for i=1:length(variables)
  name = variables{i};
  if ~strcmp(name,'ans')
    value = evalin('base',name);
    if isMatrixNNData(value)
      addElement(names,java.lang.String(name));
      addElement(sizes,size(value));
    end
  end
end
%----------------------------------------------------------
function nftooldata = cacheData(nftooldata,inputName,targetName,inputTranspose,targetTranspose)

try
  x = evalin('base',inputName);
  if ~isMatrixNNData(x), x = []; end
catch
  x = [];
end
if (inputTranspose), x = x'; end
nftooldata.input = x;
nftooldata.inputName = inputName;

try
  t = evalin('base',targetName);
  if ~isMatrixNNData(t), t = []; end
catch
  t = [];
end
if (targetTranspose), t = t'; end
nftooldata.target = t;
nftooldata.targetName = targetName;
%----------------------------------------------------------
function [names,sizes,name]=importData()

name = '';
S = uiimport;
if isempty(S)
  names = [];
  sizes = [];
  name = [];
  return
end
names = fields(S);
for i=1:length(names)
  n = names{i};
  value = S.(n);
  if strcmp(name,'') && isMatrixNNData(value)
    name = n;
  end
  assignin('base',n,value);
end
[names,sizes]=getWorkspaceDataVariables();
%----------------------------------------------------------
function nftooldata = createNetwork(nftooldata,s1)

% Create Network
nftooldata.net1 = newff(nftooldata.input,nftooldata.target,s1);
%----------------------------------------------------------
function nftooldata = trainNetwork(nftooldata,percentValidate,percentTest)

% Data
P = nftooldata.input;
T = nftooldata.target;

% Data division parameters
nftooldata.net1.divideParam.trainRatio = (100-percentValidate-percentTest)/100;
nftooldata.net1.divideParam.valRatio = percentValidate/100;
nftooldata.net1.divideParam.testRatio = percentTest/100;

% Record random seed so it can be reproduced in exported scripts
if isfield(nftooldata,'fix_seed')
  nftooldata.rand_seed = nftooldata.fix_seed;
  rand('seed',nftooldata.fix_seed);
else
  nftooldata.rand_seed = rand('seed');
  rand('seed',nftooldata.rand_seed);
end
nftooldata.net1 = init(nftooldata.net1);

% Trained network
try
  % Try with TRAINLM, if memory requirements allow
  nftooldata.net1.trainFcn = 'trainlm';
  [net2,tr] = train(nftooldata.net1,P,T);
catch
  try
    % Try TRAINSCG if TRAINLM failed
    nftooldata.net1.trainFcn = 'trainscg';
    [net2,tr] = train(nftooldata.net1,P,T);
  catch
    % Return the untrained network if both training methods fail
    % This condition should not occur but is included for safety
    nftooldata.net1.trainFcn = '';
    net2 = nftooldata.net1;
    tr.trainInd = [];
    tr.valInd = [];
    tr.testInd = [];
  end
end


drawnow
nftooldata.net2 = net2;

% indices and performance data
info=[];
info.train.indices = tr.trainInd;
info.validation.indices = tr.valInd;
info.test.indices = tr.testInd;
nftooldata.net2 = net2;

[Y1,Pf,Af,E,info.train.performance] = sim(net2,P(:,tr.trainInd),[],[],T(:,tr.trainInd));
[Y2,Pf,Af,E,info.validation.performance] = sim(net2,P(:,tr.valInd),[],[],T(:,tr.valInd));
[Y3,Pf,Af,E,info.test.performance] = sim(net2,P(:,tr.testInd),[],[],T(:,tr.testInd));

[m,b,info.train.regression] = postreg(Y1,nftooldata.target(:,tr.trainInd),'hide');
[m,b,info.validation.regression] = postreg(Y2,nftooldata.target(:,tr.valInd),'hide');
[m,b,info.test.regression] = postreg(Y3,nftooldata.target(:,tr.testInd),'hide');
nftooldata.info = info;

% Outputs and Errors
Y = sim(net2,P,[],[],T);
nftooldata.output = Y;
nftooldata.error = nftooldata.target-Y;
%----------------------------------------------------------
function showTrainRegression(nftooldata)

figure

train_i = nftooldata.info.train.indices;
train_t = nftooldata.target(train_i);
train_a = nftooldata.output(train_i);

val_i = nftooldata.info.validation.indices;
val_t = nftooldata.target(val_i);
val_a = nftooldata.output(val_i);

test_i = nftooldata.info.test.indices;
test_t = nftooldata.target(test_i);
test_a = nftooldata.output(test_i);

postreg({train_a,val_a,test_a},{train_t,val_t,test_t});
set(gcf,'name','Regression Analysis of Outputs and Targets')
drawnow
%----------------------------------------------------------
function nftooldata = testNetwork(nftooldata,inputName,targetName, ...
  inputTranspose,targetTranspose)

nftooldata.optionalTest.performance = -1;
nftooldata.optionalTest.regression = -1;

try
  x = evalin('base',inputName);
  if ~isMatrixNNData(x), x = []; end
catch
  x = [];
end
if (inputTranspose), x = x'; end
nftooldata.optionalTest.input = x;
nftooldata.optionalTest.inputName = inputName;

if (isempty(x)), return; end
  
try
  t = evalin('base',targetName);
  if ~isMatrixNNData(t),t = []; end
catch
  t = [];
end
if (targetTranspose), t = t'; end
nftooldata.optionalTest.target = t;
nftooldata.optionalTest.targetName = targetName;

if (isempty(t)), return; end

[nftooldata.optionalTest.output,Pf,Af,E,nftooldata.optionalTest.performance] = ...
  sim(nftooldata.net2,x,[],[],t);
[m,b,nftooldata.optionalTest.regression] = postreg(nftooldata.optionalTest.output,t,'hide');

%----------------------------------------------------------
function showTestRegression(nftooldata)

figure
postreg(nftooldata.optionalTest.output,nftooldata.optionalTest.target);
set(gcf,'name','Regression Analysis of Outputs and Targets')
drawnow
%----------------------------------------------------------
function exportData(nftooldata,names)

networkName = names{1};
perfName = names{2};
outputName = names{3};
errorName = names{4};
inputName = names{5};
targetName = names{6};
structName = names{7};

if isempty(structName)
  if ~isempty(networkName),assignin('base',networkName,nftooldata.net2); end
  if ~isempty(perfName), assignin('base',perfName,nftooldata.info); end
  if ~isempty(outputName), assignin('base',outputName,nftooldata.output); end
  if ~isempty(errorName), assignin('base',errorName,nftooldata.error); end
  if ~isempty(inputName), assignin('base',inputName,nftooldata.input); end
  if ~isempty(targetName), assignin('base',targetName,nftooldata.target); end
else
  s = struct;
  if ~isempty(networkName), s.(networkName) = nftooldata.net2; end
  if ~isempty(perfName), s.(perfName) = nftooldata.info; end
  if ~isempty(outputName), s.(outputName) = nftooldata.output; end
  if ~isempty(errorName), s.(errorName) = nftooldata.error; end
  if ~isempty(inputName), s.(inputName) = nftooldata.input; end
  if ~isempty(targetName), s.(targetName) = nftooldata.target; end
  assignin('base',structName,s);
end

%==========================================================
%                     UTILITY FUNCTIONS
%----------------------------------------------------------
function f=isMatrixNNData(x)
% Checks that x is a real double 2D matrix.

f = isa(x,'double') && isreal(x) && (ndims(x) <= 2) && (numel(x) > 1) && all(all(isfinite(x)));
%----------------------------------------------------------
