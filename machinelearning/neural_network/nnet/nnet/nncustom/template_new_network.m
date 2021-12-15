function net = template_new_network(varargin)
%TEMPLATE_NEW_NETWORK Template new network function.
%  
%  WARNING - Future versions of the toolbox may require you to update
%  custom functions.
%
%  Directions for Customizing
%
%    1. Make a copy of this function with a new name
%    2. Edit your new function according to the code comments marked ***
%    3. Type HELP NNNETWORK to see a list of other new network functions.
%
%  Syntax
%  
%    net = template_new_network(...args...)
%
%  Description
%
%    TEMPLATE_NEW_NETWORK(..args...) takes however many args you want
%    to define and returns a new network.

% Copyright 1992-2007 The MathWorks, Inc.

% *** CUSTOMIZE HERE
% *** Define your network according to whatever arguments you
% *** put in the function definition at the top of this file.

numInputs = 1;
numLayers = 1;
biasConnect = [1];
inputConnect = [1];
layerConnect = [1];
outputConnect = [1];

net = network(numInputs,numLayers,biasConnect,inputConnect, ...
layerConnect,outputConnect);

net.layers{1}.transferFcn = 'tansig';

% ***