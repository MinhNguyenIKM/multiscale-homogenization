function tr = tr_update(tr,stateValues)

% Copyright 2007 The MathWorks, Inc.

epoch = tr.num_epochs + 1;
tr.num_epochs = epoch;
ind = epoch+1;
stateNames = tr.states;

if epoch == 0
  % Fill in first values
  tr.epoch(ind) = 0;
  for i=1:length(stateNames)
    tr.(stateNames{i}) = stateValues(i);
  end
elseif epoch >= length(tr.epoch)
  % Double array sizes if not big enough, expanding with new and NaN values
  expansion = nan(1,epoch-1);
  tr.epoch = [tr.epoch epoch expansion];
  for i=1:length(stateNames)
    stateName = stateNames{i};
    tr.(stateName) = [tr.(stateName) stateValues(i) expansion];
  end
else
  % Fill in subsequent values
  tr.epoch(ind) = epoch;
  for i=1:length(stateNames)
    tr.(stateNames{i})(ind) = stateValues(i);
  end
end

if ~isempty(tr.stop)
  tr = tr_clip(tr);
end
