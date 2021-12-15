function net=template_init_network(net)
%TEMPLATE_INIT_NETWORK Template network initialization function.
%
%  WARNING - Future versions of the toolbox may require you to update
%  custom functions.
%
%  Directions for Customizing
%
%    1. Make a copy of this function with a new name
%    2. Edit your new function according to the code comments marked ***
%    3. Type HELP NNINIT to see a list of other network initialization functions.
%
%  Syntax
%
%    net = template_init_network(net)
%    info = template_init_network(code)
%
%  Description
%
%    TEMPLATE_INIT_NETWORK(NET) takes:
%      NET - Neural network.
%    and returns the network with each layer updated.
%
%    TEMPLATE_INIT_NETWORK(CODE) return useful information for each CODE string:
%      'pnames'    - Names of initialization parameters.
%      'pdefaults' - Default initialization parameters.
%
%  Network Use
%
%    To prepare a custom network to be initialized with
%    TEMPLATE_INIT_NETWORK set NET.initFcn to 'template_init_network'.
%    To initialize the network call INIT.

% Copyright 1992-2007 The MathWorks, Inc.

% FUNCTION INFO
% =============

if ischar(net)
  switch (net)
    case 'pnames',
      
      % *** CUSTOMIZE HERE
      % *** Define any number of parameter names
      net = {'Param One','Param Two','Param Three'};
      % ***
      
    case 'pdefaults',
      net = struct;
      
      % *** CUSTOMIZE HERE
      % *** Define default values for the parameters
      net.param1 = 1;
      net.param2 = 2;
      net.param3 = 3;
      % ***
      
    otherwise,
      error('NNET:Code','Unrecognized code.')
  end
  return
end

for i=1:net.numLayers
  if net.biasConnect(i)
    rows = net.layers{i};

    % *** CUSTOMIZE HERE
    % *** Define the ith layer's ROWSx1 bias vector
    net.b{i} = zeros(rows,1) + net.param1;
    % ***

  end
  for j=find(net.inputConnect(i,:))
    cols = net.inputs{j}.size;

    % *** CUSTOMIZE HERE
    % *** Define the ith layer's ROWSxCOLS weight matrix from the jth input
    net.IW{i,j} = zeros(rows,cols) +  + net.param2;
    % ***
  end
  for j=find(net.layerConnect(i,:))
    cols = net.inputs{j}.size;

    % *** CUSTOMIZE HERE
    % *** Define the ith layer's ROWSxCOLS weight matrix from the jth layer
    net.LW{i,j} = zeros(rows,cols) + net.param3;
    % ***
  end
end
