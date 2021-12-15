function fig = nn_find_tagged_figure(tag)
%NN_FIND_TAGGED_FIGURE Find figure with a given tag.

% Copyright 2007 The MathWorks, Inc.

if nargin<1, error('NNET:Argument','Not enough arguments.'); end
if ~ischar(tag),  error('NNET:Argument','Tag is not char.'); end

for object = get(0,'children')'
  if strcmp(get(object,'type'),'figure') 
    if strcmp(get(object,'tag'),tag)
     fig = object;
     return
   end
  end
end
fig = [];
