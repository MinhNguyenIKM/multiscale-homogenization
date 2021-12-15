function y = fill_defaults(x,defaults)

% Copyright 2007 The MathWorks, Inc.

y = [x defaults((length(x)+1):end)];
