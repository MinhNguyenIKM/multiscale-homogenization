function tr = tr_clip(tr)

% Copyright 2007 The MathWorks, Inc.

stateNames = tr.states;
len = tr.num_epochs+1;
ind = 1:len;
tr.epoch = tr.epoch(ind);
for i=1:length(stateNames)
  stateName = stateNames{i};
  tr.(stateName) = tr.(stateName)(ind);
end
