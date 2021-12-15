function [simpleclusterInputs,simpleclusterTargets] = create_simplecluster()

% Copyright 2007-2008 The MathWorks, Inc.

centerx = [0 0 1 1];
centery = [0 1 0 1];
radius = [0.7 0.6 0.3 0.7];

numSamples = 1000;
x = zeros(2,numSamples);
t = zeros(4,numSamples);
for i=1:numSamples
  j = floor(rand*4)+1;
  t(j,i) = 1;
  angle = rand*2*pi;
  r = (rand.^0.8)*radius(j);
  x(1,i) = centerx(j) + cos(angle)*r;
  x(2,i) = centery(j) + sin(angle)*r;
end
 
simpleclusterInputs = x;
simpleclusterTargets = t;
