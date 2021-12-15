%NNSAMPLE Sample Training Session

% Copyright 1994-2005 PWS Publishing Company and The MathWorks, Inc.
%   $Revision: 1.3.2.1 $  $Date: 2005/12/22 18:18:44 $

figure(gcf)
clf;
echo on
clc

%    ==========================================================
%    NNSAMPLE  Sample Training Session
%    ==========================================================

%    MAPMINMAX  - Normalize data for zero mean and unity standard deviation.
%    PROCESSPCA  - Principal components analysis.
%    NEWFF   - Inititializes feed-forward networks.
%    TRAIN   - Trains a network.
%    SIM     - Simulates networks.

%    NONLINEAR REGRESSION:

%    Using the above functions a feed-forward network is trained
%    to perform a nonlinear regression between spectral components
%    and cholesterol levels.  The final network is analyzed to
%    investigate overall performance.

pause % Strike any key to continue...
clc

%    DEFINING THE PROBLEM
%    ====================

%    The .mat file CHOLES_ALL contains matrices
%    P and T.  The P matrix contains the network inputs,
%    which are 21 measured spectral components of 264 blood samples.
%    The T matrix contains the corresponding targets, which are
%    3 cholesterol levels: ldl, vldl and hdl.

% Load in the data file
load choles_all

% Normalize the inputs and targets so that they have
% zero mean and unity variance.
[pn,pp1] = mapstd(p);
[tn,tp] = mapstd(t);

% Perform a principal component analysis and remove those
% components which account for less than 0.1% of the variation.
[ptrans,pp2] = processpca(pn,0.001);

pause % Strike any key to divide the data...
clc

% Divide the data up into training, validation and test sets.
% The testing set will start with the second point and take
% every fourth point.  The validation set will start with the
% fourth point and take every fourth point.  The training set
% will take the remaining points.
[R,Q] = size(ptrans);
iitst = 2:4:Q;
iival = 4:4:Q;
iitr = [1:4:Q 3:4:Q];
validation.P = ptrans(:,iival);
validation.T = tn(:,iival);
testing.P = ptrans(:,iitst);
testing.T = tn(:,iitst);
ptr = ptrans(:,iitr);
ttr = tn(:,iitr);

pause % Strike any key to define the network...
clc
%    DEFINING THE NETWORK
%    ====================

% Create a feedforward network with 5 hidden neurons, 3 output
% neurons, TANSIG hidden neurons and linear output neurons.  Here
% we assign the Levenberg-Marquardt training function - TRAINLM.  You
% can replace TRAINLM with any training function you desire. The NEWFF
% command will also initialize the weights in the network.
net = newff(minmax(ptr),[5 3],{'tansig' 'purelin'},'trainlm');

pause % Strike any key to train the network...
clc

%    TRAINING THE NETWORK
%    ====================

% Before training the network you may want to change some of the training
% parameters from their default values.  Here we change only the
% show parameter.
net.trainParam.show = 5;    % Show intermediate results every five iterations.

%    Training begins...please wait...

% Train the network.  We use early stopping, so we are passing the
% validation data.  We also want the errors computed on a test
% set, so we are passing the testing data.
[net,tr]=train(net,ptr,ttr,[],[],validation,testing);

pause % Strike any key to test the networks...
clc
%    TESTING THE NETWORK
%    ====================

% Plot the training, validation and test errors.
plot(tr.epoch,tr.perf,'r',tr.epoch,tr.vperf,':g',tr.epoch,tr.tperf,'-.b')
legend('Training','Validation','Test',-1);
ylabel('Squared Error')

% Simulate the trained network.
an = sim(net,ptrans);

% Convert the output of the network back into the original units
% of the targets.  Since the targets were transformed using MAPSTD so
% that the mean was 0 and the standard deviation was 1, we need to
% use MAPSTD and the original mean and standard deviation (stored
% in tp) to transform the network outputs back into the original units.
a = mapstd('reverse',an,tp);

pause % Strike any key to display the regression analysis...
clc
%    DISPLAY RESULTS
%    ===============

%    We will now display plots showing regression analyses between the
%    network outputs and the corresponding targets (in original units).


for i=1:3

    pause % Strike any key to display the next output...
    clc
  [m(i),b(i),r(i)] = postreg(a(i,:),t(i,:));


end

echo off
disp('End of NNSAMPLE')
