function result = nntool(event)
%NNTOOL Neural Network Toolbox graphical user interface.
%
%  Syntax
%
%    nntool
%
%  Description
%
%    NNTOOL opens the Network/Data Manager window which allows
%    you to import, create, use, and export neural networks
%    and data.

% Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.1.6.12 $  $Date: 2008/06/20 08:04:55 $

if nargout > 0, result = []; end

% Constants
MAX_ELEMENTS_IN_MATRIX_STRINGS = 1000;

% NNTool Data
persistent nntooldata;

% Setup State
if (isempty(nntooldata))
  emptyDef.names = {};
  emptyDef.values = {};
  nntooldata.network = emptyDef;
  nntooldata.input = emptyDef;
  nntooldata.target = emptyDef;
  nntooldata.inputstate = emptyDef;
  nntooldata.layerstate = emptyDef;
  nntooldata.output = emptyDef;
  nntooldata.error = emptyDef;
  nntooldata.tool = nnjava('nntool');
elseif ~nntooldata.tool.isVisible
  % Clear State if NNTool has been closed
  emptyDef.names = {};
  emptyDef.values = {};
  nntooldata.network = emptyDef;
  nntooldata.input = emptyDef;
  nntooldata.target = emptyDef;
  nntooldata.inputstate = emptyDef;
  nntooldata.layerstate = emptyDef;
  nntooldata.output = emptyDef;
  nntooldata.error = emptyDef;
end

% Can't proceed unless we have desktop java support
if ~usejava('swing')
  error('nnet:nntool:missingJavaSwing',...
    'Cannot use nntool unless you have Java and Swing available.');
end

% Launch NNTool
if nargin == 0
  nntooldata.tool.launch;
  if nargout > 0, result = nntooldata.tool; end
  return
end

% State
if ischar(event), result = nntooldata; return; end
  
% Event Type
eventType = substring(elementAt(event,0),0);
switch eventType
  case 'nop'
    % No Operation
    
  case 'clearState'
    nntooldata = [];
    
  case 'checkvalue'
    try
      name = substring(elementAt(event,1),0);
      valueString = substring(elementAt(event,2),0);
      returnVector = elementAt(event,3);

      err = 0;
      if ischar(valueString)
        valueString = nnjava('string',valueString);
      end
      if (valueString.equals('<NO_INPUT>'))
        err = 1;
      elseif (valueString.equals('<NO_TARGET>'))
        err = 1;
      elseif (valueString.startsWith('INPUT:'))
        err = 0;
      elseif (valueString.startsWith('TARGET:'))
        err = 0;
      else
        try
          value = eval(valueString);
        catch
          err=1;
        end
        if (err)
          err = ~exist(valueString);
        end
      end
      if (err)
        mstring = [name ' is not a legal value.'];
        jstring = nnjava('string',mstring);
        addElement(returnVector,jstring);
      end
    catch me
      error_message = 'Error in nntool:checkvalue';
      last_error = me;
      save error_file error_message last_error
    end
    
  case 'getweightnames'
    networkName = substring(elementAt(event,1),0);
    net = getValue(nntooldata,networkName);
    weightNames = elementAt(event,2);
    numInputs = net.numInputs;
    numLayers = net.numLayers;
    for j=1:numInputs
        for i=1:numLayers
            if net.inputConnect(i,j)
                weightName = sprintf('iw{%g,%g} - Weight to layer %g from input %g',i,j,i,j);
                jstring = nnjava('string',weightName);
                addElement(weightNames,jstring);
            end
        end
    end
    for j=1:numLayers
        for i=1:numLayers
            if net.layerConnect(i,j)
                weightName = sprintf('lw{%g,%g} - Weight to layer %g from layer %g',i,j);
                jstring = nnjava('string',weightName);
                addElement(weightNames,jstring);
            end
        end
    end
    for i=1:numLayers
        if net.biasConnect(i)
            weightName = sprintf('b{%g} - Bias to layer %g',i,i);
            jstring = nnjava('string',weightName);
            addElement(weightNames,jstring);
        end
    end
    
  case 'getweightvalue'
    networkName = substring(elementAt(event,1),0);
    net = getValue(nntooldata,networkName);
    weightName = substring(elementAt(event,2),0);
    weightName = weightName(1:findstr(weightName,'}'));
    returnVector = elementAt(event,3);
    weightValue = eval(['net.' weightName]);
    if numel(weightValue) <= MAX_ELEMENTS_IN_MATRIX_STRINGS
      mstring = nnmat2string(weightValue);
    else
      mstring = '?';
    end
    jstring = nnjava('string',mstring);
    addElement(returnVector,jstring);
    
