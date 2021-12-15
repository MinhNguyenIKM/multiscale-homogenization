import numpy as np
from numpy import dot
import micro1D as mic
import micro1Dnonlinear as micnl
# should be modified like this:
# 11/09/2018
# from microscale.fftstandard import micro1D_nonlinearity as micnl

# eps_macro = np.arange(-1, 1 + 0.0002, 0.0002)
# try:
#     filename = 'training_data_1D_mechanics.dat'
#     f = open(filename, 'w+')
# except IOError as e:
#     print("Can't open file:" + e.filename)
# for idx, eps_mac in enumerate(eps_macro):
#     print(idx)
#     x, k, diameter, eps_mic, sig_mic, strain_macro, stress_macro, C, energy_macro = mic.solve_micro_1d_fft_v3(eps_mac)
#     f.write("%0.12f\t%0.12f\n" % (eps_mac, energy_macro))
# f.close()

# ----------------------------------------------------------------------------------------------------------------------
# NON-LINEAR 1D
# ----------------------------------------------------------------------------------------------------------------------
eps_macro = np.arange(0, 2 + 0.0001, 0.0001)
try:
    filename = 'training_data_1D_mechanics_nonlinear.dat'
    f = open(filename, 'w+')
except IOError as e:
    print("Can't open file :" + e.filename)
for idx, eps_mac in enumerate(eps_macro):
    print(idx)
    x, k, diameter, eps_mic, sig_mic, strain_macro, stress_macro, C, energy_macro = micnl.solve_micro_1d_nonlinear_fft(eps_mac)
    f.write("%0.12f\t%0.12f\n" % (eps_mac, energy_macro))
f.close()