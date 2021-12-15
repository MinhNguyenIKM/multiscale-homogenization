% Neural Network Toolbox
% Version 6.0.2 (R2009a) 15-Jan-2009
%
% Graphical user interface functions.
%   nctool      - Neural network classification tool.
%   nftool      - Neural network fitting tool.
%   nprtool     - Neural Network pattern recognition tool.
%   nntool      - Neural Network Toolbox graphical user interface.
%   nntraintool - Neural network training tool.
%   view        - View a neural network.
%
% Analysis functions.
%   confusion - Classification confusion matrix.
%   errsurf   - Error surface of single input neuron.
%   maxlinlr  - Maximum learning rate for a linear layer.
%   roc       - Receiver operating characteristic.
%
% Distance functions.
%   boxdist  - Box distance function.
%   dist     - Euclidean distance weight function.
%   mandist  - Manhattan distance weight function.
%   linkdist - Link distance function.
%
% Formatting data.
%   combvec  - Create all combinations of vectors.
%   con2seq  - Convert concurrent vectors to sequential vectors.
%   concur   - Create concurrent bias vectors.
%   dividevec  - Create all combinations of vectors.
%   ind2vec  - Convert indices to vectors.
%   minmax   - Ranges of matrix rows.
%   nncopy   - Copy matrix or cell array.
%   normc    - Normalize columns of a matrix.
%   normr    - Normalize rows of a matrix.
%   pnormc   - Pseudo-normalize columns of a matrix.
%   quant    - Discretize values as multiples of a quantity.
%   seq2con  - Convert sequential vectors to concurrent vectors.
%   vec2ind  - Convert vectors to indices.
%
% Initialize network functions.
%   initlay  - Layer-by-layer network initialization function.
%
% Initialize layer functions.
%   initnw   - Nguyen-Widrow layer initialization function.
%   initwb   - By-weight-and-bias layer initialization function.
%
% Initialize weight and bias functions.
%   initcon  - Conscience bias initialization function.
%   initzero - Zero weight/bias initialization function.
%   initsompc - Initialize SOM weights with principle components.
%   midpoint - Midpoint weight initialization function.
%   randnc   - Normalized column weight initialization function.
%   randnr   - Normalized row weight initialization function.
%   rands    - Symmetric random weight/bias initialization function.
%
% Learning functions.
%   learncon  - Conscience bias learning function.
%   learngd   - Gradient descent weight/bias learning function.
%   learngdm  - Gradient descent w/momentum weight/bias learning function.
%   learnh    - Hebb weight learning function.
%   learnhd   - Hebb with decay weight learning function.
%   learnis   - Instar weight learning function.
%   learnk    - Kohonen weight learning function.
%   learnlv1  - LVQ1 weight learning function.
%   learnlv2  - LVQ2 weight learning function.
%   learnos   - Outstar weight learning function.
%   learnsomb - Batch self-organizing map weight learning function.
%   learnp    - Perceptron weight/bias learning function.
%   learnpn   - Normalized perceptron weight/bias learning function.
%   learnsom  - Self-organizing map weight learning function.
%   learnwh   - Widrow-Hoff weight/bias learning rule.
%
% Line search functions.
%   srchbac  - Backtracking search.
%   srchbre  - Brent's combination golden section/quadratic interpolation.
%   srchcha  - Charalambous' cubic interpolation.
%   srchgol  - Golden section search.
%   srchhyb  - Hybrid bisection/cubic search.
%
% Net input functions.
%   netprod  - Product net input function.
%   netsum   - Sum net input function.
%
% Network creation functions.
%   network  - Create a custom neural network.
%   newc     - Create a competitive layer.
%   newcf    - Create a cascade-forward backpropagation network.
%   newdtdnn - Create a distributed time delay neural network.
%   newelm   - Create an Elman backpropagation network.
%   newfit   - Createa a fitting network.
%   newff    - Create a feed-forward backpropagation network.
%   newfftd  - Create a feed-forward input-delay backprop network.
%   newgrnn  - Design a generalized regression neural network.
%   newhop   - Create a Hopfield recurrent network.
%   newlin   - Create a linear layer.
%   newlind  - Design a linear layer.
%   newlvq   - Create a learning vector quantization network.
%   newnarx   - Create a feed-forward backpropagation network with feedback
%     from output to input.
%   newnarxsp   - Create an NARX network in series-parallel arrangement.
%   newp     - Create a perceptron.
%   newpnn   - Design a probabilistic neural network.
%   newpr    - Create a pattern recognition network.
%   newrb    - Design a radial basis network.
%   newrbe   - Design an exact radial basis network.
%   newsom   - Create a self-organizing map.
%
% Network transform functions.
%   sp2narx   - Convert a series-parallel NARX network to parallel (feedback) form.
%
% Network update functions.
%   nnt2c    - Update NNT 2.0 competitive layer.
%   nnt2elm  - Update NNT 2.0 Elman backpropagation network.
%   nnt2ff   - Update NNT 2.0 feed-forward network.
%   nnt2hop  - Update NNT 2.0 Hopfield recurrent network.
%   nnt2lin  - Update NNT 2.0 linear layer.
%   nnt2lvq  - Update NNT 2.0 learning vector quantization network.
%   nnt2p    - Update NNT 2.0 perceptron.
%   nnt2rb   - Update NNT 2.0 radial basis network.
%   nnt2som  - Update NNT 2.0 self-organizing map.
%
% Performance functions.
%   mae      - Mean absolute error performance function.
%   mse      - Mean squared error performance function.
%   msereg   - Mean squared error with regularization performance function.
%   mseregec   - Mean squared error with regularization and economization performance function.
%   sse      - Sum squared error performance function.
%
% Plotting functions.
%   hintonw        - Hinton graph of weight matrix.
%   hintonwb       - Hinton graph of weight matrix and bias vector.
%   plotbr         - Plot network performance for Bayesian regularization training.
%   plotconfusion  - Plot classification confusion matrix.
%   plotep         - Plot a weight-bias position on an error surface.
%   plotes         - Plot an error surface of a single input neuron.
%   plotfit        - Plot function fit.
%   plotpc         - Plot classification line on perceptron vector plot.
%   plotperform    - Plot network performance.
%   plotpv         - Plot perceptron input/target vectors.
%   plotregression - Plot linear regression.
%   plotroc        - plot receiver operating characteristic.
%   plotsom        - Plot self-organizing map.
%   plotsomhits    - Plot self-organizing map sample hits.
%   plotsomnc      - Plot self-organizing map neighbor connections.
%   plotsomnd      - Plot self-organizing map neighbor distances.
%   plotsompos     - Plot self-organizing map weight positions.
%   plotsomtop     - Plot self-organizing map topology.
%   plottrainstate - Plot training state values.
%   plotv          - Plot vectors as lines from the origin.
%   plotvec        - Plot vectors with different colors.
%   postreg        - Post-training regression analysis.
%
% Processing data.
%   fixunknowns   - Process matrix rows with unknown values.
%   mapminmax  - Map matrix row minimum and maximum values to [-1 1].
%   mapstd   - Map matrix row means and deviations to standard values.
%   processpca  - Processes matrix rows with principal component analysis.
%   removeconstantrows - Remove matrix rows with constant values.
%   removerows  - Remove matrix rows with specified indices.
%
% Simulink support.
%   gensim   - Generate a Simulink block to simulate a neural network.
%
% Topology functions.
%   gridtop  - Grid layer topology function.
%   hextop   - Hexagonal layer topology function.
%   randtop  - Random layer topology function.
%
% Training functions.
%   trainb    - Batch training with weight & bias learning rules.
%   trainbuwb - Batch unsupervised weights/bias learning.
%   trainbfg  - BFGS quasi-Newton backpropagation.
%   trainbr   - Bayesian regularization.
%   trainc    - Cyclical order incremental training w/learning functions.
%   traincgb  - Powell-Beale conjugate gradient backpropagation.
%   traincgf  - Fletcher-Powell conjugate gradient backpropagation.
%   traincgp  - Polak-Ribiere conjugate gradient backpropagation.
%   traingd   - Gradient descent backpropagation.
%   traingdm  - Gradient descent with momentum backpropagation.
%   traingda  - Gradient descent with adaptive lr backpropagation.
%   traingdx  - Gradient descent w/momentum & adaptive lr backpropagation.
%   trainlm   - Levenberg-Marquardt backpropagation.
%   trainoss  - One step secant backpropagation.
%   trainr    - Random order incremental training w/learning functions.
%   trainrp   - Resilient backpropagation (Rprop).
%   trains    - Sequential order incremental training w/learning functions.
%   trainscg  - Scaled conjugate gradient backpropagation.
%
% Transfer functions.
%   compet   - Competitive transfer function.
%   hardlim  - Hard limit transfer function.
%   hardlims - Symmetric hard limit transfer function.
%   logsig   - Log sigmoid transfer function.
%   netinv   - Inverse transfer function.
%   poslin   - Positive linear transfer function.
%   purelin  - Linear transfer function.
%   radbas   - Radial basis transfer function.
%   satlin   - Saturating linear transfer function.
%   satlins  - Symmetric saturating linear transfer function.
%   softmax  - Soft max transfer function.
%   tansig   - Hyperbolic tangent sigmoid transfer function.
%   tribas   - Triangular basis transfer function.
%
% Using networks.
%   sim      - Simulate a neural network.
%   init     - Initialize a neural network.
%   adapt    - Allow a neural network to adapt.
%   train    - Train a neural network.
%   disp     - Display a neural network's properties.
%   display  - Display the name and properties of a neural network variable.
%
% Weight functions.
%   convwf     - Convolution weight function.
%   dist     - Euclidean distance weight function.
%   dotprod  - Dot product weight function.
%   mandist  - Manhattan distance weight function.
%   negdist  - Negative distance weight function.
%   normprod - Normalized dot product weight function.
%   scalprod - Scalar product weight function.
%
% Template custom functions.
%   template_distance     - Template distance function.
%   template_init_layer   - Template layer initialization function.
%   template_init_network - Template network initialization function.
%   template_init_wb      - Template weight/bias initialization function.
%   template_learn        - Template leaning function.
%   template_net_input    - Template net input function.
%   template_new_network  - Template new network function.
%   template_performance  - Template performance function.
%   template_process      - Template process function.
%   template_search       - Template search function.
%   template_topology     - Template topology function.
%   template_train        - Template train function.
%   template_transfer     - Template transfer function.
%   template_weight       - Template weight function.

% Copyright 1992-2009 The MathWorks, Inc.