case 'checkweightvalue'
    networkName = substring(elementAt(event,1),0);
    net = getValue(nntooldata,networkName);
    weightName = substring(elementAt(event,2),0);
    weightName = weightName(1:findstr(weightName,'}'));
    weightValue = substring(elementAt(event,3),0);
    returnVector = elementAt(event,4);
    
    eval(['oldweight=net.' weightName ';']);
    [S,R] = size(oldweight);
    
    err = 0;
    range = [];
    try
      eval(['weight=' weightValue ';']);
    catch
      err = 1;
    end
    if (err)
        addElement(returnVector,nnjava('string','Value is not a legal matrix.'));
    elseif ~isa(weight,'double')
        addElement(returnVector,nnjava('string','Value is not a matrix.'));
    elseif size(weight,1) ~= S
        addElement(returnVector,nnjava('string',['Value does not have ' num2str(S) ' rows.']));
    elseif size(weight,2) ~= R
        addElement(returnVector,nnjava('string',['Value does not have ' num2str(R) ' columns.']));
    end
    
case 'setweightvalue'
    networkName = substring(elementAt(event,1),0);
    net = getValue(nntooldata,networkName);
    weightName = substring(elementAt(event,2),0);
    weightName = weightName(1:findstr(weightName,'}'));
    weightValue = substring(elementAt(event,3),0);
    eval(['net.' weightName '=' weightValue ';']);
    nntooldata = setValue(nntooldata,networkName,net);
    
case 'getinputranges'
    networkName = substring(elementAt(event,1),0);
    net = getValue(nntooldata,networkName);
    returnVector = elementAt(event,2);
    rangesValue = net.inputs{1}.range;
    if (numel(rangesValue) <= MAX_ELEMENTS_IN_MATRIX_STRINGS)
      mstring = nnmat2string(rangesValue);
    else
      mstring = '?';
    end
    addElement(returnVector,nnjava('string',mstring));
    
case 'checkinputranges'
    
    networkName = substring(elementAt(event,1),0);
    net = getValue(nntooldata,networkName);
    rangesValue = substring(elementAt(event,2),0);
    returnVector = elementAt(event,3);
    
    R = net.inputs{1}.size;
    
    err = 0;
    range = [];
    try
      eval(['range=' rangesValue ';']);
    catch
      err = 1;
    end
    if (err)
        jstring = nnjava('string','Input Ranges is not a legal matrix.');
        addElement(returnVector,jstring);
    elseif ~isa(range,'double')
        jstring = nnjava('string','Input Ranges is not a matrix.');
        addElement(returnVector,jstring);
    elseif size(range,2) ~= 2
        jstring = nnjava('string','Input Ranges does not have 2 columns.');
        addElement(returnVector,jstring);
    elseif size(range,1) ~= R
        jstring = nnjava('string',['Input Ranges does not have ' num2str(R) ' rows.']);
        addElement(returnVector,jstring);
    end
    
case 'setinputranges'
    networkName = substring(elementAt(event,1),0);
    net = getValue(nntooldata,networkName);
    rangesValue = substring(elementAt(event,2),0);
    eval(['net.inputs{1}.range=' rangesValue ';']);
    nntooldata = setValue(nntooldata,networkName,net);
    
case 'getnetworkinfo'
    name = substring(elementAt(event,1),0);
    returnVector = elementAt(event,2);
    net = getValue(nntooldata,name);
    jtrue = nnjava('string','true');
    jfalse = nnjava('string','false');
    conditionalAppend(returnVector,net.numInputs ~=0,jtrue,jfalse);
    conditionalAppend(returnVector,net.numOutputs ~=0,jtrue,jfalse);
    conditionalAppend(returnVector,net.numInputDelays ~=0,jtrue,jfalse);
    conditionalAppend(returnVector,net.numLayerDelays ~=0,jtrue,jfalse);
    conditionalAppend(returnVector,~strcmp(net.trainFcn,''),jtrue,jfalse);
    conditionalAppend(returnVector,~strcmp(net.adaptFcn,''),jtrue,jfalse);
    
case 'getdata'
    name = substring(elementAt(event,1),0);
    value = getValue(nntooldata,name);
    if all(size(value) == [1 1])
        mstring = nnmat2string(value{1,1});
    else
        mstring = nncell2string(value);
    end
    returnVector = elementAt(event,2);
    addElement(returnVector,nnjava('string',mstring));
        
