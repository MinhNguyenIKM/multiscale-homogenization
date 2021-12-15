function v=subsref(v,subscripts)
%SUBSREF Reference fields of a neural network.

%  Mark Beale, 11-31-97
%  Copyright 1992-2008 The MathWorks, Inc.
% $Revision: 1.7.4.5 $

% Assume no error
err = '';

% Short hand fields
%type = subscripts(1).type;
%subs = subscripts(1).subs;

% For each level of subscripts
for i=1:length(subscripts)

  type = subscripts(i).type;
  subs = subscripts(i).subs;
  
  switch type
  
  % Paretheses
  case '()'
    try
      eval('v=v(subs{:});');
    catch me
      err = me.message;
    end
  
  % Curly bracket
  case '{}'
    try
      eval('v=v{subs{:}};');
    catch me
      err = me.message;
    end
  
  % Dot
  case '.'
    if isa(v,'struct') || isa(v,'network')
      
      % NNT 5.0 Backward compatibility
      if strcmpi(subs,'numTargets')
        subs = 'numOutputs';
        nntobsu(mfilename,'"numTargets" is obsolete.',...
          'Use "numOutputs" to determine numbers of outputs and targets.');
      elseif strcmpi(subs,'targetConnect')
        subs = 'outputConnect';
        nntobsu(mfilename,'"targetConnect" is obsolete.',...
          'Use "outputConnect" to determine connections for outputs and targets.');
      elseif strcmpi(subs,'targets')
        subs = 'outputs';
        nntobsu(mfilename,'"targets" is obsolete.',...
          'Use "outputs" to determine properties of outputs and targets.');
      end
      
      f = fieldnames(v);
      for j=1:length(f)
        if strcmpi(subs,f{j})
          subs = f{j};
          break;
        end
      end
    end

    try
      eval(['v=v.' subs ';'])
    catch me
     err= me.message;
    end
  end
  
  % Error message
  if ~isempty(err)
 
   % Work around: remove any reference to variable V
   ind = findstr(err,' ''v''');
    if (ind)
      err(ind+(0:3)) = [];
    end
  
  error('NNET:subsref:referencing',err)
  end
end

