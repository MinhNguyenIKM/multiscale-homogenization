function nn_setup_java

% Not currently used.

% Copyright 2007-2008 The MathWorks, Inc.

% Check that the Neural Network Toolbox is installed
if ~license('test', 'Neural_Network_Toolbox')
  error('nnet:nn_setup_java:noLicense',...
    'This functionality requires the Neural Network Toolbox.');
end

% Can't proceed unless we have desktop java support
if ~usejava('swing')
  error('nnet:nftool:missingJavaSwing',...
    'This functionality requires Java and Swing to be available.');
end

% Add development files to classpath
addPaths = {'c:\nnet6\jai_core.jar', 'c:\nnet6\jai_codec.jar'};
oldPaths = javaclasspath;
for i=1:length(addPaths)
  if isempty(strmatch(addPaths{i},oldPaths,'exact'))
    javaaddpath(addPaths{i});
  end
end

% Initialize root
com.mathworks.toolbox.nnet.matlab.NNMatlabInfo.initialize(matlabroot);
