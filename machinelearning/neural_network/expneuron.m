% eponential neuron activation function to be used with Matlab 7 or earlier
function a = expneuron(n,b)

if nargin < 1, error('Not enough arguments.'); end

% FUNCTION INFO
if isstr(n)
  switch (n)
    case 'deriv'
    a = 'dexpneuron';
    case 'name'
    a = 'Exp neuron';
    case 'output'
    a = [0.14 7.4];
    case 'active'
    a = [-2 2];
    case 'type'
    a = 1;        
    otherwise, error('Unrecognized code.')
  end
  return
end

% CALCULATION
a = exp(n);

