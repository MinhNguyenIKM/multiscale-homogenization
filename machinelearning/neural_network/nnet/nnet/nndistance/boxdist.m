function d = boxdist(pos)
%BOXDIST Box distance function.
%
%  Syntax
%
%    d = boxdist(pos);
%    info = boxdist(code);
%
%  Description
%
%    BOXDIST is a layer distance function used to find
%    the distances between the layer's neurons given their
%    positions.
%
%    BOXDIST(pos) takes one argument,
%      POS - NxS matrix of neuron positions.
%     and returns the SxS matrix of distances.
%
%    BOXDIST is most commonly used in conjunction with layers
%    whose topology function is GRIDTOP.
%
%    BOXDIST('name') returns the name of this function.
%
%  Examples
%
%    Here we define a random matrix of positions for 10 neurons
%    arranged in three dimensional space and find their distances.
%
%      pos = rand(3,10);
%      d = boxdist(pos)
%
%  Network Use
%
%    You can create a standard network that uses BOXDIST
%    as a distance function by calling NEWSOM.
%
%    To change a network so a layer's topology uses BOXDIST set
%    NET.layers{i}.distanceFcn to 'boxdist'.
%
%    In either case, call SIM to simulate the network with BOXDIST.
%    See NEWSOM for training and adaption examples.
%
%  Algorithm
%
%    The box distance D between two position vectors Pi and Pj
%    from a set of S vectors is:
%  
%      Dij = max(abs(Pi-Pj))
%
%  See also SIM, DIST, MANDIST, LINKDIST.

% Mark Beale, 11-31-97
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.6 $

fn = mfilename;
if (nargin < 1), error('NNET:Arguments','Not enough arguments.'); end
if ischar(pos)
  switch(pos)
    case 'name'
      d = 'Box Distance';
    otherwise, error('NNET:Arguments',['Unrecognized code: ''' pos ''''])
  end
  return
end

[dims,s] = size(pos);
d = zeros(s,s);
for i=1:s
  for j=1:(i-1)
    d(i,j) = max(abs(pos(:,i)-pos(:,j)));
  end
end
d = d + d';
