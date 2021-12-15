function gp = calc_gp_from_gpd(net,gpd,Q,TS)

% Copyright 2007 The MathWorks, Inc.

numInputs = net.numInputs;
gp = cell(numInputs,TS);
for j=1:numInputs
  inputSize = net.inputs{j}.processedSize;
  for ts=1:TS
    gp{j,ts} = zeros(inputSize,Q);
    for i=find(net.inputConnect(:,j)')
      delays = net.inputWeights{i,j}.delays;
      for d = 1:length(delays)
        delay = delays(d);
        delayed_ts = ts-delay;
        if (delayed_ts > 0)
          gp{j,delayed_ts} = gp{j,delayed_ts} + gpd{i,j,ts}((1:inputSize)+delay*inputSize,:);
        end
      end
    end
  end
end
