%% Crab Classification
% This demo illustrates using a neural network as a classifier to identify
% the sex of crabs from physical dimensions of the crab.

%   Copyright 2003-2008 The MathWorks, Inc.
%   $Revision: 1.1.8.10 $  $Date: 2008/06/20 08:04:08 $ 


%% The Problem: Classification of Crabs
% In this demo we attempt to build a classifier that can identify the sex
% of a crab from its physical measurements. Six physical characterstics of
% a crab are considered: species, frontallip, rearwidth, length, width and
% depth. The problem on hand is to identify the sex of a crab given the
% observed values for each of these 6 physical characterstics.
%
%% Why Neural Networks?
% Neural networks have proven themselves as proficient classifiers and are
% particularly well suited for addressing non-linear problems. Given the
% non-linear nature of real world phenomena, like crab classification,
% neural networks is certainly a good candidate for solving the problem.
%
% The six physical characterstics will act as inputs to a neural network
% and the sex of the crab will be target. Given an input, which constitutes
% the six observed values for the physical characterstics of a crab, the
% neural network is expected to identify if the crab is male or female.
%
% This is achieved by presenting previously recorded inputs to a neural
% network and then tuning it to produce the desired target outputs. This
% process is called neural network training.
%
%% Preparing the Data
% Data for classification problems can very often have textual or
% non-numeric information. In our case, sex of the crab is non-numeric
% (Male/Female). Neural networks however cannot be trained with non-numeric
% data. Hence we need to translate the textual data into a numeric form. 
%
% There are several ways to translate textual or symbolic data into numeric
% data. Some of the common symbol translation techniques used are unary
% encoding, binary encoding and numbering classes. We are going to use
% unary encoding in this demo to perform symbol translation. 

fid = fopen('private/crabdata.csv');
C = textscan(fid,'%f%f%f%f%f%f%s','delimiter',',');  % Import data
fclose(fid);

%%
% The first 6 columns of data represent the crab's physical characterstics.
% The 7th column represents the sex of the crab.

physchars = [C{1} C{2} C{3} C{4} C{5} C{6}]; % inputs to neural network

female = strncmpi(C{7}, 'Female', 1);
male = strncmpi(C{7}, 'Male', 1);

sex = double([female male]);                 % targets for neural network

%%
% 'Female' is now represented by the vector [1 0] and 'Male' is represented
% by the vector [0 1]. This process is called unary encoding. The neural
% network will now be trained to produce a [1 0] output for 'Female' crabs
% and [0 1] output for 'Male' crabs.
%
% We could also have used numbers to represent the two sexes (Male=1,
% Female=2) or performed binary encoding (Male=[0 0], Female=[0 1]).
%
% The next step is to preprocess the data into a form that can be used with
% a neural network.
%
% The neural network object in the toolbox expects the samples along
% columns and its features along rows. Our dataset has its samples along
% rows and its features along columns. Hence the matrices have to be
% transposed.

physchars = physchars';
sex = sex';

%% Building the Neural Network Classifier
% The next step is to create a neural network that will learn to identify
% the sex of the crabs.
%
% Since the neural network starts with random initial weights, the results
% of this demo will differ slightly every time it is run. The random seed
% is set to avoid this randomness. However this is not necessary for your
% own applications.

rand('seed', 491218382)

%%
% A 1-hidden layer feed forward network is created with 20 neurons in the
% hidden layer.
%

net = newff(physchars,sex,20); % Create a new feed forward network

%%
% Now the network is ready to be trained. The samples are automatically
% divided into training, validation and test sets. The training set is
% used to teach the network. Training continues as long as the network
% continues improving on the validation set. The test set provides a
% completely independent measure of network accuracy.

[net,tr] = train(net,physchars,sex);

%% Testing the Classifier
% The trained neural network can now be tested with the testing samples
% This will give us a sense of how well the network will do when applied
% to data from the real world.

testInputs = physchars(:,tr.testInd);
testTargets = sex(:,tr.testInd);

out = sim(net,testInputs);        % Get response from trained network

%%
% The network response can now be compared against the desired target
% response to build the classification matrix which will provides a
% comprehensive picture of a classifiers performance.

[y_out,I_out] = max(out);
[y_t,I_t] = max(testTargets);

diff = [I_t - 2*I_out];

f_f = length(find(diff==-1));     % Female crabs classified as Female
f_m = length(find(diff==0));      % Female crabs classified as Male
m_m = length(find(diff==-2));     % Male crabs classified as Male
m_f = length(find(diff==-3));      % Male crabs classified as Female

N = size(testInputs,2);               % Number of testing samples
fprintf('Total testing samples: %d\n', N);

cm = [f_f f_m; m_f m_m]           % classification matrix

%%
% The classification matrix provides a comprehensive picture of the
% classification performance of the classifier. The ideal classification
% matrix is the one in which the sum of the diagonal is equal to the number
% of samples.
%
% It can also be understood in terms of percentages. The following matrix
% provides the same information as above but in terms of percentages. 

cm_p = (cm ./ N) .* 100          % classification matrix in percentages

fprintf('Percentage Correct classification   : %f%%\n', 100*(cm(1,1)+cm(2,2))/N);
fprintf('Percentage Incorrect classification : %f%%\n', 100*(cm(1,2)+cm(2,1))/N);

%%
% This demo illustrated using a neural network to classify crabs.
%
% Explore other demos and the documentation for more insight into neural
% networks and its applications. 



displayEndOfDemoMessage(mfilename)