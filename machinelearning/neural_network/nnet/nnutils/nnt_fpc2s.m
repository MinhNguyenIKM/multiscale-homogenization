function s = nnt_fpc2s(c,pd)

% Copyright 2005 The MathWorks, Inc.

f = fieldnames(pd);
s = struct;
for i=1:length(f)
  s=setfield(s,f{i},c{i});
end

