% function RS_HDMR_NN fits RS-HDMR-NN to data using independent NNs for component functions. 
% The first hidden layer of each NN perfoms a linear transformation of the coordinates,
% and the second hidden layer perfoms a nonlinear fit in the new coordinates.
% trainset and testset are filenames for the training and validation/test data,
% where each line is a fitting point - first columns are coords, and the last
% column is the function value. When not using a second data set, pass for
% testset the same string as for trainset
% label is a string that will be attached to the output filenames, e.g
% [label '_3_NNs.dat']
% tolerance is an array of rmse for each fitting stage (mode-term) - see Eq. (8) of the article
% Nnodesini is an array of the number of nodes for corresponding mode-terms
% Ecut is an array of max energy to which to cut the data for corresponding
% mode-terms, and npointsmax means using the first npointsmax points of the
% data file or all, whichever is less (same number for fit and test/validation if npointsmax is a scalar, different numbers of points
% if it is a 2-component vector, npointsmax(3), if passed, is the number of points in a batch trained at each cycles).
% The following parametes are optional:
% - neuron specifies the activation function in the non-linear layers ('tansig' by default)
% ATTENTION! the neuron definition is MatLab's version-dependent. We provide two functions for the user-defined exponential neuron:
%   expneuron2.m for MatLab R2007b
%   expneuron.m  for earlier versions (tested on version 7.0 R14) 
% - cyclemax specifies how many times the fit cycles over all component functions (50 by default)
% - epochsinseq is number of training epochs in each cycles for each component function (5 by default)
% - ifRegularisation, if 1 (which is also the default), makes NNs use trainbr/msereg training
% - ifTestPtsSameFile, of 1, draws test points from the same file as fit points
% - the name of the transfer function of the coordinate transformation layer
% - the name of the transfer function of the partial NN output layer
% - a logical parameter to use test(1) or validation (0) set 
% In this code, the number of HDMR component functions in each mode-term is user-defined by the vector parameter Nfunctions
% each partial NN fits in new coordinates which are linear combinations of the original coordinates. Consequently, each has four layers:
% - the input layer that receives and relays all original coordinates without transformation
% - the coordinate transformation layer of linear neurons
% - the non-linear layer that fits the component functions in the new coordinates produced by the 2nd layer
% - a linear one-neuron component function output layer
%
% for example, call
% D=2
% npoints=[2000 7000]
% fns=3
% N=10
% neuron='tansig'
% cyclemax=20
% epochsinseq=10
% ifRegularisation=0
% a=RS_HDMR_NN('H2O_20000cm_10000pts_unsym_qdgb.dat', 'H2O_20000cm_10000pts_unsym_qdgb.dat', ['H2Otest'], ones(1,3), [zeros(1,D-1) N], 15000*ones(1,6), npoints,
% [zeros(1,D-1) fns], neuron, cyclemax, epochsinseq, ifRegularisation);
%
% to fit 3D data from file H2O_20000cm_10000pts_unsym_qdgb.dat (sampled of the water PES by Jensen) 
% using points below 15000, using 2000 fitting points and 7000 test points
% (which will be drawn randomly from the same file), using 3 2-dimensional sigmoid NNs with 10 neurons each, cycling 20 times through all
% component functions, fitting for 10 epochs each NN within each cycle, and using 2000 points (randomly redrawn from the 8000 in each cycle)
% to train the NNs in each cycle
%
% or use the supplied file test_run_water.m
% 
% the program will export the fit function for use in other environments into a _NNs.dat file with the structure
% DimensionalityOfData    DimensionalityOfNNs    NumberOfNNs    NumberOfNeurons    NeuronCode(1=sigmoid, 2=exponential, 0=other)
% row vector of length DimensionalityOfData of minimum values of coordinates
% row vector of length DimensionalityOfData of maximum values of coordinates
% FunctionMin    FunctionMax
% matrix DimensionalityOfNNs x DimensionalityOfData of layer weights from the 1st to 2nd layer   -|
% matrix NumberOfNeurons x DimensionalityOfNNs of layer weights from the 2st to 3nd layer         |
% column of  NumberOfNeurons elements of layer weights from the 2st to 4nd layer                  |
% column of DimensionalityOfNNs elements of biases to the 2nd layer                               | repeated NumberOfNNs times
% column of DimensionalityOfNNs elements of biases to the 2nd layer                               |
% column of NumberOfNeurons elements of biabes to the 3rd layer                                   |
% bias to the 4th layer of 1 neuron which is the output of partial NN                            -|

