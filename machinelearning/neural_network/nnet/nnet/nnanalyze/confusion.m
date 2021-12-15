function [c,cm,ind,per] = confusion(targets,outputs)
%CONFUSION Classification confusion matrix.
%
% Syntax
%
%   [c,cm,ind,per] = confusion(targets,outputs)
%
% Description
%
%   [C,CM,IND,PER] = CONFUSION(TARGETS,OUTPUTS)takes these values,
%      TARGETS - SxQ matrix, where each column vector contains a
%        single 1 value, with all other elements 0. The index of the 1
%        indicates which of S categories that vector represents.
%      OUTPUTS - SxQ matrix , where each column contains values in the
%        range [0.1]. The index of the largest element in the column
%        indicates which of S categories that vector presents.
%    and returns these values:
%      C - Confusion value = fraction of samples misclassified.
%      CM - SxS confusion matrix, where cm(i,j) is number of samples
%        whose target is the ith class were classified as j.
%      IND - SxS cell array, where IND{i,j} contains the indices
%        of samples with the ith target class, but jth output class.
%      per - Sx3 matrix where each ith row represents the percentage
%        of false negatives, false positives, and true positives for
%        the ith category.
%
%   [C,CM,IND,PER] = CONFUSION(TARGETS,OUTPUTS)takes these values,
%      TARGETS - 1xQ vector of 1/0 values representing membership.
%      OUTPUTS - SxQ matrix, of value in [0.1] interval, where values
%        greater-or-equal to 0.5 indicate class membership.
%    and returns these values:
%      C - Confusion value = fraction of samples misclassified.
%      CM - 2x2 confusion matrix.
%      IND - 2x2 cell array, where IND{i,j} contains the indices
%        of samples whose target is 1 vs. 0, and whose output was
%        greater-or-equal to 0.5 vs. less than 0.5.
%      per - 2x3 matrix where each ith row represents the percentage
%        of false negatives, false positives, and true positives for
%        the class and out-of-class.
%
%  Examples
%
%    load simpleclass_dataset
%    net = newpr(simpleclassInputs,simpleclassTargets,20);
%    net = train(net,simpleclassInputs,simpleclassTargets);
%    simpleclassOutputs = sim(net,simpleclassInputs);
%    [c,cm,ind,per] = confusion(simpleclassTargets,simpleclassOutputs)
%
% See also PLOTCONFUSION, ROC

% Copyright 2007-2008 The MathWorks, Inc.

if nargin < 2
  error('NNET:Arguments','Not enough input arguments.');
end
if any(size(targets)~=size(outputs))
  error('NNET:Arguments','Targets and outputs have different dimensions.')
end
if ~all((targets==0) | (targets==1))
  error('NNET:Arguments','Targets are not all 1/0 values.')
end
if ~all((outputs>=0) | (outputs<=1))
  error('NNET:Arguments','Outputs are not all within a [0,1] interval.')
end

[numClasses,numSamples] = size(outputs);

if (numClasses == 1)
  targets = [targets; 1-targets];
  outputs = [outputs; 1-outputs-eps*(outputs==0.5)];
  [c,cm,ind,per] = confusion(targets,outputs);
  return;
end

% Transform outputs
outputs = compet(outputs);

% Confusion value
c = sum(sum(targets ~= outputs))/2/numSamples;
c = full(c);

% Confusion matrix
if nargout < 2, return, end
cm = zeros(numClasses,numClasses);
i = vec2ind(targets);
j = vec2ind(outputs);
for k=1:numSamples
  cm(i(k),j(k)) = cm(i(k),j(k)) + 1;
end

% Indices
if nargout < 3, return, end
ind = cell(numClasses,numClasses);
for k=1:numSamples
  ind{i(k),j(k)} = [ind{i(k),j(k)} k];
end

% Percentages
if nargout < 4, return, end
per = zeros(numClasses,3);
for i=1:numClasses,
  tot = sum(cm(i,:));
  per(i,1) = sum(cm(i,[1:(i-1) (i+1):numClasses]))/tot;
  per(i,2) = sum(cm([1:(i-1) (i+1):numClasses],i))/tot;
  per(i,3) = cm(i,i)/tot;
end
