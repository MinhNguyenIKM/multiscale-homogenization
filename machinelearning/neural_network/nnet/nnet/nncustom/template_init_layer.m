function net=template_init_layer(net,i)
%TEMPLATE_INIT_LAYER Template layer initialization function.
%
%  WARNING - Future versions of the toolbox may require you to update
%  custom functions.
%
%  Directions for Customizing
%
%    1. Make a copy of this function with a new name
%    2. Edit your new function according to the code comments marked ***
%    3. Type HELP NNINIT to see a list of other layer initialization functions.
%
%  Syntax
%
%    net = template_init_layer(net,i)
%  
%  Description
%
%    TEMPLATE_INIT_LAYER(NET,i) takes two arguments,
%      NET - Neural network.
%      i   - Index of a layer.
%    and returns the network with layer i's weights and biases updated.
%
%  Network Use
%
%    To prepare a custom network to be initialized with TEMPLATE_INIT_LAYER:
%    1) Set NET.initFcn to 'initlay'.
%       (This will set NET.initParam to the empty matrix [] since
%       INITLAY has no initialization parameters.)
%    2) Set NET.layers{i}.initFcn to 'template_init_layer'.
%    To initialize the network call INIT.

% Copyright 1992-2005 The MathWorks, Inc.

if net.biasConnect(i)
  rows = net.layers{i};

  % *** CUSTOMIZE HERE
  % *** Define the ith layer's ROWSx1 bias vector
  net.b{i} = ones(rows,1);
  % ***
  
end
for j=find(net.inputConnect(i,:))
  cols = net.inputs{j}.size;
  
  % *** CUSTOMIZE HERE
  % *** Define the ith layer's ROWSxCOLS weight matrix from the jth input
  net.IW{i,j} = ones(rows,cols);
  % ***
end
for j=find(net.layerConnect(i,:))
  cols = net.inputs{j}.size;
  
  % *** CUSTOMIZE HERE
  % *** Define the ith layer's ROWSxCOLS weight matrix from the jth layer
  net.LW{i,j} = ones(rows,cols);
  % ***
end