function value=RS_HDMR_NN(trainset, testset, label, tolerance, Nnodesini, Ecut, npointsmax, Nfunctions, varargin);
global nn inputn targetn ndim Nnodes npoints
global unc testunc
warning off all
format short e
tightval=2;                                      % accepted difference between training and test sets' errors
TrainFunction='trainlm';

% introduce elements of sequential training:
% fit nbatch points randomly redrawn each time from the fitting set
if max(size(npointsmax))==3, 
    nbatch=min(npointsmax(1),npointsmax(3))
else
    nbatch=npointsmax(1)                  % by default fit all points in each partial fit   
end;
%same number of test points if not specified
if max(size(npointsmax))==1, npointsmax=[npointsmax npointsmax], end;

% assign optional parameters
try
    neuron=varargin{1};
catch
    neuron='tansig'
end;
try
    cyclemax=varargin{2};
catch
    cyclemax=50
end;
try
    epochsinseq=varargin{3};
catch
    epochsinseq=10
end;
try
    ifRegularisation=varargin{4};
catch
    ifRegularisation=0;                             % using or not Bayesian regularisation by default
end;
if ifRegularisation==1, message='using regularisation', end;
try
    ifTestPtsSameFile=varargin{5};
catch
    ifTestPtsSameFile=1;                            % draws test points from the same file as fit points, use if no separate test set available
end;
try
    CoordTransformNeuron=varargin{6}
catch
    CoordTransformNeuron='purelin'
end;
try
    PartialNNoutputNeuron=varargin{7}
catch
    PartialNNoutputNeuron='purelin'
end;
try
   ifTest=varargin{8}
catch
   ifTest=1 
end;

ifupdatenodes=0;                                    % changing or not the number of nodes of component functions after each cycle                                               % 0 - training with a validation set; 1 - training with a test set       
if ifTest==0, message='Using validation', end;

Nmodes=max(size(Nnodesini));                        % order of HDMR is determined by the size of the array containing numbers of nodes for mode-terms, see also below

rand('state', sum(100*clock));
data=dlmread(trainset); 
indices=randperm(max(size(data)));
if ifTestPtsSameFile,  % taking test points from the same file - the first in the parameter list;
    message='taking test points from the same file - the first in the parameter list'                          
    if max(size(data))>=npointsmax(1)+npointsmax(2),                 
        testdata=data(indices(1:npointsmax(2)),:);
        data=data( indices(npointsmax(2)+1:npointsmax(2)+npointsmax(1)),:);
    else
        message='not enough data for specified numbers of fitting and test points to be taken from the same file'
    end;
else % taking test points from the a separate file
    testdata=dlmread(testset);   
        % shuffle data in case they are ordered before taking npointsmax points        
        if max(size(data))>npointsmax(1),            
            indices=indices(1:npointsmax(1));             
            data=data(indices,:);
        else
            data=data(1:min(max(size(data)),npointsmax(1)),:);
        end;    
        % shuffle data in case they are ordered before taking npointsmax points
        if max(size(testdata))>npointsmax(2),    
            indices=randperm(max(size(testdata)));      
            indices=indices(1:npointsmax(2));             
            testdata=testdata(indices,:);
        else
            testdata=testdata(1:min(max(size(testdata)),npointsmax(2)),:);
        end;    
end; % taking test points from the same or a separate file

[npoints,ndim]=size(data); 		         % ndim returs # of columns of which the last is the potential value
[testnpoints, testndim]=size(testdata);
ndim=ndim-1;
Nmodes=min(Nmodes,max(size(tolerance)));
Nmodes=min(Nmodes,max(size(Ecut)))               % order of HDMR is determined by the min of the sizes of the arrays containing numbers of nodes, Ecut values, and tolerances for mode-terms
   data=sortrows(data,ndim+1);
   testdata=sortrows(testdata,ndim+1);

% form input and target arrays
target=data(:,ndim+1)';                          % extract potential values   
input=data(:,1:ndim)';                           % extract coordinates
testtarget=testdata(:,ndim+1)';                  % same for validation / test data
testinput=testdata(:,1:ndim)';   

clear data testdata % not needed beyond this point

