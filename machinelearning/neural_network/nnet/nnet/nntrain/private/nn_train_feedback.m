function [] = nn_train_feedback(command,net,varargin)

% Copyright 2007-2008 The MathWorks, Inc.

showWindow = net.trainParam.showWindow;
showCommandLine = net.trainParam.showCommandLine;

% No Java Compatibility
if ~usejava('swing')
  if (showWindow)
    showCommandLine = true;
    showWindow =  false;
  end
end

% NNT 5.1 Backward Compatibility
if isnan(net.trainParam.show)
  showCommandLine = false;
end

switch command
  
  case 'start'
    
    algorithms = {net.trainFcn,net.performFcn,net.divideFcn};
    [status] = deal(varargin{:});
    if (showWindow)
      nntraintool('start',net,algorithms,status);
    end
    if (showCommandLine)
      disp(' ')
      disp(['Training with ' upper(net.trainFcn) '.']);
    end
    
  case 'update'
    
    [status,tr,signals,status_values] = deal(varargin{:});
    if (showWindow)
      nntraintool('update',net,tr,signals,status_values);
    end
    
    if (showCommandLine)
      doStop = ~isempty(tr.stop);
      doShow = (rem(tr.num_epochs,net.trainParam.show)==0) || doStop;
      if (doShow)
        numStatus = length(status);
        s = cell(1,numStatus*2-1);
        for i=1:length(status)
          s{i*2-1} = train_status_str(status(i),status_values(i));
          if (i < numStatus), s{i*2} = ', '; end
        end
        disp([s{:}])
      end
      if doStop
        disp(['Training with ' upper(net.trainFcn) ' completed: ' tr.stop])
        disp(' ');
      end
    end
end

%%
function str = train_status_str(status,value)

if ~isfinite(status.max)
  str = [status.name ' ' num2str(value)];
else
  str = [status.name ' ' num2str(value) '/' num2str(status.max)];
end
