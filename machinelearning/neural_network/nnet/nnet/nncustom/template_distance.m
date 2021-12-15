function d = template_transfer(pos)
%TEMPLATE_TRANSFER Template distance function.
%
%  WARNING - Future versions of the toolbox may require you to update
%  custom functions.
%
%  Directions for Customizing
%
%    1. Make a copy of this function with a new name
%    2. Edit your new function according to the code comments marked ***
%    3. Type HELP NNTRANSFER to see a list of other distance functions.
%
%  Syntax
%
%    d = template_transfer(pos);
%
%  Description
%
%    TEMPLATE_TRANSFER(pos) takes one argument,
%      POS - NxS matrix of neuron positions.
%    and returns the SxS matrix of distances.
%
%  Network Use
%
%    To change a network so a layer's topology uses TEMPLATE_TRANSFER set
%    NET.layers{i}.distanceFcn to 'template_transfer'.

% Copyright 2005-2008 The MathWorks, Inc.

[rows,cols] = size(pos);
d = zeros(cols,cols);
for i=1:cols
  for j=1:(i-1)
    d(i,j) = calculate_distance(pos(:,i),pos(:,j));
  end
end
d = d + d';

%=====================
function d = calculate_distance(v1,v2)

% *** CUSTOMIZE HERE
% *** Calculate scalar distance d,
% *** given two column vectors v1 and v2, of the same length.
d = sqrt(sum((v1-v2).^2));
% ***
