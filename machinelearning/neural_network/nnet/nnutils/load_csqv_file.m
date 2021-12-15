function data = load_csqv_file(path)

% Copyright 2007 The MathWorks, Inc.

MAX_LINES = 100000;
data = {};
numLines = 0;
f = fopen(path,'r');
while (true)
  line = fgetl(f);
  if (length(line) == 1) && (line == -1), break, end
  numLines = numLines + 1;
  row = csqv2cell(line);
  if numLines == 1
    numColumns = length(row);
    data = cell(MAX_LINES,numColumns);
  end
  data(numLines,:) = row;
  if ~rem(numLines,100),disp(['numLines = ' num2str(numLines)]),end
end
fclose(f);
data = data(1:numLines,:);