case 'getdatarange'
    name = substring(elementAt(event,1),0);
    returnVector = elementAt(event,2);
    value = getValue(nntooldata,name);
    range = minmax(value);
    if iscell(range) && all(size(range)==[1 1])
      mstring = mat2str(range{1,1});
    elseif iscell(range)
      mstring = nncell2string(range);
    else
      mstring = mat2str(range);
    end
    addElement(returnVector,nnjava('string',mstring));
    
case 'checkdata'
    mstring = substring(elementAt(event,1),0);
    err = [];
    value = [];
    try
      eval(['value=' mstring ';']);
    catch
      err='Data is not a legal value.';
    end
    if isempty(err)
      err = nncheckdata(value);
    end
    if ~isempty(err)
      returnVector = elementAt(event,2);
      addElement(returnVector,nnjava('string',err));
    end
    
case 'setdata'
    name = substring(elementAt(event,1),0);
    mstring = substring(elementAt(event,2),0);
    value = eval([mstring ';']);
    if isa(value,'double')
        value = {value};
    end
    nntooldata = setValue(nntooldata,name,value);
    
case 'newnet'
  
  params = [];
  networkName = [];
  func = [];
  i = -1;
  try
  % lower to workaround the case-sensitivity of UNIX
    returnVector = elementAt(event,4);
    networkName = substring(elementAt(event,1),0);
    func = lower(substring(elementAt(event,2),0));
    
    try
      params = j2mparam(nntooldata,elementAt(event,3));
    catch me
      addElement(returnVector,nnjava('string',me.message));
      return
    end

    for i=1:length(params)
      param = params{i};
      if ischar(param)
        params{i}=lower(param);
      end
    end

    try
      net=feval(func,params{:});
    catch me
      addElement(returnVector,nnjava('string',me.message));
      return
    end
    nntooldata.network = addDef(nntooldata.network,networkName,net);
    
  catch me
    addElement(returnVector,nnjava('string','Unknown error prevented creation of new network.'));
    error_message = 'Error in nntool:newnet';
    last_error = me;
    save error_file error_message last_error networkName func params i
  end
  
case 'newinput'
    name = substring(elementAt(event,1),0);
    value = eval(substring(elementAt(event,2),0));
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.input = addDef(nntooldata.input,name,value);
    
case 'newtarget'
    name = substring(elementAt(event,1),0);
    value = eval(substring(elementAt(event,2),0));
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.target = addDef(nntooldata.target,name,value);
    
case 'newinputstate'
    name = substring(elementAt(event,1),0);
    value = eval(substring(elementAt(event,2),0));
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.inputstate = addDef(nntooldata.inputstate,name,value);
    
case 'newlayerstate'
    name = substring(elementAt(event,1),0);
    value = eval(substring(elementAt(event,2),0));
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.layerstate = addDef(nntooldata.layerstate,name,value);
    
case 'newoutput'
    name = substring(elementAt(event,1),0);
    value = eval(substring(elementAt(event,2),0));
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.output = addDef(nntooldata.output,name,value);
    
case 'newerror'
    name = substring(elementAt(event,1),0);
    value = eval(substring(elementAt(event,2),0));
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.error = addDef(nntooldata.error,name,value);
    
case 'importnet'
    name = substring(elementAt(event,1),0);
    variable = substring(elementAt(event,2),0);
    value = evalin('base',variable);
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.network = addDef(nntooldata.network,name,value);
    
case 'importinput'
    name = substring(elementAt(event,1),0);
    variable = substring(elementAt(event,2),0);
    value = evalin('base',variable);
    if isa(value,'double')
        value = {value};
    end
    
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.input = addDef(nntooldata.input,name,value);
    
case 'importtarget'
    name = substring(elementAt(event,1),0);
    variable = substring(elementAt(event,2),0);
    value = evalin('base',variable);
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.target = addDef(nntooldata.target,name,value);
    
case 'importinputstate'
    name = substring(elementAt(event,1),0);
    variable = substring(elementAt(event,2),0);
    value = evalin('base',variable);
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.inputstate = addDef(nntooldata.inputstate,name,value);
    
case 'importlayerstate'
    name = substring(elementAt(event,1),0);
    variable = substring(elementAt(event,2),0);
    value = evalin('base',variable);
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.layerstate = addDef(nntooldata.layerstate,name,value);
    
