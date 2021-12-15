function i=vec2ind(v)
%VEC2IND Transform vectors to indices.
%
%  Syntax
%
%    ind = vec2ind(vec)
%
%  Description
%
%    IND2VEC and VEC2IND allow indices to be represented
%    either by themselves or as vectors containing a 1 in the
%    row of the index they represent.
%
%    VEC2IND(VEC) takes one argument,
%      VEC - Matrix of vectors, each containing a single 1.
%    and returns the indices of the 1's.
%
%  Examples
%
%    Here four vectors (containing only one 1 each) are defined
%    and the indices of the 1's are found.
%
%      vec = [1 0 0 0; 0 0 1 0; 0 1 0 1]
%      ind = vec2ind(vec)
%  
%  See also IND2VEC.

% Mark Beale, 12-15-93
% Copyright 1992-2005 The MathWorks, Inc.
% $Revision: 1.1.6.2 $  $Date: 2005/12/22 18:19:24 $

[i,j,s] = find(v);
i=i';
