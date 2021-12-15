d=1
npoints=[100 450]
fns=1
N=5
neuron='tansig'
cyclemax=30
epochsinseq=100
ifRegularisation=0
tolerance = 1e-10
ifRegularisation=0
ifTestPtsSameFile=1
CoordTransformNeuron='purelin'
PartialNNoutputNeuron='purelin'
ifTest = 0

a=RS_HDMR_NN('training_data_1D_mechanics_nonlinear_05122018.dat', 'training_data_1D_mechanics_nonlinear_05122018.dat', 'Mechanics1D_Nonlinear_1d_1com_5N_100M', ...
    [tolerance], [N], 200000*[1], npoints, [fns], neuron, cyclemax, epochsinseq, ifRegularisation, ifTestPtsSameFile, CoordTransformNeuron, PartialNNoutputNeuron, ifTest);
%a=RS_HDMR_NN('training_data_1D_mechanics_nonlinear_05122018.dat', 'training_data_1D_mechanics_nonlinear_05122018.dat', 'Mechanics1D_Nonlinear', [zeros(1,d-1) tolerance], [zeros(1,d-1) N], 200000*[zeros(1,d-1) 1], npoints, [zeros(1,d-1) fns], neuron, cyclemax, epochsinseq, ifRegularisation);