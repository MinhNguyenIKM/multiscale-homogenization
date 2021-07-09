#!/usr/bin/env  python2
# ---------------------------------------------------------------------
# Author: minh.nguyen@ikm.uni-hannover.de
# Create date: 12/09/2018
# Purpose: Create data for the training process
# ---------------------------------------------------------------------
import numpy as np
from scipy.stats import norm
import matplotlib.pyplot as plt
from microscale.fftgarlerkin import micro2D_largedeformation_elasticity as mic2D
import seaborn as sns


# ---------------------------------------------------------------------
# create numerous data for laminate problem
# number data: 10000
# problem: 2D large deformation - elasticity
# Create date: 12/09/2018
# ---------------------------------------------------------------------
def create_2Ddata_largedeformation_elasticity_laminate(fileinput):
	F11_min, F11_max = (0.7, 1.3)
	# F12_min, F12_max = (-0.3, 0.3)
	# F21_min, F21_max = (-0.3, 0.3)
	F12_min, F12_max = (0, 0)
	F21_min, F21_max = (0, 0)
	F22_min, F22_max = (0.7, 1.3)
	number_data = 5 * (10 ** 4)
	# uniform probability distribution
	data_uniform_F11 = np.random.uniform(F11_min, F11_max, number_data)
	data_uniform_F12 = np.random.uniform(F12_min, F12_max, number_data)
	data_uniform_F21 = np.random.uniform(F21_min, F21_max, number_data)
	data_uniform_F22 = np.random.uniform(F22_min, F22_max, number_data)
	# plot distribution
	ax = sns.distplot(data_uniform_F11,
					  bins=100,
					  kde=False,
					  color='skyblue',
					  hist_kws={"linewidth": 15, 'alpha': 1})
	ax.set(xlabel='Macro deformation gradient F11', ylabel='F11 data distribution')
	try:
		filename = fileinput
		f = open(filename, 'w+')
	except IOError as e:
		print("Can't open file :" + e.filename)
	# run each test case
	f.write('############################ MICRO SIMULATION INFORMATION ##################################\n')
	f.write('No\t\tF11\t\tF12\t\tF21\t\tF22\t\tEnergy\n')
	for i in range(number_data):
		print('data %d' % i)
		Fmacro = np.zeros([2, 2])
		Fmacro[0, 0] = data_uniform_F11[i]
		Fmacro[0, 1] = data_uniform_F12[i]
		Fmacro[1, 0] = data_uniform_F21[i]
		Fmacro[1, 1] = data_uniform_F22[i]
		detFmacro = np.linalg.det(Fmacro)
		if detFmacro < 0:
			print("With this F the cell is penetrable !!!")
			f.write("%d;\t%0.12f;\t%0.12f;\t%0.12f;\t%0.12f;\t%s\n" % (
			i, Fmacro[0, 0], Fmacro[0, 1], Fmacro[1, 0], Fmacro[1, 1], 'Penetrable'))
			continue
		energy_macro = mic2D.solve_nonlinear_GalerkinFFT(Fmacro, kind='neo-hookean', mode='energy')
		if energy_macro == -999999:
			print("With this F the cell is penetrable - with detFmacro < 0 !!!")
			f.write("%d;\t%0.12f;\t%0.12f;\t%0.12f;\t%0.12f;\t%s\n" % (
				i, Fmacro[0, 0], Fmacro[0, 1], Fmacro[1, 0], Fmacro[1, 1], 'Penetrable-detFmacro'))
		elif energy_macro == -888888:
			print("With this F the cell is penetrable - with detFmicro < 0 !!!")
			f.write("%d;\t%0.12f;\t%0.12f;\t%0.12f;\t%0.12f;\t%s\n" % (
				i, Fmacro[0, 0], Fmacro[0, 1], Fmacro[1, 0], Fmacro[1, 1], 'Penetrable-detFmicro'))
		elif energy_macro == -777777:
			print("The programme is not convergent !!!")
			f.write("%d;\t%0.12f;\t%0.12f;\t%0.12f;\t%0.12f;\t%s\n" % (
				i, Fmacro[0, 0], Fmacro[0, 1], Fmacro[1, 0], Fmacro[1, 1], 'Not-Convergent'))
		else:
			f.write("%d;\t%0.12f;\t%0.12f;\t%0.12f;\t%0.12f;\t%0.12f\n" % (
				i, Fmacro[0, 0], Fmacro[0, 1], Fmacro[1, 0], Fmacro[1, 1], energy_macro))
	f.write('################################ END OF FILE ################################################')
	f.close()
	plt.show()


