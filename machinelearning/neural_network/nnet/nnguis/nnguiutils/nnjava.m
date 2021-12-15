function result = nnjava(command,varargin)

% Copyright 2007-2008 The MathWorks, Inc.

if nargout > 0, result = []; end

persistent JAVA_TOOLS;
if isempty(JAVA_TOOLS)
  JAVA_TOOLS = javaObjectEDT('com.mathworks.toolbox.nnet.matlab.nnTools');
  mroot = matlabroot;
  nroot = nnetroot;
  try
    sLicense = (license('checkout','simulink') == 1);
  catch
    sLicense = false;
  end
  JAVA_TOOLS.initialize(mroot,nroot,sLicense);
end

try
  numargs = length(varargin);
  switch command

    case 'initialize'
      % Initialization happens above, no need to do more here

  %% CALLS FROM JAVA
    case 'state'
      result = JAVA_TOOLS;
      
    case 'getWorkspaceVariables'
      [names,cTypes,rTypes,sizes] = getWorkspaceVariables();
      result = nnjava('vector');
      addElement(result,names);
      addElement(result,cTypes);
      addElement(result,rTypes);
      addElement(result,sizes);

    case 'loadDataset'
      prefix = varargin{1};
      evalin('base',['load ' prefix '_dataset']);

    case 'get_java_transfer_function'
      tfname = nnjava('string',varargin{1});
      result = JAVA_TOOLS.getTransferFunction(tfname);

    case 'importData'
      name = importData();
      result = nnjava('string',name);

  %% CALLS FROM MATLAB

    case 'nctool'
      result = JAVA_TOOLS.getNCTool;

    case 'nftool'
      result = JAVA_TOOLS.getNFTool;

    case 'nprtool'
      result = JAVA_TOOLS.getNPRTool;

    case 'nntraintool'
      result = JAVA_TOOLS.getNNTrainTool;
      
    case 'nntool'
      result = JAVA_TOOLS.getNNTool;
      
    case 'diagram'
      diagram = JAVA_TOOLS.newDiagram;
      if numargs > 0
        net = struct(varargin{1});

        inputs = cell(1,net.numInputs);
        for i=1:net.numInputs
          inputs{i} = diagram.newInput;
        end
        layers = cell(1,net.numLayers);
        for i=1:net.numLayers
          layers{i} = diagram.newLayer;
          if ~isfield(net.layers{i},'name'), layerName = net.layers{i}.name;
          else layerName = 'Layer'; end
          layers{i}.layerProperties.title.set(layerName);
          if net.biasConnect(i)
            layers{i}.layerProperties.hasBias.set(true);
          end
        end
        outputs = cell(1,net.numOutputs);
        for i=1:net.numOutputs
          outputs{i} = diagram.newOutput;
        end
        weightGroups = cell(1,net.numLayers);
        numWeights = zeros(1,net.numLayers);
        outputIndex = 1;
        for i=1:net.numLayers
          for j=1:net.numInputs
            if net.inputConnect(i,j)
              weightGroup = layers{i}.newWeightGroup;
              weightGroups{i} = [weightGroups{i} {weightGroup}];
              diagram.newInputToLayerConnection(i-1,j-1,numWeights(i));
              numWeights(i) = numWeights(i) + 1;
            end
          end
          for j=1:net.numLayers
            jTransferFunction = nnjava('get_java_transfer_function',net.layers{i}.transferFcn);
            layers{i}.layerProperties.transferFunction.set(jTransferFunction);
            if net.layerConnect(i,j)
              weightGroup = layers{i}.newWeightGroup;
              weightGroups{i} = [weightGroups{i} {weightGroup}];
              diagram.newLayerToLayerConnection(i-1,j-1,numWeights(i));
              numWeights(i) = numWeights(i) + 1;
            end
          end
          if net.outputConnect(i)
            diagram.newLayerToOutputConnection(outputIndex-1,i-1);
            outputIndex = outputIndex + 1;
          end
        end
        diagram.layoutChildren;
      end
      result = diagram;

    case 'view'
      net = struct(varargin{1});
      diagram = nnjava('diagram',net);
      JAVA_TOOLS.newView(diagram);

    case 'error'
      errmsg = varargin{1};
      result = JAVA_TOOLS.newError(errmsg);
      
    case 'string'
      result = javaObjectEDT('java.lang.String',varargin{1});
      
    case 'vector'
      result = javaObjectEDT('java.util.Vector');
      
    case 'double'
      result = javaObjectEDT('java.lang.Double',varargin{1});
      
    case 'true'
      result = javaObjectEDT('java.lang.Boolean',true);
    
    case 'false'
      result = javaObjectEDT('java.lang.Boolean',false);
      
    case 'stringarray'
      result = JAVA_TOOLS.newStringArray(varargin{1});
      
    case 'doublearray'
      result = JAVA_TOOLS.newDoubleArray(varargin{1});
      
    otherwise, error('NNET:Arguments',['Unrecognized command: ' command]);
  end
catch me
  errmsg = me.message;
  errmsg(errmsg<32) = ',';
  errmsg = nnjava('string',errmsg)
  result = JAVA_TOOLS.newError(errmsg);
end

%----------------------------------------------------------
function [names,cTypes,rTypes,sizes] = getWorkspaceVariables()
names = nnjava('vector');
cTypes = nnjava('vector');
rTypes = nnjava('vector');
sizes = nnjava('vector');
variables = evalin('base','who');
for i=1:length(variables)
  name = variables{i};
  if ~strcmp(name,'ans')
    value = evalin('base',name);
    if ~isjava(value)
      cType = nntype(value);
      rType = nntype(value');
      addElement(names,nnjava('string',name));
      addElement(cTypes,nnjava('string',cType));
      addElement(rTypes,nnjava('string',rType));
      addElement(sizes,size(value));
    end
  end
end

%%
function type = nntype(x)

type = '.';
if isa(x,'network') && (numel(x) == 1)
  type = [type 'NETWORK.'];
elseif ~(isnumeric(x) || islogical(x)) || ischar(x)
  % Nothing
elseif (ndims(x) == 2) && ~isempty(x)
  if isnumeric(x) || islogical(x)
    type = [type 'NUMERIC.'];
  end
  if ischar(x), type = [type 'CHAR.']; end
  xsum = sum(x,1);
  if all((xsum==1) | isnan(xsum)) && all(all(((x>=0) & (x<=1)) | isnan(x)))
    type = [type 'NORMALIZED.'];
  end
  if all(all((x == 0) | (x == 1) | isnan(x)))
    type = [type 'LOGICAL.'];
  end
  if all(all((x >= 0) | isnan(x)))
    type = [type 'POSITIVE.'];
  end
else
  type = '?';
end

%%
function name = importData()

name = '';
S = uiimport('-file');
if ~isempty(S)
  names = fields(S);
  for i=1:length(names)
    n = names{i};
    value = S.(n);
    assignin('base',n,value);
    if isempty(name) && (isnumeric(value) || islogical(value))
      name = n;
    end
  end
end

%%

