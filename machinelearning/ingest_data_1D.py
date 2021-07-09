#!/usr/env python2
# ---------------------------------------------------------------------
# Author: minh.nguyen@ikm.uni-hannover.de
# Create date: 05/12/2018
# Galerkin FFT method version: Building database for 1D problem
# ---------------------------------------------------------------------
import numpy as np
from microscale.fftgarlerkin import micro1D as micro1DNL
import matplotlib.pyplot as plt
import seaborn as sns
from util import setup_plot

# ----------------------------------------------------------------------------------------------------------------------
# NON-LINEAR 1D
# ----------------------------------------------------------------------------------------------------------------------
eps_macro_min, eps_macro_max = (0.0, 2.0)
number_data = 10 ** 4
# uniform probability distribution
data_uniform_eps = np.random.uniform(eps_macro_min, eps_macro_max, number_data)
# plot distribution
ax = sns.distplot(data_uniform_eps,
				  bins=100,
				  kde=False,
				  color='skyblue',
				  hist_kws={"linewidth": 15, 'alpha': 1})
ax.set(xlabel='$\overline{\epsilon}$', ylabel='$\overline{\epsilon}$ data distribution')
try:
	filename = './dataFiles/training_data_1D_mechanics_nonlinear.dat'
	f = open(filename, 'w+')
except IOError as e:
	print("Can't open file :" + e.filename)
for idx, eps_mac in enumerate(data_uniform_eps):
	print(idx)
	energy_macro, stress_macro, effective_moduli = micro1DNL.solve_micro_1d_nonlinear_fft(eps_mac)
	f.write("%0.12f\t%0.12f\n" % (eps_mac, energy_macro))
f.close()
plt.show()