case 'importoutput'
    name = substring(elementAt(event,1),0);
    variable = substring(elementAt(event,2),0);
    value = evalin('base',variable);
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.output = addDef(nntooldata.output,name,value);
    
case 'importerror'
    name = substring(elementAt(event,1),0);
    variable = substring(elementAt(event,2),0);
    value = evalin('base',variable);
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.error = addDef(nntooldata.error,name,value);
    
case 'loadnet'
    name = substring(elementAt(event,1),0);
    variable = substring(elementAt(event,2),0);
    path = substring(elementAt(event,3),0);
    s = load(path,variable);
    value = s.(variable);
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.network = addDef(nntooldata.network,name,value);
    
case 'loadinput'
    name = substring(elementAt(event,1),0);
    variable = substring(elementAt(event,2),0);
    path = substring(elementAt(event,3),0);
    s = load(path,variable);
    value = s.(variable);
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.input = addDef(nntooldata.input,name,value);
    
case 'loadtarget'
    name = substring(elementAt(event,1),0);
    variable = substring(elementAt(event,2),0);
    path = substring(elementAt(event,3),0);
    s = load(path,variable);
    value = s.(variable);
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.target = addDef(nntooldata.target,name,value);
    
case 'loadinputstate'
    name = substring(elementAt(event,1),0);
    variable = substring(elementAt(event,2),0);
    path = substring(elementAt(event,3),0);
    s = load(path,variable);
    value = getfield(s,variable);
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.inputstate = addDef(nntooldata.inputstate,name,value);
    
case 'loadlayerstate'
    name = substring(elementAt(event,1),0);
    variable = substring(elementAt(event,2),0);
    path = substring(elementAt(event,3),0);
    s = load(path,variable);
    value = getfield(s,variable);
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.layerstate = addDef(nntooldata.layerstate,name,value);
    
case 'loadoutput'
    name = substring(elementAt(event,1),0);
    variable = substring(elementAt(event,2),0);
    path = substring(elementAt(event,3),0);
    s = load(path,variable);
    value = s.(variable);
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.output = addDef(nntooldata.output,name,value);
    
case 'loaderror'
    name = substring(elementAt(event,1),0);
    variable = substring(elementAt(event,2),0);
    path = substring(elementAt(event,3),0);
    s = load(path,variable);
    value = s.(variable);
    if isa(value,'double')
        value = {value};
    end
    nntooldata = deleteAllDefsByName(nntooldata,name);
    nntooldata.error = addDef(nntooldata.error,name,value);
    
case 'delete';
    name = substring(elementAt(event,1),0);
    nntooldata = deleteAllDefsByName(nntooldata,name);
    
case 'initialize'
    name = substring(elementAt(event,1),0);
    i = strmatch(name,nntooldata.network.names,'exact');
    nntooldata.network.values{i} = init(nntooldata.network.values{i});
    
case 'revert'
    name = substring(elementAt(event,1),0);
    i = strmatch(name,nntooldata.network.names,'exact');
    nntooldata.network.values{i} = revert(nntooldata.network.values{i});
    
case 'simulate'
    networkName = substring(elementAt(event,1),0);
    inputsName = substring(elementAt(event,2),0);
    initInputStatesName = substring(elementAt(event,3),0);
    initLayerStatesName = substring(elementAt(event,4),0);
    targetsName = substring(elementAt(event,5),0);
    
    % Sim results
    outputsName = substring(elementAt(event,6),0);
    finalInputStatesName = substring(elementAt(event,7),0);
    finalLayerStatesName = substring(elementAt(event,8),0);
    errorsName = substring(elementAt(event,9),0);
    
    % Error return vector
    returnVector = elementAt(event,10);
    net = getValueByName(nntooldata.network,networkName);
    if (strcmp(inputsName,'(zeros)'))
        P = inputZeros(net);
    else
        P = getValueByName(nntooldata.input,inputsName);
    end
    if (strcmp(initInputStatesName,'(zeros)'))
        Pi = {};
    else
        Pi = getValueByName(nntooldata.inputstate,initInputStatesName);
    end
    if (strcmp(initLayerStatesName,'(zeros)'))
        Ai = {};
    else
        Ai = getValueByName(nntooldata.layerstate,initLayerStatesName);
    end
    if (strcmp(targetsName,'(zeros)'))
        T = {};
    else
        T = getValueByName(nntooldata.target,targetsName);
    end
    err = 0;
    try
      [Y,Pf,Af,E] = sim(net,P,Pi,Ai,T);
    catch me
      err = 1;
    end
    if (err)
        jstring = nnjava('string',me.message);
        addElement(returnVector,jstring);
    else
        if (length(outputsName) > 0)
            nntooldata = deleteAllDefsByName(nntooldata,outputsName);
            nntooldata.output = addDef(nntooldata.output,outputsName,Y);
        end
        if (length(finalInputStatesName) > 0)
            nntooldata = deleteAllDefsByName(nntooldata,finalInputStatesName);
            nntooldata.inputstate = addDef(nntooldata.inputstate,finalInputStatesName,Pf);
        end
        if (length(finalLayerStatesName) > 0)
            nntooldata = deleteAllDefsByName(nntooldata,finalLayerStatesName);
            nntooldata.layerstate = addDef(nntooldata.layerstate,finalLayerStatesName,Af);
        end
        if (length(errorsName) > 0)
            nntooldata = deleteAllDefsByName(nntooldata,errorsName);
            nntooldata.error = addDef(nntooldata.error,errorsName,E);
        end
        
    end
    
    % TRAIN
