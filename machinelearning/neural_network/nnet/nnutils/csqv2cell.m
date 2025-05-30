function y = csqv2cell(x)

% Copyright 2007 The MathWorks, Inc.

pos = 1;
y = nextRow(x,pos);

%% Next Row
function [row,pos] = nextRow(x,pos)

row = {};
while (true)
  [value,pos,ok] = nextElement(x,pos);
  if (~ok), return; end
  row{end+1} = value;
  if (pos > length(x)), return; end
  if x(pos) ~= ',', return; end
  pos = pos+1;
end

%% Next Element
function [value,pos,ok] = nextElement(x,pos)

if x(pos) ~= '"', value=''; ok = false; return, end
pos = pos+1;
start = pos;
while (x(pos) ~= '"'), pos = pos + 1; end
value = x(start:(pos-1));
pos = pos+1;
ok = true;
