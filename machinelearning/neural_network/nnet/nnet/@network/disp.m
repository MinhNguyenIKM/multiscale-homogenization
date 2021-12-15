function disp(net)
%DISP Display a neural network's properties.
%
%  Syntax
%
%    disp(net)
%
%  Description
%
%    DISP(NET) displays a network's properties.
%
%  Examples
%
%    Here a perceptron is created and displayed.
%
%      net = newp([-1 1; 0 2],3);
%      disp(net)
%
%  See also DISPLAY, SIM, INIT, TRAIN, ADAPT

%  Mark Beale, 11-31-97
%  Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.7.4.5 $

isLoose = strcmp(get(0,'FormatSpacing'),'loose');

if (isLoose), fprintf('\n'), end
fprintf('    Neural Network object:\n');
if (isLoose), fprintf('\n'), end
fprintf('    architecture:\n');
if (isLoose), fprintf('\n'), end

fprintf('         numInputs: %g\n',net.numInputs);
fprintf('         numLayers: %g\n',net.numLayers);
fprintf('       biasConnect: %s\n',boolstr(net.biasConnect));
fprintf('      inputConnect: %s\n',boolstr(net.inputConnect));
fprintf('      layerConnect: %s\n',boolstr(net.layerConnect));
fprintf('     outputConnect: %s\n',boolstr(net.outputConnect));
fprintf('\n');
fprintf('        numOutputs: %g  (read-only)\n',net.numOutputs);
fprintf('    numInputDelays: %g  (read-only)\n',net.numInputDelays);
fprintf('    numLayerDelays: %g  (read-only)\n',net.numLayerDelays);

if (isLoose), fprintf('\n'), end

fprintf('    subobject structures:\n');

if (isLoose), fprintf('\n'), end

fprintf('            inputs: {%gx1 cell} of inputs\n',net.numInputs);
fprintf('            layers: {%gx1 cell} of layers\n',net.numLayers);
fprintf('           outputs: {%gx%g cell} containing %s\n',size(net.outputs),nplural(active(net.outputs),'output'));
fprintf('            biases: {%gx%g cell} containing %s\n',size(net.biases),nplural(active(net.biases),'bias'));
fprintf('      inputWeights: {%gx%g cell} containing %s\n',size(net.inputWeights),nplural(active(net.inputWeights),'input weight'));
fprintf('      layerWeights: {%gx%g cell} containing %s\n',size(net.layerWeights),nplural(active(net.layerWeights),'layer weight'));

if (isLoose), fprintf('\n'), end

fprintf('    functions:\n');

if (isLoose), fprintf('\n'), end

fprintf('          adaptFcn: %s\n',functionStr(net.adaptFcn));
fprintf('         divideFcn: %s\n',functionStr(net.divideFcn));
fprintf('       gradientFcn: %s\n',functionStr(net.gradientFcn));
fprintf('           initFcn: %s\n',functionStr(net.initFcn));
fprintf('        performFcn: %s\n',functionStr(net.performFcn));
fprintf('          plotFcns: %s\n',stringList2Str(net.plotFcns));
fprintf('          trainFcn: %s\n',functionStr(net.trainFcn));

if (isLoose), fprintf('\n'), end

fprintf('    parameters:\n');

if (isLoose), fprintf('\n'), end

fprintf('        adaptParam: '); parameterStr(net.adaptParam);
fprintf('       divideParam: '); parameterStr(net.divideParam);
fprintf('     gradientParam: '); parameterStr(net.gradientParam);
fprintf('         initParam: '); parameterStr(net.initParam);
fprintf('      performParam: '); parameterStr(net.performParam);
%fprintf('        plotParams: %s\n',paramList2Str(net.plotParams));
fprintf('        trainParam: '); parameterStr(net.trainParam);

if (isLoose), fprintf('\n'), end

fprintf('    weight and bias values:\n');

if (isLoose), fprintf('\n'), end

fprintf('                IW: {%gx%g cell} containing %s\n',size(net.inputWeights),nplural(active(net.inputWeights),'input weight matrix'));
fprintf('                LW: {%gx%g cell} containing %s\n',size(net.layerWeights),nplural(active(net.layerWeights),'layer weight matrix'));
fprintf('                 b: {%gx%g cell} containing %s\n',size(net.biases),nplural(active(net.biases),'bias vector'));

if (isLoose), fprintf('\n'), end

fprintf('    other:\n');

if (isLoose), fprintf('\n'), end

fprintf('              name: ''%s''\n',net.name);
fprintf('          userdata: (user information)\n');

if (isLoose), fprintf('\n'), end

%% Plural
function str = plural(n,s)

if n == 1
  str = s;
else
  if s(end) == 's'
    str = [s 'es'];
  elseif s(end) == 'x'
    str = [s(1:(end-1)) 'ces'];
  else
    str = [s 's'];
  end
end

%% N Plural
function str = nplural(n,s)

if n == 0
  str = sprintf('no %s',plural(n,s));
elseif n == 1
  str = sprintf('%g %s',n,s);
else
  str = sprintf('%g %s',n,plural(n,s));
end

%% Function String
function str = functionStr(s)

if isempty(s)
  str = '(none)';
else
  str = ['''' s ''''];
end

%% Parameter String
function parameterStr(s)

if isempty(s)
  fprintf('(none)\n');
  return
end

f = fieldnames(s);
n = length(f);
if n == 0
  fprintf('(none)\n');
elseif n == 1
  fprintf('.%s\n',f{1});
else
  fprintf('.%s',f{1});
  for i=2:n
    fprintf(', ')
    if rem(i,4) == 1
      fprintf('\n                    ')
    end
    fprintf('.%s',f{i});
  end
  fprintf('\n')
end

%% String List 2 String
function s = stringList2Str(list)

s = '{';
for i=1:length(list)
  if i>1, s = [s ',']; end
  s = [s '''' list{i} ''''];
end
s = [s '}'];

%% Parameter List 2 String
function s = paramList2Str(list)

num = length(list);
if num == 0
  s = '{}';
else
  s = ['{ ...' num2str(num) '...}'];
end

%% Boolean String
function s=boolstr(b)

if numel(b) > 12
  s = sprintf('[%gx%g boolean]',size(b,1),size(b,2));
else
  s = '[';
  for i=1:size(b,1)
    if (i > 1)
      s = [s '; '];
    end
    for j=1:size(b,2)
    if (j > 1)
        s = [s sprintf(' %g',b(i,j))];
      else
        s = [s sprintf('%g',b(i,j))];
    end
    end
  end
  s = [s ']'];
end
  

