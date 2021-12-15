function root = nnetroot

% Copyright 2007 The MathWorks, Inc.

% General Case

c = computer;
if isempty(strmatch(c,{'PCWIN','PCWIN64'},'exact'))
  root = [matlabroot '/toolbox/nnet'];
  return
end

% Windows only, detect if development toolbox has non-standard path

p1 = path;
p2 = p1;
p2((p1 == '/') | (p1 == '\') | (p1 == ':')) = '*';

semicolons = [0 find(p1 == ';') (length(p1)+1)];
for i=1:(length(semicolons)-1)
  start = semicolons(i)+1;
  stop = semicolons(i+1)-1;
  s1 = p1(start:stop);
  s2 = p2(start:stop);
  position = findstr(s2,'nnet*nnet*nnnetwork');
  if ~isempty(position)
    position = position(1);
    root = s1(1:(position+3));
    root2 = s2(1:(position+3));
    if isempty(findstr(root2,'test*toolbox*nnet'))
      return
    end
  end
end
root = '';
