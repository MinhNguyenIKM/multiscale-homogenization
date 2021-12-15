%% Cancer Detection
% This example demonstrates using a neural network to detect cancer from
% mass spectrometry data on protien profiles.

%   Copyright 2003-2008 The MathWorks, Inc.
%   $Revision: 1.1.8.7 $  $Date: 2008/06/20 08:04:07 $

%% Introduction
% Serum proteomic pattern diagnostics can be used to differentiate samples
% from patients with and without disease. Profile patterns are generated
% using surface-enhanced laser desorption and ionization (SELDI) protein
% mass spectrometry. This technology has the potential to improve clinical
% diagnostics tests for cancer pathologies. 

%%
% You need the bioinformatics toolbox to run this demo. 

if isempty(ver('bioinfo'))
    errordlg('This demo requires the Bioinformatics Toolbox.');
    return;
end

%% The Problem: Cancer Detection
% The goal is to build a classifier that can distinguish between cancer and
% control patients from the mass spectrometry data. 
%
% The methodology followed in this demo is to select a reduced set of
% measurements or "features" that can be used to distinguish between cancer
% and control patients using a classifier. 
%
% These features will be ion intensity levels at specific mass/charge
% values.

%% The Data
% The data in this example is from the FDA-NCI Clinical Proteomics Program
% Databank (http://home.ccr.cancer.gov/ncifdaproteomics/ppatterns.asp).
% This example uses the high-resolution ovarian cancer data set that was
% generated using the WCX2 protein array.
%
% This demonstration assumes that you downloaded, uncompressed, and
% preprocessed the raw mass-spectrometry data from the FDA-NCI web site.
% You can recreate the preprocessed data file OvarianCancerQAQCdataset.mat,
% needed for this demo, by either running the script *msseqprocessing*, or,
% by following the steps in the demo *biodistcompdemo* (Batch processing
% through parallel computing).
%
% The preprocessing steps from the script and demo listed above are
% intended to demonstrate a representative set of possible pre-processing
% procedures. Using different steps or parameters may lead to different and
% possibly improved results of this demonstration.

load OvarianCancerQAQCdataset.mat
whos

%%
% Each column in |Y| represents measurements taken from a patient. There
% are |216| columns in |Y| representing |216| patients, out of which |121|
% are ovarian cancer patients and |95| are normal patients.
%
% Each row in |Y| represents the ion intensity level at a specific
% mass-charge value indicated in |MZ|. There are |15000| mass-charge values
% in |MZ| and each row in |Y| represents the ion-intesity levels of the
% patients at that particular mass-charge value.
%
% The variable |grp| holds the index information as to which of these
% samples represent cancer patients and which ones represent normal
% patients.
%
% An extensive description of this data set and excellent introduction to
% this promising technology can be found in [1] and [2].

%% Ranking Key Features
% This is a typical classification problem in which the number of features
% is much larger than the number of observations, but in which no single
% feature achieves a correct classification, therefore we need to find a
% classifier which appropriately learns how to weight multiple features and
% at the same time produce a generalized mapping which is not over-fitted.
%
% A simple approach for finding significant features is to assume that each
% M/Z value is independent and compute a two-way t-test. *rankfeatures*
% returns an index to the most significant M/Z values, for instance 100
% indices ranked by the absolute value of the test statistic.

[feat,stat] = rankfeatures(Y,grp,'CRITERION','ttest','NUMBER',100);


%% Classification Using a Feed Forward Neural Network
% Now that you have identified some significant features, you can use this
% information to classify the cancer and normal samples. 
%
% First, the data is separated into inputs and targets. The significant
% features identified will act as the inputs to the neural network. The
% targets for the neural network will be the logical indices of cancer
% samples. Cancer samples will hence be identified with |1|'s and normal
% samples will be identified with |0|'s.

P = double(Y(feat, :));      % Inputs
Cidx = strcmp('Cancer',grp); % Logical index vector for Cancer samples
T = double(Cidx)';           % Targets


%%
% Since the neural network is initialized with random initial weights, the
% results after training the network vary slightly every time the demo is
% run. To avoid this randomness, the random seed is set to reproduce the
% same results every time. However this is not necessary for your own
% applications.

rand('seed', 672880951)

%%
% A 1-hidden layer feed forward neural network with 5 hidden layer neurons
% is created and trained. The input and target samples are automatically
% divided into training, validation and test sets. The training set is
% used to teach the network. Training continues as long as the network
% continues improving on the validation set. The test set provides a
% completely independent measure of network accuracy.

net = newff(P,T,5);                        % create neural network
[net,tr] = train(net,P,T); % train network

%%
% The trained neural network can now be tested with the testing samples we
% partitioned from the main dataset using |dividevec|. The testing data is
% not used in training in any way and hence provides an "out-of-sample"
% dataset to test the network on.This will give us a sense of how well the
% network will do when tested with data from the real world.

testInputs = P(:,tr.testInd);
testTargets = T(:,tr.testInd);

out = round(sim(net,testInputs));           % Get response of trained network

%%
% The classification matrix provides a comprehensive picture of the
% classifiers performance. The ideal classification matrix is the one in
% which the sum of the diagonal is equal to the number of samples.

diff = [testTargets - 2*out];

detections = length(find(diff==-1));        % cancer samples classified as cancerous
false_positives = length(find(diff==1));    % cancer samples classified as normal
true_positives = length(find(diff==0));     % normal samples classified as normal
false_alarms = length(find(diff==-2));      % normal samples classified as cancerous

Nt = size(testInputs,2);                    % Number of testing samples
fprintf('Total testing samples: %d\n', Nt);

%classification matrix
cm = [detections false_positives; false_alarms true_positives] 
 
%%
% It can also be understood in terms of percentages. The following matrix
% provides the same information as above but in terms of percentages. 

cm_p = (cm ./ Nt) .* 100                   % classification matrix in percentages

%%
fprintf('Percentage Correct classification   : %f%%\n', 100*(cm(1,1)+cm(2,2))/Nt);
fprintf('Percentage Incorrect classification : %f%%\n', 100*(cm(1,2)+cm(2,1))/Nt);


%%
% This demo illustrated how neural networks can be used as classifiers
% for cancer detection. One can also experiment using techniques like
% principal component analysis to reduce the dimensionality of the data
% to be used for building neural networks to improve classifier
% performance. 
%

%% References
% [1] T.P. Conrads, et al., "High-resolution serum proteomic features for
%     ovarian detection", Endocrine-Related Cancer, 11, 2004, pp. 163-178.
%%
% [2] E.F. Petricoin, et al., "Use of proteomic patterns in serum to
%     identify ovarian cancer", Lancet, 359(9306), 2002, pp. 572-577.

%%
% *<mailto:bioinfo-feedback@mathworks.com?subject=Feedback%20for%20CANCERDETECTDEMO%20in%20Bioinformatics%20Toolbox%202.1.1 Provide feedback for this demo.>*


displayEndOfDemoMessage(mfilename)