case 'train'
    networkName = substring(elementAt(event,1),0);
    inputsName = substring(elementAt(event,2),0);
    initInputStatesName = substring(elementAt(event,3),0);
    initLayerStatesName = substring(elementAt(event,4),0);
    targetsName = substring(elementAt(event,5),0);
    
    % Training results
    outputsName = substring(elementAt(event,6),0);
    finalInputStatesName = substring(elementAt(event,7),0);
    finalLayerStatesName = substring(elementAt(event,8),0);
    errorsName = substring(elementAt(event,9),0);
    
    % Error return vector
    returnVector = elementAt(event,10);
    
    % Get training data
    net = getValueByName(nntooldata.network,networkName);
    if (strcmp(inputsName,'(zeros)'))
        P = inputZeros(net);
    else
        P = getValueByName(nntooldata.input,inputsName);
    end
    if (strcmp(initInputStatesName,'(zeros)'))
        Pi = {};
    else
        Pi = getValueByName(nntooldata.inputstate,initInputStatesName);
    end
    if (strcmp(initLayerStatesName,'(zeros)'))
        Ai = {};
    else
        Ai = getValueByName(nntooldata.layerstate,initLayerStatesName);
    end
    if (strcmp(targetsName,'(zeros)'))
        T = {};
    else
        T = getValueByName(nntooldata.target,targetsName);
    end
    
    err = 0;
    try
      [net,tr,Y,E,Pf,Af] = train(net,P,T,Pi,Ai);
    catch me
      err=1;
    end
    if (err)
      [errmsg,errid] = me.message;
        jstring = nnjava('string',errmsg);
        addElement(returnVector,jstring);
    else
        nntooldata.network.values{strmatch(networkName,nntooldata.network.names,'exact')} = net;
        if (length(outputsName) > 0)
            nntooldata = deleteAllDefsByName(nntooldata,outputsName);
            nntooldata.output = addDef(nntooldata.output,outputsName,Y);
        end
        if (length(finalInputStatesName) > 0)
            nntooldata = deleteAllDefsByName(nntooldata,finalInputStatesName);
            nntooldata.inputstate = addDef(nntooldata.inputstate,finalInputStatesName,Pf);
        end
        if (length(finalLayerStatesName) > 0)
            nntooldata = deleteAllDefsByName(nntooldata,finalLayerStatesName);
            nntooldata.layerstate = addDef(nntooldata.layerstate,finalLayerStatesName,Af);
        end
        if (length(errorsName) > 0)
            nntooldata = deleteAllDefsByName(nntooldata,errorsName);
            nntooldata.error = addDef(nntooldata.error,errorsName,E);
        end      
    end
    
