function pos=template_topology(varargin)
%TEMPLATE_TOPOLOGY Template topology function.
%
%  WARNING - Future versions of the toolbox may require you to update
%  custom functions.
%
%  Directions for Customizing
%
%    1. Make a copy of this function with a new name
%    2. Edit your new function according to the code comments marked ***
%    3. Type HELP NNTEMPLATE to see a list of other topology functions.
%
%  Syntax
%
%    pos = template_topology(dim1,dim2,...,dimN)
%
%  Description
%
%    TEMPLATE_TOPOLOGY(DIM1,DIM2,...,DIMN) takes N arguments,
%      DIMi - Length of layer in dimension i.
%    and returns an NxS matrix of N coordinate vectors
%    where S is the product of DIM1*DIM2*...*DIMN.
%
%	Network Use
%
%	  To change a network so a layer uses TEMPLATE_TOPOLOGY set
%	  NET.layer{i}.topologyFcn to 'template_topology.

% Mark Beale, 11-31-97
% Copyright 1992-2005 The MathWorks, Inc.
% $Revision: 1.1.6.1 $

dim = [varargin{:}];
size = prod(dim);
n = length(dim);
pos = zeros(n,size);

% *** CUSTOMIZE HERE
% *** Fill in each POS(:,i) with the N-dimensional position of the ith neuron
len = 1;
pos(1,1) = 0;
for i=1:n
  dimi = dim(i);
  newlen = len*dimi;
  pos(1:(i-1),1:newlen) = pos(1:(i-1),rem(0:(newlen-1),len)+1);
  posi = 0:(dimi-1);
  pos(i,1:newlen) = posi(floor((0:(newlen-1))/len)+1);
  len = newlen;
end
% ***


