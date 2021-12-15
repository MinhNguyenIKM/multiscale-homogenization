% fit the PES of water with 3 two-dimensional NNs with 15 neurons each
% use 1500 points to fit and 7000 points to test
D=2
npoints=[1500 7000]
fns=3
N=15
neuron='tansig'
cyclemax=50
epochsinseq=10
ifRegularisation=0
a=RS_HDMR_NN('H2O_20000cm_10000pts_unsym_qdgb.dat', 'H2O_20000cm_10000pts_unsym_qdgb.dat', 'H2Otest', [zeros(1,D-1) 1], [zeros(1,D-1) N], 20000*[zeros(1,D-1) 1], npoints, [zeros(1,D-1) fns], neuron, cyclemax, epochsinseq, ifRegularisation);