case 'adapt'
    networkName = substring(elementAt(event,1),0);
    inputsName = substring(elementAt(event,2),0);
    initInputStatesName = substring(elementAt(event,3),0);
    initLayerStatesName = substring(elementAt(event,4),0);
    targetsName = substring(elementAt(event,5),0);
    outputsName = substring(elementAt(event,6),0);
    finalInputStatesName = substring(elementAt(event,7),0);
    finalLayerStatesName = substring(elementAt(event,8),0);
    errorsName = substring(elementAt(event,9),0);
    returnVector = elementAt(event,10);
    net = getValueByName(nntooldata.network,networkName);
    if (strcmp(inputsName,'(zeros)'))
        P = inputZeros(net);
    else
        P = getValueByName(nntooldata.input,inputsName);
    end
    if (strcmp(initInputStatesName,'(zeros)'))
        Pi = {};
    else
        Pi = getValueByName(nntooldata.inputstate,initInputStatesName);
    end
    if (strcmp(initLayerStatesName,'(zeros)'))
        Ai = {};
    else
        Ai = getValueByName(nntooldata.layerstate,initLayerStatesName);
    end
    if (strcmp(targetsName,'(zeros)'))
        T = {};
    else
        T = getValueByName(nntooldata.target,targetsName);
    end
    err = 0;
    try
      [net,Y,E,Pf,Af] = adapt(net,P,T,Pi,Ai);
    catch me
      err=1;
    end
    if (err)
        jstring = nnjava('string',me.message);
        addElement(returnVector,jstring);
    else
        nntooldata.network.values{strmatch(networkName,nntooldata.network.names,'exact')} = net;
        if (length(outputsName) > 0)
            nntooldata = deleteAllDefsByName(nntooldata,outputsName);
            nntooldata.output = addDef(nntooldata.output,outputsName,Y);
        end
        if (length(finalInputStatesName) > 0)
            nntooldata = deleteAllDefsByName(nntooldata,finalInputStatesName);
            nntooldata.inputstate = addDef(nntooldata.inputstate,finalInputStatesName,Pf);
        end
        if (length(finalLayerStatesName) > 0)
            nntooldata = deleteAllDefsByName(nntooldata,finalLayerStatesName);
            nntooldata.layerstate = addDef(nntooldata.layerstate,finalLayerStatesName,Af);
        end
        if (length(errorsName) > 0)
            nntooldata = deleteAllDefsByName(nntooldata,errorsName);
            nntooldata.error = addDef(nntooldata.error,errorsName,E);
        end
    end
    
case 'gettrainparams'
    networkName = substring(elementAt(event,1),0);
    names = elementAt(event,2);
    values = elementAt(event,3);
    net = getValueByName(nntooldata.network,networkName);
    trainParam = net.trainParam;
    if (isempty(trainParam))
        fields = {};
    else
        fields = fieldnames(trainParam);
    end
    num = size(fields,1);
    for i=1:num
        field = fields{i};
        name = nnjava('string',field);
        value = nnjava('string',mat2str(trainParam.(field)));
        addElement(names,name);
        addElement(values,value)
    end
    
case 'settrainparams'
    networkName = substring(elementAt(event,1),0);
    values = elementAt(event,2);
    net = getValueByName(nntooldata.network,networkName);
    trainParam = net.trainParam;
    if (isempty(trainParam))
        fields = {};
    else
        fields = fieldnames(trainParam);
    end
    num = size(fields,1);
    for i=1:num
        field = fields{i};
        value = eval(substring(elementAt(values,i-1),0));
        trainParam.(field) = value;
    end
    net.trainParam = trainParam;
    nntooldata.network.values{strmatch(networkName,nntooldata.network.names,'exact')} = net;
    
case 'getadaptparams'
    networkName = substring(elementAt(event,1),0);
    names = elementAt(event,2);
    values = elementAt(event,3);
    net = getValueByName(nntooldata.network,networkName);
    adaptParam = net.adaptParam;
    if (isempty(adaptParam))
        fields = {};
    else
        fields = fieldnames(adaptParam);
    end
    num = size(fields,1);
    for i=1:num
        field = fields{i};
        name = nnjava('string',field);
        value = nnjava('string',mat2str(adaptParam.(field)));
        addElement(names,name);
        addElement(values,value)
    end
    
case 'setadaptparams'
    networkName = substring(elementAt(event,1),0);
    values = elementAt(event,2);
    net = getValueByName(nntooldata.network,networkName);
    adaptParam = net.adaptParam;
    if (isempty(adaptParam))
        fields = {};
    else
        fields = fieldnames(adaptParam);
    end
    num = size(fields,1);
    for i=1:num
        value = eval(substring(elementAt(values,i-1),0));
        field = fields{i};
        adaptParams.(field) = value;
    end
    net.adaptParam = adaptParam;
    nntooldata.network.values{strmatch(networkName,nntooldata.network.names,'exact')} = net;
    
case 'getwsvars'
    names = elementAt(event,1);
    variables = evalin('base','who');
    for i=1:length(variables)
        variable = variables{i};
        addElement(names,nnjava('string',variable));
    end

