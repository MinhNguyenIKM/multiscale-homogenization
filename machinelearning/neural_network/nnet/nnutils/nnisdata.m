function ok = nnisdata(v)

% Copyright 2005 The MathWorks, Inc.

% Must not have more than 2 dimensions
ok = 0;

% Ok if double
if isa(v,'double')
    ok = ndims(v) <= 2;
    return
end

% Or a cell array:
if ~isa(v,'cell')
    return
end
if ndims(v) > 2
    return
end

rows = size(v,1);
cols = size(v,2);
for i=1:rows
    for j=1:cols
        % must be double
        if ~isa(v{i,j},'double')
            return;
        end
        % must be 2D
        if ndims(v{i,j}) > 2
            return;
        end
        % must have same # of cols
        if size(v{i,j},2) ~= size(v{1,1},2)
            return;
        end
        % must have same # rows, if in same row
        if size(v{i,j},1) ~= size(v{1,1},1)
            return
        end
    end
end
ok = 1;