# ---------------------------------------------------------------------
# create numerous data for a circular-inclusion
# number data: 10000
# problem: 2D large deformation - elasticity in with energy depends on C (Right Cauchy-Green tensor)
# Create date: 12/09/2018
# ---------------------------------------------------------------------
def create_2Ddata_largedeformation_K4_circular_inclusion(fileinput):
	F11_min, F11_max = (0.8, 1.2)
	F12_min, F12_max = (-0.2, 0.2)
	F21_min, F21_max = (-0.2, 0.2)
	F22_min, F22_max = (0.8, 1.2)
	number_data = 2 * (10 ** 3)
	# uniform probability distribution
	data_uniform_F11 = np.random.uniform(F11_min, F11_max, number_data)
	data_uniform_F12 = np.random.uniform(F12_min, F12_max, number_data)
	data_uniform_F21 = np.random.uniform(F21_min, F21_max, number_data)
	data_uniform_F22 = np.random.uniform(F22_min, F22_max, number_data)
	# plot distribution
	ax = sns.distplot(data_uniform_F11,
					  bins=100,
					  kde=False,
					  color='skyblue',
					  hist_kws={"linewidth": 15, 'alpha': 1})
	ax.set(xlabel='Macro deformation gradient F11', ylabel='F11 data distribution')
	try:
		filename = fileinput
		f = open(filename, 'w+')
	except IOError as e:
		print("Can't open file :" + e.filename)
	# run each test case
	f.write('############################ MICRO SIMULATION INFORMATION ##################################\n')
	f.write('No\t\tF11\t\tF12\t\tF21\t\tF22\t\tEnergy\n')
	for i in range(number_data):
		print('data %d' % i)
		Fmacro = np.zeros([2, 2])
		Fmacro[0, 0] = data_uniform_F11[i]
		Fmacro[0, 1] = data_uniform_F12[i]
		Fmacro[1, 0] = data_uniform_F21[i]
		Fmacro[1, 1] = data_uniform_F22[i]
		detFmacro = np.linalg.det(Fmacro)
		if detFmacro < 0:
			print("With this F the cell is penetrable !!!")
			f.write("%d;\t%0.12f;\t%0.12f;\t%0.12f;\t%0.12f;\t%s\n" % (
				i, Fmacro[0, 0], Fmacro[0, 1], Fmacro[1, 0], Fmacro[1, 1], 'Penetrable'))
			continue
		# energy_macro = mic2D.solve_nonlinear_GalerkinFFT(Fmacro, kind='neo-hookean2', mode='energy', domain='inclusion')
		energy_macro = mic2D.solve_nonlinear_GalerkinFFT(Fmacro, kind='neo-hookean', mode='energy', domain='laminate')
		if energy_macro == -999999:
			print("With this F the cell is penetrable - with detFmacro < 0 !!!")
			f.write("%d;\t%0.12f;\t%0.12f;\t%0.12f;\t%0.12f;\t%s\n" % (
				i, Fmacro[0, 0], Fmacro[0, 1], Fmacro[1, 0], Fmacro[1, 1], 'Penetrable-detFmacro'))
		elif energy_macro == -888888:
			print("With this F the cell is penetrable - with detFmicro < 0 !!!")
			f.write("%d;\t%0.12f;\t%0.12f;\t%0.12f;\t%0.12f;\t%s\n" % (
				i, Fmacro[0, 0], Fmacro[0, 1], Fmacro[1, 0], Fmacro[1, 1], 'Penetrable-detFmicro'))
		elif energy_macro == -777777:
			print("The programme is not convergent !!!")
			f.write("%d;\t%0.12f;\t%0.12f;\t%0.12f;\t%0.12f;\t%s\n" % (
				i, Fmacro[0, 0], Fmacro[0, 1], Fmacro[1, 0], Fmacro[1, 1], 'Not-Convergent'))
		else:
			f.write("%d;\t%0.12f;\t%0.12f;\t%0.12f;\t%0.12f;\t%0.12f\n" % (
				i, Fmacro[0, 0], Fmacro[0, 1], Fmacro[1, 0], Fmacro[1, 1], energy_macro))
	f.write('################################ END OF FILE ################################################')
	f.close()
	plt.show()


if __name__ == '__main__':
	create_2Ddata_largedeformation_elasticity_laminate('./dataFiles/training_data_2D_neohookean_hyperelasticity_02102018.dat')
	# create_2Ddata_largedeformation_K4_circular_inclusion('./dataFiles/training_data_2D_neohookean_K4_circular_inclusion.dat')