% produce array of indices equal in length to Ecut that will contain the
% indices of the last target and testtarget elements below Ecut
for i=1:max(size(Ecut)),
    EcutTargetIndex(i)=sum((sign(Ecut(i)-target)+1)/2); 
    EcutTesttargetIndex(i)=sum((sign(Ecut(i)-testtarget)+1)/2);
end;        
    
% perform pre-analysis - bring the range to [-1, 1] for inputs and targets
[inputn,minp,maxp,targetn,mint,maxt] = premnmx(input,target); 
[testinputn] = tramnmx(testinput,minp,maxp);
[testtargetn] = tramnmx(testtarget,mint,maxt);

clear input target testinput testtarget  % not needed beyond this point

% normalised tolerance
tolerancen=tolerance*2/(maxt-mint);              % scaled error goal 

for i=1:Nmodes,                                  % for each order of HDMR
    
if (Nnodesini(i)>0),                             % if this mode-term is to be fitted    
    
    nn{i}.message='used';
    dlmwrite([label '_' num2str(i) '_NNs.dat'],[],'delimiter', '\t'); % to clean the file
    Nterms=Nfunctions(i);                        % number of terms in a Nth-mode term 
    
        range=[];
        for k=1:ndim,
            range=[range ; [-1 1]];              % due to use of premnmx above      
        end;
    
    nn{i}.net=cell(Nterms,1);                    % a cell array containing partial NNs

        nn{i}.inputs=inputn(:,1:EcutTargetIndex(i));               % scaled input coords for values below Ecut  
        nn{i}.testinputs=testinputn(:,1:EcutTesttargetIndex(i));   % same for the test set
        nn{i}.target=targetn(1:EcutTargetIndex(i));             
        nn{i}.testtarget=testtargetn(1:EcutTesttargetIndex(i));  

    % create a separate NN for each term
    for j=1:Nterms,
        nn{i}.net{j}=network;
        nn{i}.net{j}.numInputs=1;                % input of each NN is a combination of i variables        
        nn{i}.net{j}.numLayers=4;                % an input layer, a new coordinate layer, a non-linear multi-node layer and a one-node output linear layer
        nn{i}.net{j}.inputConnect(1,1)=1;        % connect the input to the input layer
        nn{i}.net{j}.inputs{1}.range=range;      % assign input ranges
        nn{i}.net{j}.layerConnect(2,1)=1;        % connect the input layer to the coordinate layer
        nn{i}.net{j}.layerConnect(3,2)=1;        % connect the coordinates layer to the 3rd (non-linear) layer
        nn{i}.net{j}.layerConnect(4,3)=1;        % connect the non-linear hidden layer to the 4th (partial NN output) layer
        nn{i}.net{j}.outputConnect(nn{i}.net{j}.numLayers)=1;           % NN output is the output of the 4th layer

        % the input layer, just to relay the coordinates
        nn{i}.net{j}.layers{1}.size=ndim;
        nn{i}.net{j}.layers{1}.transferFcn=CoordTransformNeuron; 

        % the coordinate transformation layer
        nn{i}.net{j}.layers{2}.size=min(i,ndim);
        nn{i}.net{j}.layers{2}.transferFcn=CoordTransformNeuron; 

        % the non-linear and output layers
        nn{i}.net{j}.layers{3}.size=Nnodesini(i);                       % each NN gets a number of nodes specifies by user in Nnodesini
        nn{i}.net{j}.layers{3}.transferFcn=neuron;   
        nn{i}.net{j}.layers{4}.size=1;                                  % the output layer has one
        nn{i}.net{j}.layers{4}.transferFcn=PartialNNoutputNeuron;       % a linear neuron generally

        nn{i}.net{j}.targetConnect(nn{i}.net{j}.numLayers)=1;           % the output of the output layer will be compared to the target (potential values)   
        nn{i}.net{j}.trainFcn=TrainFunction;                            % will be changed to 'trainbr' if using refgularisation
        nn{i}.net{j}.performFcn = 'mse';                                % will be changed to 'msereg' if ifRegularisation
        nn{i}.net{j}.initFcn='initlay';
        for k=1:nn{i}.net{j}.numLayers,
            nn{i}.net{j}.biasConnect(k)=1;                              % all layers are biased
            nn{i}.net{j}.layers{k}.initFcn='initnw';
        end;    
        nn{i}.net{j}.trainParam.goal=tolerancen(i).^2;                  % error target of the i'th mode-term
    end;  % for j=1:Nterms
        
    if ifRegularisation,
        ratio=0.9+0.1*(1-10/(Nterms*Nnodesini(i)));
        for j=1:Nterms,
            nn{i}.net{j}.trainFcn='trainbr'; 
            nn{i}.net{j}.performFcn = 'msereg';                     
            nn{i}.net{j}.performParam.ratio = ratio;                        % g: msereg=g*mse+(1-g)*msw            
            nn{i}.net{j}.trainParam.goal=nbatch*tolerancen(i).^2;                  % N.B.: rmserr computed below using .goal is not rmse because of the (1-g)*msw term
        end;
    end; 
        
    % these parameters are recommended by the Guide for use of early stopping
    % with LM
    for j=1:Nterms,
        nn{i}.net{j}.trainParam.mu=1;
        nn{i}.net{j}.trainParam.mu_dec=0.98; 
        nn{i}.net{j}.trainParam.mu_inc=1.02; 
        nn{i}.net{j}.trainParam.mem_reduc=4;
        nn{i}.net{j}.trainParam.epochs=epochsinseq;                  
        nn{i}.net{j}.trainParam.show=NaN;
        if isunix, 
            nn{i}.net{j}.trainParam.show = NaN;  % suppress graphic output when running on the server
        end;
        nn{i}.net{j}=init(nn{i}.net{j});         % initialise weights and biases
        % reset unlearnable weights after initialisation
        nn{i}.net{j}.IW{1}=eye(ndim);
        nn{i}.net{j}.b{1}=zeros(ndim,1);     
        nn{i}.net{j}.biases{1}.learn=0;
        nn{i}.net{j}.inputWeights{1}.learn=0;
            % set partial NN output to zero initially
            nn{i}.net{j}.LW{4,3}=rand(size(nn{i}.net{j}.LW{4,3}))*1e-10; 
            nn{i}.net{j}.b{4}=rand(1,1)*1e-10;
            nn{i}.net{j}.LW{3,2}=rand(size(nn{i}.net{j}.LW{3,2}))*1e-10;
            nn{i}.net{j}.b{3}=rand(size(nn{i}.net{j}.b{3}))*1e-10;
    end; % for j=1:Nterms
                                        
    if strcmp(testset,trainset), VV=[]; end;     % void the validation set if is the same as the training set
    
    reachedn=2*tightval*tolerancen(i);           % set the current fit error high enough so that the cycle could start
    vreachedn=2*tightval*reachedn;        
                                                    
    if ((reachedn>tolerancen(i))|(vreachedn>=tightval*reachedn)),                                  % if target error is not yet achieved
        
       BeganFit=fix(clock)                                                                         % time execution
       TermImportance=zeros(Nterms,1);          
 
 % which component functions are fitted
 whichj{i}=1:Nterms;      
 
       for cycle=1:cyclemax,                     % cycle through sequential fits
           message=['***************** STARTING CYCLE ' num2str(cycle) '*********************']

                % use a smaller random selection of fitting points to achieve a combination of batch and sequential learning                
                VVbatch=[];
                if  nbatch>EcutTargetIndex(i),
                    message=['Attention: EcutTargetIndex(i)=' num2str(EcutTargetIndex(i)) ' is less than nbatch']
                    indices=1:EcutTargetIndex(i);
                else                    
                    indices=randperm(EcutTargetIndex(i));                                           
                    indices=indices(1:nbatch); 
                    if nnz(indices-1)==nbatch, indices(1)=1; end;     % to maintain the range, add the first element if it is not randomly selected
                    if nnz(indices-min(npointsmax(1),EcutTargetIndex(i)))==nbatch, indices(nbatch)=min(npointsmax(1),EcutTargetIndex(i)); end;                         
                    %VVbatch.P=nn{i}.inputs;   
                    %VVbatch.T=nn{i}.target;
                end; 

           % ******test errors*******************************************************
           nntargettest=nn{i}.target;         
           testerror=nn{i}.testtarget;                          
           for k=whichj{i},                                       
               nntargettest=nntargettest-sim(nn{i}.net{k},nn{i}.inputs); 
               testerror=testerror-sim(nn{i}.net{k},nn{i}.testinputs);
           end;          
           nntargettest=nntargettest*(mint-maxt)/2; 
           testerror=testerror*(mint-maxt)/2;
           error_b4_this_cycle=sqrt(mean(nntargettest.^2))
           test_error_b4_this_cycle=sqrt(mean(testerror.^2)) 
           %*************************************************************************

           %******to 'equilibrate' component functions, phase in the no. of epochs***                      
           if cyclemax>1,
               epochs=min(round(epochsinseq*(cycle/5)+1),epochsinseq)
           else
               epochs=epochsinseq;
           end;    
           for j=1:Nterms,               
               nn{i}.net{j}.trainParam.epochs=epochs; 
           end;           
           %*************************************************************************   
       
       for j=randperm(Nterms), %(whichj{i}),            % sequential terms fit    
           
           % fitting_term=j
           nntarget=nn{i}.target;
           %nntarget_b4_subtr=sqrt(mean(nntarget.^2))
           VV.T=nn{i}.testtarget;  
           % fit the jth NN to target-sum_k<>j(sim_k)
           for k=whichj{i},  
               if (k~=j),   
                   nntarget=nntarget-sim(nn{i}.net{k},nn{i}.inputs);  
                   VV.T=VV.T-sim(nn{i}.net{k},nn{i}.testinputs);
               end;
           end;
           %nntarget_after_subtr=sqrt(mean(nntarget.^2))

           %******to 'equilibrate' component functions, don't fit all variance in the beginning***
           if cyclemax>1, nntarget=nntarget/Nterms*min(cycle/5*Nterms,Nterms); end;
           %**************************************************************************************

           input=nn{i}.inputs;
           VV.P=nn{i}.testinputs;           

                % use a smaller random selection of fitting points to achieve a combination of batch and sequential learning                
                traininput=input(:,indices); 
                traintarget=nntarget(:,indices); 

           if ifTest,                               % with a test set
               [nn{i}.net{j},tr{j},outputn{j},errorsn] = train(nn{i}.net{j},traininput,traintarget,[],[],VVbatch,VV);
               vreachedn=tr{j}.tperf(max(size(tr{j}.tperf)));
           else                                     % with a validation set
               [nn{i}.net{j},tr{j},outputn{j},errorsn] = train(nn{i}.net{j},traininput,traintarget,[],[],VV,[]);
               vreachedn=tr{j}.vperf(max(size(tr{j}.vperf)));
           end;           

         % test rmse of the component function directly
         bla=(traintarget-sim(nn{i}.net{j},traininput))*(maxt-mint)/2;         
         rmse_directly_comp_fn(j,1)=sqrt(mean(bla.^2));         
         bla=(nntarget-sim(nn{i}.net{j},nn{i}.inputs))*(maxt-mint)/2;         
         rmse_directly_comp_fn_all_pts=sqrt(mean(bla.^2)); 
         if 1, 
             message=['current term=' num2str(j) ', rmse (directly, batch/all points)=' num2str(rmse_directly_comp_fn(j,1)) '/' num2str(rmse_directly_comp_fn_all_pts)],         
         end; 

           reachedn=tr{j}.perf(max(size(tr{j}.perf)));
           rmserr=sqrt(reachedn./nn{i}.net{j}.trainParam.goal);                                      % form rmse for output
           rmsetest=sqrt(vreachedn./nn{i}.net{j}.trainParam.goal);                                  % same for the test set

           if cycle>1,
               TermImportance(j)=(rmsetestold-rmsetest)/rmsetestold;                                % term importance by relative reduction in rmse
           end;
           rmseold=rmserr;
           rmsetestold=rmsetest;

       end; % for j=1:Nterms, % sequential terms fit 
       rmse_directly_comp_fn 
       
               % check the size of terms               
               for j=whichj{i},                              
                   TermImportanceRmse(j)=sqrt(mean(outputn{j}.^2));          
               end;      
               %TermImportanceRmse=reshape(TermImportanceRmse,max(size(TermImportanceRmse)),1)
       
       %if sum(max(0,TermImportance))<1e-5*Nterms && cycle>5, break; end;                           % stop cycles if no fit improvement, run at least 5 cycles
       
       %Terms_rating=TermImportance                                                                 % output term importance                             
       rmserr
       rmsetest             
       
       % update # of nodes based on TermImportance
       if ifupdatenodes && cycle>2,     % update number of nodes of a term based on its importance
           updates=TermImportance/max(TermImportance)*3;          % 3 is max nodes increment   
           for j=1:Nterms,                          
               nn{i}.net{j}.layers{3}.size=nn{i}.net{j}.layers{3}.size+max(0,round(updates(j)));  
           end;
       end; % if ifupdatenodes 
       
       end; %  for cycle=1:xxx     
          
         EndedFit=fix(clock)    
         TimeTaken=EndedFit-BeganFit       
         
               % to display in cm-1
               rmserr
               rmsetest   
               for j=1:Nterms,           
                  finalnodes(j)=nn{i}.net{j}.layers{3}.size;           
               end;
               final_nodes=finalnodes                                                              % output final numbers of nodes of terms    
               total_nodes=sum(finalnodes)
         
    end; % if ((reachedn>tolerancen)|(vreachedn>=tightval*reachedn))     
    
    previoussim=zeros(1,max(size(nn{i}.target)));
    previoustestsim=zeros(1,max(size(nn{i}.testtarget)));
    for j=whichj{i},        
        previoussim=previoussim+sim(nn{i}.net{j},nn{i}.inputs);                              % sum up all component functions of the i'th mode-terms
        previoustestsim=previoustestsim+sim(nn{i}.net{j},nn{i}.testinputs);                  % same for the test points
    end;

         % test rmse directly
         bla=(nn{i}.target-previoussim)*(mint-maxt)/2;         
         rmse_directly=sqrt(mean(bla.^2))          
         testbla=(nn{i}.testtarget-previoustestsim)*(mint-maxt)/2;     
         test_rmse_directly=sqrt(mean(testbla.^2))
         variance_of_targetn=sqrt(mean((targetn*(maxt-mint)/2).^2))

    % prepare targets for the next mode-term by subtracting the current mode-term    
    previoussim=zeros(1,max(size(inputn)));
    previoustestsim=zeros(1,max(size(testinputn)));
    for j=whichj{i},        
        previoussim=previoussim+sim(nn{i}.net{j},inputn);                              % sum up all component functions of the i'th mode-terms
        previoustestsim=previoustestsim+sim(nn{i}.net{j},testinputn);                  % same for the test points
    end;      
    targetn=targetn-previoussim;          
    variance_after_this_mode_term=sqrt(mean((targetn*(mint-maxt)/2).^2))                       
    testtargetn=testtargetn-previoustestsim;     % same for the test points     

    % export NN parameters for this mode-term
    Export(label,nn{i}.net,minp,maxp,mint,maxt,neuron,i);  

    % save errors
    dlmwrite([label '_' num2str(i) '_errors.dat'],[postmnmx(inputn,minp,maxp); targetn*(maxt-mint)/2]','delimiter','\t', 'precision', '%.12f'); 
    dlmwrite([label '_' num2str(i) '_testerrors.dat'],[postmnmx(testinputn,minp,maxp); testtargetn*(maxt-mint)/2]','delimiter','\t', 'precision', '%.12f');
    dlmwrite([label '_' num2str(i) '_testresult.dat'],[postmnmx(testinputn,minp,maxp); postmnmx(previoustestsim,mint,maxt)]','delimiter','\t', 'precision', '%.12f');
    
else % if Nnodesini(i)=0, skip this stage
  % do nothing - targetn and testtargetn keep their previous values
  message=['skipping stage Nmodes=' int2str(i)]
  nn{i}.message='skipped';
end; % if (Nnodesini(i)>0)  

try TermImportanceRmse=zeros(max(size(TermImportanceRmse)),1); end;
end; % for i=1:Nmodes    

ToReturn=[rmse_directly test_rmse_directly];
value=ToReturn;                                  % function NNMMEseqInd returns rmse on training and test points
goal=nn{i}.net{1}.trainParam.goal;
traindata=input';
% save the NNs and data
%save([label '_nnstruc.mat'], 'nn', 'Nmodes', 'minp','maxp','mint','maxt','ndim','reachedn','vreachedn','goal','traindata');

function value=step(x);
value=(1+sign(x))/2;

function value=Export(label,NNarray,minp,maxp,mint,maxt,neuron,modeterm);
global nn
    neuroncode=0;
    if strcmp(neuron,'tansig'), neuroncode=1; end;
    if strcmp(neuron,'expneuron'), neuroncode=2; end;
    if strcmp(neuron,'expneuron2'), neuroncode=2; end;
    D=max(size(maxp));
    Dterm=size(NNarray{1}.LW{2,1},1);
    Nterms=max(size(NNarray));
    Nneurons=max(size(NNarray{1}.LW{4,3}));
    dlmwrite([label '_' num2str(modeterm) '_NNs.dat'],[D Dterm Nterms Nneurons neuroncode],'-append','delimiter', '\t');
    dlmwrite([label '_' num2str(modeterm) '_NNs.dat'], minp','-append','delimiter', '\t', 'precision', '%.12f');
    dlmwrite([label '_' num2str(modeterm) '_NNs.dat'], maxp','-append','delimiter', '\t', 'precision', '%.12f');
    dlmwrite([label '_' num2str(modeterm) '_NNs.dat'], [mint maxt],'-append','delimiter', '\t', 'precision', '%.12f');
    for i=1:Nterms,              
        dlmwrite([label '_' num2str(modeterm) '_NNs.dat'], NNarray{i}.LW{2,1},'-append','delimiter', '\t', 'precision', '%.12f');        
        dlmwrite([label '_' num2str(modeterm) '_NNs.dat'], NNarray{i}.LW{3,2},'-append','delimiter', '\t', 'precision', '%.12f');        
        dlmwrite([label '_' num2str(modeterm) '_NNs.dat'], NNarray{i}.LW{4,3}','-append','delimiter', '\t', 'precision', '%.12f');        
        dlmwrite([label '_' num2str(modeterm) '_NNs.dat'], NNarray{i}.b{2},'-append','delimiter', '\t', 'precision', '%.12f');         
        dlmwrite([label '_' num2str(modeterm) '_NNs.dat'], NNarray{i}.b{3},'-append','delimiter', '\t', 'precision', '%.12f');        
        dlmwrite([label '_' num2str(modeterm) '_NNs.dat'], NNarray{i}.b{4},'-append','delimiter', '\t', 'precision', '%.12f');        
    end; % for i=1:Nterms    

  % saving Red-RS-HDMR-NN as several simple, one-hidden layer NN's (see p. 28, 30 of Vol. 2 of Tokyo notes)
  if  0, % only makes sense if the coord transform is linear
      dlmwrite([label '_' num2str(modeterm) '_NNs_expnn.dat'],[D Dterm Nterms Nneurons neuroncode],'delimiter', '\t');
      dlmwrite([label '_' num2str(modeterm) '_NNs_expnn.dat'], minp','-append','delimiter', '\t', 'precision', '%.12f');
      dlmwrite([label '_' num2str(modeterm) '_NNs_expnn.dat'], maxp','-append','delimiter', '\t', 'precision', '%.12f');
      dlmwrite([label '_' num2str(modeterm) '_NNs_expnn.dat'], [mint maxt],'-append','delimiter', '\t', 'precision', '%.12f');
      IW=zeros(Nneurons,D);
      b1new=zeros(Nneurons,1);
      for t=1:Nterms,              
          % simple expnn has 2 layers, matrices IW, b1new, LW21new=LW43, b2new=b4
          for i=1:Nneurons,
              b1new(i)=NNarray{t}.b{3}(i);
              for k=1:D,
                  IW(i,k)=0;
                  for j=1:Dterm,
                      IW(i,k)=IW(i,k)+NNarray{t}.LW{3,2}(i,j)*NNarray{t}.LW{2,1}(j,k);
                  end;
              end;
              for j=1:Dterm,
                  b1new(i)=b1new(i)+NNarray{t}.LW{3,2}(i,j)*NNarray{t}.b{2}(j);
              end;
          end; % for i=1:Nneurons,
          dlmwrite([label '_' num2str(modeterm) '_NNs_expnn.dat'], IW,'-append','delimiter', '\t', 'precision', '%.12f');              
          dlmwrite([label '_' num2str(modeterm) '_NNs_expnn.dat'], b1new,'-append','delimiter', '\t', 'precision', '%.12f'); 
          dlmwrite([label '_' num2str(modeterm) '_NNs_expnn.dat'], NNarray{t}.LW{4,3}','-append','delimiter', '\t', 'precision', '%.12f');              
          dlmwrite([label '_' num2str(modeterm) '_NNs_expnn.dat'], NNarray{t}.b{4},'-append','delimiter', '\t', 'precision', '%.12f');        
      end; % for i=1:Nterms        
  end;
    
value='NN parameters exported'

    
 

