%APPCR1 Character recognition.

% Mark Beale, 12-15-93
% Copyright 1992-2007 The MathWorks, Inc.
% $Revision: 1.15.2.3 $  $Date: 2008/12/01 07:20:26 $

clf;
figure(gcf)

echo on


%    NEWFF   - Creates feed-forward networks.
%    SIM   - Simulates feed-forward networks.

%    CHARACTER RECOGNITION:

%    Using the above functions a feed-forward network is trained
%    to recognize character bit maps, in the presence of noise.

pause % Strike any key to continue...

%    DEFINING THE MODEL PROBLEM
%    ==========================

%    The script file PRPROB defines a matrix ALPHABET
%    which contains the bit maps of the 26 letters of the
%    alphabet.

%    This file also defines target vectors TARGETS for
%    each letter.  Each target vector has 26 elements with
%    all zeros, except for a single 1.  A has a 1 in the
%    first element, B in the second, etc.

[alphabet,targets] = prprob;

pause % Strike any key to define the network...

%    DEFINING THE NETWORK
%    ====================

%    The character recognition network will have 25 TANSIG
%    neurons in its hidden layer.

net = newff(alphabet,targets,25);

pause % Strike any key to train the network...

%    TRAINING THE NETWORK WITHOUT NOISE
%    ==================================

%    The network will be trained without dividing data up into
%    training and validation sets, because this is a small problem
%    with only 26 samples.
%
%    Training begins...please wait...

net1 = net;
net1.divideFcn = '';
[net1,tr] = train(net1,alphabet,targets);

%    ...and finally finishes.

pause % Strike any key to train the network with noise...

%    TRAINING THE NETWORK WITH NOISE
%    ===============================

%    The network will be trained on the original letters
%    along with 10 sets of noisy letters.

numNoisy = 10;
alphabet2 = [alphabet repmat(alphabet,1,numNoisy)+randn(35,26*numNoisy)*0.2];
targets2 = [targets repmat(targets,1,numNoisy)];
net2 = train(net,alphabet2,targets2);

%    ...and finally finishes.

pause % Strike any key to finish training the network...

% SET TESTING PARAMETERS
noise_range = 0:.05:.5;
max_test = 100;
network1 = [];
network2 = [];

% PERFORM THE TEST
for noiselevel = noise_range
  fprintf('Testing networks with noise level of %.2f.\n',noiselevel);
  errors1 = 0;
  errors2 = 0;

  for i=1:max_test
    x = alphabet + randn(35,26)*noiselevel;

    % TEST NETWORK 1
    y = sim(net1,x);
    yy = compet(y);
    errors1 = errors1 + sum(sum(abs(yy-targets)))/2;

    % TEST NETWORK 2
    yn = sim(net2,x);
    yyn = compet(yn);
    errors2 = errors2 + sum(sum(abs(yyn-targets)))/2;
    echo off
  end

  % AVERAGE ERRORS FOR 100 SETS OF 26 TARGET VECTORS.
  network1 = [network1 errors1/26/max_test];
  network2 = [network2 errors2/26/max_test];
end
echo on

pause % Strike any key to display the test results...

%    DISPLAY RESULTS
%    ===============

%    Here is a plot showing the percentage of errors for
%    the two networks for varying levels of noise.

clf
plot(noise_range,network1*100,'--',noise_range,network2*100);
title('Percentage of Recognition Errors');
xlabel('Noise Level');
ylabel('Network 1 _ _   Network 2 ___');

%    Network 1, trained without noise, has more errors due
%    to noise than does Network 2, which was trained with noise.

echo off
disp('End of APPCR1')

 
