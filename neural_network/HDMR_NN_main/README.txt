The RS_HDMR_NN distribution contains the following files.

dexpneuron.m                        - derivative of exponential neuron 
                                      activation function                                               
expneuron.m                         - exponential neuron activation 							function                        
expneuron2.m                        - exponential neuron activation 							function                        
H2O_20000cm_10000pts_unsym_qdgb.dat - test run input
H2Otest_2_errors.dat                - sample test run output        
H2Otest_2_NNs.dat                   -   "   "    "      "
H2Otest_2_testerrors.dat            -   "   "    "      "   
RS_HDMR_NN.m                        - main program
test_run_water.m                    - a small test run
xNNimport.f                         - fortran routines that load the NN
                                      parameters and provide the value 
                                      of the function at any point.

To run the test_run_water example,

Change the Matlab current directory to the directory in which the test run file  is stored.
Open the test_run_water.m file

In the Matlab Editor window click Debug -> "Run test_run_water.m
Three files should be output to the Matlab current directory. 
These can be checked against the files provided in the distribution.

Note: The test program will not run under Matlab 2008a, owing to a bug in 
that Matlab release. It will run on earlier versions and the latest version, 
Matlab 2009a.     
