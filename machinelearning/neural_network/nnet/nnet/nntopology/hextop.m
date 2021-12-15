function pos=hextop(varargin)
%HEXTOP Hexagonal layer topology function.
%
%  Syntax
%
%    pos = hextop(dim1,dim2,...,dimN)
%
%  Description
%
%    HEXTOP calculates the neuron positions for layers whose
%    neurons are arranged in a N dimensional hexagonal pattern.
%
%    HEXTOP(DIM1,DIM2,...,DIMN) takes N arguments,
%      DIMi - Length of layer in dimension i.
%    and returns an NxS matrix of N coordinate vectors
%    where S is the product of DIM1*DIM2*...*DIMN.
%
%  Examples
%
%    positions = hextop(8,5);
%    plotsom(pos)
%
%  See also GRIDTOP, RANDTOP, TRITOP.

% Mark Beale, 11-31-97
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.1.6.6 $

if (nargin < 1), error('NNET:Arguments','Not enough arguments.'); end
in1 = varargin{1};
if ischar(in1)
  switch(in1)
    case 'name'
      pos = 'Hexagonal';
    otherwise, error('NNET:Arguments',['Unrecognized code: ''' in1 ''''])
  end
  return
end

dim = [varargin{:}];
dims = length(dim);
pos = zeros(dims,prod(dim));

len = 1;
pos(1,1) = 0;
center = [];
for i=1:length(dim)
  dimi = dim(i);
  newlen = len*dimi;
  offset = sqrt(1-sum(sum(center.*center)));
  
  if (i>1)
    for j=2:dimi
      iShift = center * rem(j+1,2);
    doShift = iShift(:,ones(1,len));
      pos(1:(i-1),(1:len)+len*(j-1)) = pos(1:(i-1),1:len) + doShift;
    end
  end
  
  posi = (0:(dimi-1))*offset;
  pos(i,1:newlen) = posi(floor((0:(newlen-1))/len)+1);
  
  len = newlen;
  center = ([center; 0]*i + [center; offset])/(i+1);
end
