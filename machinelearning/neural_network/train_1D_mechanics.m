% fit the PES of water with 3 two-dimensional NNs with 15 neurons each
% use 1500 points to fit and 7000 points to test
d=1
npoints=[10000 2000]
fns=2
N=5
neuron='tansig'
cyclemax=60
epochsinseq=30
ifRegularisation=0
tolerance = 1e-10
a=RS_HDMR_NN('training_data_1D_mechanics.dat', 'training_data_1D_mechanics.dat', 'Mechanics1D', [zeros(1,d-1) tolerance], [zeros(1,d-1) N], 200000*[zeros(1,d-1) 1], npoints, [zeros(1,d-1) fns], neuron, cyclemax, epochsinseq, ifRegularisation);