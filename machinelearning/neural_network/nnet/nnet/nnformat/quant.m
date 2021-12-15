function y = quant(x,q)
%QUANT Discretize values as multiples of a quantity.
%
%  Syntax
%
%    quant(x,q)
%
%  Description
%
%    QUANT(X,Q) takes these inputs,
%      X - Matrix, vector or scalar.
%      Q - Minimum value.
%    and returns values in X rounded to nearest multiple of Q
%  
%  Examples
%
%    x = [1.333 4.756 -3.897];
%    y = quant(x,0.1)

% Mark Beale, 12-15-93
% Copyright 1992-2005 The MathWorks, Inc.
% $Revision: 1.1.6.2 $  $Date: 2005/12/22 18:19:22 $

y = round(x/q)*q;