case 'getwsvartype'
    name = substring(elementAt(event,1),0);
    returnVector = elementAt(event,2);
    value = evalin('base',name,'''UNKNOWN''');
    if isa(value,'network')
      code = 'NETWORK';
    elseif nnisdata(value)
      code = 'DATA';
    else
      code = 'UNKNOWN';
    end
    addElement(returnVector,nnjava('string',code));
    
case 'getfilevars'
    thepath = substring(elementAt(event,1),0);
    names = elementAt(event,2);
    variables = evalin('base',['who(''-file'',''' thepath ''')']);
    for i=1:length(variables)
        variable = variables{i};
        addElement(names,nnjava('string',variable));
    end
    
case 'getfilevartype'
    thepath = substring(elementAt(event,1),0);
    name = substring(elementAt(event,2),0);
    returnVector = elementAt(event,3);
    valueStruct = load(thepath,name);
    value = valueStruct.(name);
    if isa(value,'network')
      code = 'NETWORK';
    elseif nnisdata(value)
      code = 'DATA';
    else
      code = class(value); %'UNKNOWN';
    end
    addElement(returnVector,nnjava('string',code));
    
case 'export'
    variables = elementAt(event,1);
    count = double(size(variables));
    for i=1:count
        variable = substring(elementAt(variables,i-1),0);
        value = getValue(nntooldata,variable);
        if (all(size(value) == [1  1]))
            if isa(value,'cell')
                value = value{1,1};
            end
        end
    assignin('base',variable,value);
    end
    
case 'save'
    path = substring(elementAt(event,1),0);
    variables = elementAt(event,2);
    count = double(size(variables));
    names = {};
    for i=1:count
        variable = substring(elementAt(variables,i-1),0);
        value = getValue(nntooldata,variable);
        eval([variable ' = value;']);
        names = [names {variable}];
    end
    save(path,names{:});
    
case 'getdiagram'
    networkName = substring(elementAt(event,1),0);
    descVector = elementAt(event,2);
    net = getValueByName(nntooldata.network,networkName);
    descVector.add(nnjava('diagram',net));
    
case 'newdiagram'
    try
      errorHolder = elementAt(event,1);
      func = lower(substring(elementAt(event,2),0));
      params = j2mparam(nntooldata,elementAt(event,3));
      net = feval(func,params{:});
      errorHolder.removeAllElements();
      view(net);
    catch
      errorVector.add('error');
    end
end

%==========================================
function getNetworkDescription(net,descVector)
% Puts a description of NET into Java vector DESCVECTOR

if (net.numInputs == 1)
    switch (net.numLayers)
    case 1
        if (net.inputConnect == 1) && (net.layerConnect == 0)
            % Single layer network
            % descVector = ['ff1' inputSize
            %   layerSize netInputFcn transferFcn]
            addElement(descVector,nnjava('string','ff1'));
            addElement(descVector,nnjava('string',num2str(net.inputs{1}.size)));
            addElement(descVector,nnjava('string',num2str(net.layers{1}.size)));
            n1 = net.layers{1}.netInputFcn;
            addElement(descVector,nnjava('string',n1));
            f1 = net.layers{1}.transferFcn;
            addElement(descVector,nnjava('string',f1));
        else
          addElement(descVector,nnjava('string','unknown'));
        end
    case 2
        % Two layer feed-forward network
        % descVector = ['ff2' inputSize
        %   layerSize1 netInputFcn1 transferFcn1
        %   layerSize2 netInputFcn2 transferFcn2]
        if all(net.inputConnect==[1;0]) && all(all(net.layerConnect==[0 0;1 0]))
            addElement(descVector,nnjava('string','ff2'));
            addElement(descVector,nnjava('string',num2str(net.inputs{1}.size)));
            addElement(descVector,nnjava('string',num2str(net.layers{1}.size)));
            n1 = net.layers{1}.netInputFcn;
            addElement(descVector,nnjava('string',n1));
            f1 = net.layers{1}.transferFcn;
            addElement(descVector,nnjava('string',f1));
            addElement(descVector,nnjava('string',num2str(net.layers{2}.size)));
            n2 = net.layers{2}.netInputFcn;
            addElement(descVector,nnjava('string',n2));
            f2 = net.layers{2}.transferFcn;
            addElement(descVector,nnjava('string',f2));
        else
          addElement(descVector,nnjava('string','unknown'));
        end
    case 3
        if all(net.inputConnect==[1;0;0]) && all(all(net.layerConnect==[0 0 0;1 0 0;0 1 0]))
            % Three layer feed-forward network
            % descVector = ['ff3' inputSize
            %   layerSize1 netInputFcn1 transferFcn1
            %   layerSize2 netInputFcn2 transferFcn2
            %   layerSize3 netInputFcn3 transferFcn3]
            addElement(descVector,nnjava('string','ff3'));
            addElement(descVector,nnjava('string',num2str(net.inputs{1}.size)));
            addElement(descVector,nnjava('string',num2str(net.layers{1}.size)));
            n1 = net.layers{1}.netInputFcn;
            addElement(descVector,nnjava('string',n1));
            f1 = net.layers{1}.transferFcn;
            addElement(descVector,nnjava('string',f1));
            addElement(descVector,nnjava('string',num2str(net.layers{2}.size)));
            n2 = net.layers{2}.netInputFcn;
            addElement(descVector,nnjava('string',n2));
            f2 = net.layers{2}.transferFcn;
            addElement(descVector,nnjava('string',f2));
            addElement(descVector,nnjava('string',num2str(net.layers{3}.size)));
            n3 = net.layers{3}.netInputFcn;
            addElement(descVector,nnjava('string',n3));
            f3 = net.layers{3}.transferFcn;
            addElement(descVector,nnjava('string',f3));
        else
          addElement(descVector,nnjava('string','unknown'));
        end
      otherwise
        addElement(descVector,nnjava('string','unknown'));
    end
  else
  addElement(descVector,nnjava('string','unknown'));
end

%==========================================
function value = getValue(data,name)

f=fields(data);
for i=1:length(f)
  defs = data.(f{i});
  index = strmatch(name,defs.names,'exact');
  if (index)
      value = defs.values{index};
      return;
  end
end
value = [];
set(gcf,'name','getValue-fail');

%==========================================
function P = inputZeros(net)

P = cell(net.numInputs,1);
for i=1:net.numInputs
    P{i,1} = zeros(net.inputs{i}.size);
end

%==========================================
function data = setValue(data,name,value)

f = fields(data);
for i=1:length(f);
  defs = data.(f{i});
  index = strmatch(name,defs.names,'exact');
  if (index)
       defs.values{index} = value;
       data.(f{i}) = defs;
  end
end

%==========================================
function value = getValueByName(defs,name)

value = defs.values{strmatch(name,defs.names,'exact')};

%==========================================
function defs = addDef(defs,name,value)

defs.names = [defs.names {name}];
defs.values = [defs.values {value}];

%==========================================
function data = deleteAllDefsByName(data,name)

data.network = deleteDefByName(data.network,name);
data.input = deleteDefByName(data.input,name);
data.target = deleteDefByName(data.target,name);
data.inputstate = deleteDefByName(data.inputstate,name);
data.layerstate = deleteDefByName(data.layerstate,name);
data.output = deleteDefByName(data.output,name);
data.error = deleteDefByName(data.error,name);

%==========================================
function defs = deleteDefByName(defs,name)

i = strmatch(name,defs.names,'exact');
if length(i) > 0;
    defs.names(i) = [];
    defs.values(i) = [];
end

%==========================================
function mparam = j2mparam(nntooldata,jparam)

FUNCTION_NAME = 0;
INPUT = 2;
TARGET = 3;
if isa(jparam,'com.mathworks.toolbox.nnet.nntool.property.NNValue')
    string = char(getString(jparam));
    type = getType(jparam);
    if (type == FUNCTION_NAME)
      mparam = lower(string);
    elseif (type == INPUT)
      if strcmp(string,'<NO_INPUT>'), error('NNET:NNTool','No input selected.'); end
      name = string((length('INPUT:')+1):end);
      mparam = getValue(nntooldata,name);
    elseif (type == TARGET)
      if strcmp(string,'<NO_TARGET>'), error('NNET:NNTool','No target selected.'); end
      name = string((length('TARGET:')+1):end);
      mparam = getValue(nntooldata,name);
    else
      mparam = eval(string);
    end
elseif isa(jparam,'java.util.Vector')
    num = double(size(jparam));
    mparam = cell(1,num);
    for i=1:num
        mparam{i} = j2mparam(nntooldata,elementAt(jparam,i-1));
    end
else
    error('NNET:NNTool',['J2MPARAM can not convert ' class(jparam) ' objects\n']);
end
%==========================================
function conditionalAppend(vector,condition,jtrue,jfalse)

if (condition)
  addElement(vector,jtrue);
else
  addElement(vector,jfalse);
end
%==========================================
