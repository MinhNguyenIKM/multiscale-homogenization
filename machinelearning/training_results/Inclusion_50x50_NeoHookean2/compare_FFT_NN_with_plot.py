#!/usr/bin/env python2
from util import FileProcessing as fp
from numpy import dot, exp, ones
import numpy as np
from matplotlib import pyplot as plt
from matplotlib import cm as color
from mpl_toolkits.mplot3d import Axes3D
import itertools
import re
from microscale.fftgarlerkin import micro2D_largedeformation_elasticity as mic2D


# font = {'weight': 'normal'}
# plt.rc('font', **font)
from util import setup_plot

Ddim = 4
def tramnnmx(p, minp, maxp):
	return 2 * (p - minp) / (maxp - minp) - 1


def postmnmx(tn, mint, maxt):
	t = (tn + 1) / 2.0
	# return t * (maxt - mint) + (mint * ones((len(t), 1)))
	return t * (maxt - mint) + (mint * 1)


def postmnmx2(tn, mint, maxt):
	return tn * (maxt - mint) / 2.0


def return_to_rescale_for_stress(stress_scaled, minX, maxX, minY, maxY):
	dxidx = 2.0 / (maxX - minX)
	dgdf = 2.0 / (maxY - minY)
	return stress_scaled * (1.0 / dgdf) * dxidx


def unnormalize_for_hessian(hessian, Xmin, Xmax, Ymin, Ymax):
	dxidx = 2.0 / (Xmax - Xmin)
	dgdf = 2.0 / (Ymax - Ymin)
	return hessian * (1.0 / dgdf) * np.dot(dxidx.reshape(Ddim, 1), dxidx.reshape(1, Ddim))

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
def derivative_activation(z):
	return 4 * exp(-2 * z) / ((1 + exp(-2 * z)) ** 2)


def tansig(z):
	return 2.0 / (1 + np.exp(-2*z)) - 1


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
def cal_material_parameter2D(F_macro, type):
	# eps_macro = eps_macro[0]
	if type == '1Dlinear':
		filename = 'Mechanics1D_1_NNs.dat'
	elif type == '1Dnonlinear':
		filename = 'Mechanics1D_Nonlinear_1_NNs.dat'
	elif type == 'Yvonnet_quadratic_function_2d':
		filename = 'yvonnetFunction3d_1com_3_NNs.dat'
	elif type == 'NeoHooke-Laminate':
		filename = 'Laminate_NeoHookean_4d_15com_20N_80epoch_50000M_4_NNs.dat'
	elif type == 'NeoHookean2-Inclusion':
		filename = 'Inclusion_NeoHookean2_4d_15com_20N_80epoch_30000M_4_NNs.dat'
	dimD, dimd, L, N, activation_func_type, min_input, max_input, min_max_output, \
	A, w, c, b, d, d0 = fp.get_NN_parameters(filename)
	F_macro = tramnnmx(F_macro.reshape(-1), min_input, max_input)
	sigma_macro = np.zeros(Ddim)
	P = np.zeros(Ddim)
	C_effective = np.zeros([Ddim, Ddim])
	energy = 0
	for i in range(0, L):
		y = dot(A[:, :, i], F_macro) + b[:, :, i].reshape(-1)
		for n in range(0, N):
			z = dot(w[n, :, i], y) + d[n, :, i]
			zm = dot(w[n, :, i], y)
			energy += c[n, :, i] * tansig(z)
			sigma_macro += c[n, :, i] * dot(w[n, :, i], A[:, :, i]) * derivative_activation(z)
			C_effective += c[n, :, i] * dot(dot(w[n, :, i], A[:, :, i]).reshape(Ddim, 1), dot(w[n, :, i], A[:, :, i]).reshape(1, Ddim)) \
						   * 4 * ((-2 * exp(-2*z) / (1 + exp(-2*z)) ** 2) + (4 * exp(-4*z) / (1 + exp(-2*z)) ** 3))
		energy += d0[:, :, i].reshape(-1)
	# return the real scale data
	energy_aver = postmnmx(energy, min_max_output[0], min_max_output[1])
	P = return_to_rescale_for_stress(sigma_macro, min_input, max_input, min_max_output[0], min_max_output[1])
	print(sigma_macro)
	C_effective_unscaled = unnormalize_for_hessian(C_effective, min_input, max_input, min_max_output[0], min_max_output[1])
	return energy_aver, P, C_effective_unscaled


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
if __name__ == '__main__':
	F_macro = np.array([
		[0.988311799935, 0.158990370976],
		[-0.162079873193, 0.985702349318]
	])
	type = 'NeoHookean2-Inclusion'
	# W, P, C = cal_material_parameter2D(F_macro, type)
	numberM = 50
	W = np.zeros([numberM, numberM, numberM, numberM])
	P = np.zeros([1, 4, numberM, numberM, numberM, numberM])
	C = np.zeros([4, 4, numberM, numberM, numberM, numberM])

	F11 = np.linspace(0.9, 1.1, numberM)
	F12 = np.linspace(-0.4, 0.4, numberM)
	F21 = np.linspace(-0.4, 0.4, numberM)
	F22 = np.linspace(0.9, 1.1, numberM)

	F12grid, F21grid = np.meshgrid(F21, F12)
	valF11 = 1.1
	valF22 = 1.1
	for i in range(1):
		for j in range(numberM):
			for k in range(numberM):
				for l in range(1):
					valF12 = F12grid[j, k]; valF21 = F21grid[j, k]
					F_macro = np.array([[valF11, valF12], [valF21, valF22]])
					W[i, j, k, l], P[:, :, i, j, k, l], C[:, :, i, j, k, l] = cal_material_parameter2D(F_macro, type)
	# ------------------------------------------------------------------------------------------------------
	runFFT = 0
	if runFFT:
		# -------------------------------------------------------------------------------
		# 						FFT - Calculation
		#	Usage: Please run this code in advance and collect the file. Then, turn off
		#	only this piece of code and run the rest file
		# -------------------------------------------------------------------------------
		try:
			# filename = 'training_data_1D_mechanics_nonlinear.dat'
			# filename = './FFT_Inclusion_NeoHookean2_50x50_mesh131x131.dat'
			filename = './FFT_Inclusion_NeoHookean2_50x50'
			fileFFT = open(filename, 'w+')
		except IOError as e:
			print("Can't open file :" + e.filename)
		W_FFT = np.zeros([numberM, numberM, numberM, numberM])
		P_FFT = np.zeros([2, 2, numberM, numberM, numberM, numberM])
		C_FFT = np.zeros([4, 4, numberM, numberM, numberM, numberM])
		for i in range(1):
			for j in range(numberM):
				for k in range(numberM):
					for l in range(1):
						valF12 = F12grid[j, k]; valF21 = F21grid[j, k]
						F_macro = np.array([[valF11, valF12], [valF21, valF22]])
						energy_macro = mic2D.solve_nonlinear_GalerkinFFT(F_macro, kind='neo-hookean2', mode='energy', domain='inclusion')
						if energy_macro != -999999 and energy_macro != -888888 and energy_macro != -777777:
							W_FFT[i, j, k, l], P_FFT[:, :, i, j, k, l], C_FFT[:, :, i, j, k,l] = mic2D.solve_nonlinear_GalerkinFFT(F_macro, kind='neo-hookean2', mode='everything', domain='inclusion')
							print(W_FFT[i, j, k, l])
							# f.write("%0.12f;\t%0.12f;\t%0.12f;\t%0.12f;\t%0.12f\n" % (F_macro[0, 0], F_macro[0, 1], F_macro[1, 0], F_macro[1, 1], W_FFT[i, j, k, l]))
							fileFFT.write("%0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f\n\r" \
							% (F_macro[0, 0], F_macro[0, 1], F_macro[1, 0], F_macro[1, 1], W_FFT[i, j, k, l], \
							   P_FFT[0, 0, i, j, k, l], P_FFT[0, 1, i, j, k, l], P_FFT[1, 0, i, j, k, l], P_FFT[1, 1, i, j, k, l], \
							   C_FFT[0, 0, i, j, k, l], C_FFT[0, 1, i, j, k, l], C_FFT[0, 2, i, j, k, l], C_FFT[0, 3, i, j, k, l], \
							   C_FFT[1, 0, i, j, k, l], C_FFT[1, 1, i, j, k, l], C_FFT[1, 2, i, j, k, l], C_FFT[1, 3, i, j, k, l], \
							   C_FFT[2, 0, i, j, k, l], C_FFT[2, 1, i, j, k, l], C_FFT[2, 2, i, j, k, l], C_FFT[2, 3, i, j, k, l], \
							   C_FFT[3, 0, i, j, k, l], C_FFT[3, 1, i, j, k, l], C_FFT[3, 2, i, j, k, l], C_FFT[3, 3, i, j, k, l]))
						else:
							fileFFT.write("%0.12f;\t%0.12f;\t%0.12f;\t%0.12f;\t%s\n" % (F_macro[0, 0], F_macro[0, 1], F_macro[1, 0], F_macro[1,1], 'Penetrable'))
							print(F_macro, '--> Penetrable')
		fileFFT.close()
	# --------------------------------------------------- END RUN FFT ---------------------------------------------------

	# ---------------------------------------------------------------------------------------------
	#			FFT SOLUTIONS
	# ---------------------------------------------------------------------------------------------
	file_FFT = './FFT_Inclusion_NeoHookean2_50x50.dat'
	try:
		with open(file_FFT) as f:
			content = np.array(f.readlines())
	except IOError as e:
		print("An error occurred trying to read the file: " + e.filename)
		exit()
	eof = len(content)
	rows = 50
	columns = 50
	F12grid_FFT = np.zeros([rows, columns])
	F21grid_FFT = np.zeros([rows, columns])
	Wgrid_FFT = np.zeros([rows, columns])
	P11grid_FFT = np.zeros([rows, columns])
	Pgrid_FFT = np.zeros([2, 2, rows, columns])
	C1111grid_FFT = np.zeros([rows, columns])
	Cgrid_FFT = np.zeros([4, 4, rows, columns])
	i = -1
	while i < eof - 1:
		i += 1
		line = content[i]
		# print(line)
		if re.search('#*[a-zA-Z]+', line):
			print(line)
			continue
		else:
			try:
				segments = fp.get_values_wsplit(line, ';')
			except ValueError as e:
				print(e)
				print(line)
				continue
			F12grid_FFT[i / rows, i % columns] = segments[1]
			F21grid_FFT[i / rows, i % columns] = segments[2]
			Wgrid_FFT[i / rows, i % columns] = segments[4]
			P11grid_FFT[i / rows, i % columns] = segments[5]
			Pgrid_FFT[0, 0, i / rows, i % columns] = segments[5]
			Pgrid_FFT[0, 1, i / rows, i % columns] = segments[6]
			Pgrid_FFT[1, 0, i / rows, i % columns] = segments[7]
			Pgrid_FFT[1, 1, i / rows, i % columns] = segments[8]
			C1111grid_FFT[i / rows, i % columns] = segments[9]
			Cgrid_FFT[0, 0, i / rows, i % columns] = segments[9]
			Cgrid_FFT[0, 1, i / rows, i % columns] = segments[10]
			Cgrid_FFT[0, 2, i / rows, i % columns] = segments[11]
			Cgrid_FFT[0, 3, i / rows, i % columns] = segments[12]
			Cgrid_FFT[1, 0, i / rows, i % columns] = segments[13]
			Cgrid_FFT[1, 1, i / rows, i % columns] = segments[14]
			Cgrid_FFT[1, 2, i / rows, i % columns] = segments[15]
			Cgrid_FFT[1, 3, i / rows, i % columns] = segments[16]
			Cgrid_FFT[2, 0, i / rows, i % columns] = segments[17]
			Cgrid_FFT[2, 1, i / rows, i % columns] = segments[18]
			Cgrid_FFT[2, 2, i / rows, i % columns] = segments[19]
			Cgrid_FFT[2, 3, i / rows, i % columns] = segments[20]
			Cgrid_FFT[3, 0, i / rows, i % columns] = segments[21]
			Cgrid_FFT[3, 1, i / rows, i % columns] = segments[22]
			Cgrid_FFT[3, 2, i / rows, i % columns] = segments[23]
			Cgrid_FFT[3, 3, i / rows, i % columns] = segments[24]
	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	# 				PLOTING 2
	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	# -------------------------------------------------------------------------------------------
	# #   PLOT MESH and VALUES
	# # -------------------------------------------------------------------------------------------
	# fig = plt.figure()
	X = F12grid
	Y = F21grid


	nrows = 1
	ncols = 1

	fig = plt.figure('SM1', figsize=(4.0, 3.5))
	ax = fig.add_subplot(nrows, ncols, 1, projection='3d')
	Z = W[0, :, :, 0]
	ax.plot_surface(X, Y, Z, cmap=color.coolwarm)
	cset = ax.contourf(X, Y, Z, zdir='z', offset=0, cmap=color.coolwarm)
	ax.set_xlabel('$\overline{F}_{12}$')
	ax.set_xlim(-0.4, 0.4)
	ax.set_ylabel('$\overline{F}_{21}$')
	ax.set_ylim(-0.4, 0.4)
	ax.set_zlabel('$\overline{\psi}(\overline{\mathbf{F}})$')
	ax.set_zlim(0, 15)
	ax.view_init(elev=20, azim=-40)
	# ax.set_title("NN solutions")

	fig = plt.figure('SM2', figsize=(4.0, 3.5))
	ax = fig.add_subplot(nrows, ncols, 1, projection='3d')
	Z = P[0, 0, 0, :, :, 0] # P_11 at all grid points
	ax.plot_surface(X, Y, Z, cmap=color.coolwarm)
	cset2 = ax.contourf(X, Y, Z, zdir='z', offset=10, cmap=color.coolwarm)
	ax.set_xlabel('$\overline{F}_{12}$')
	ax.set_xlim(-0.4, 0.4)
	ax.set_ylabel('$\overline{F}_{21}$')
	ax.set_ylim(-0.4, 0.4)
	ax.set_zlabel('$\overline{P}_{11}$')
	ax.set_zlim(10, 55)
	ax.view_init(elev=20, azim=-40)

	fig = plt.figure('SM3', figsize=(4.0, 3.5))
	ax = fig.add_subplot(nrows, ncols, 1, projection='3d')
	Z = C[0, 0, 0, :, :, 0]  # C_1111 at all grid points
	ax.plot_surface(X, Y, Z, cmap=color.coolwarm)
	cset3 = ax.contourf(X, Y, Z, zdir='z', offset=120, cmap=color.coolwarm)
	ax.set_xlabel('$\overline{F}_{12}$')
	ax.set_xlim(-0.4, 0.4)
	ax.set_ylabel('$\overline{F}_{21}$')
	ax.set_ylim(-0.4, 0.4)
	ax.set_zlabel('$\overline{\mathbb{C}}_{1111}$')
	ax.set_zlim(120, 280)
	ax.view_init(elev=20, azim=-40)

	fig = plt.figure('FFT1', figsize=(4.0, 3.5))
	ax = fig.add_subplot(nrows, ncols, 1, projection='3d')

	ax.plot_surface(F12grid_FFT, F21grid_FFT, Wgrid_FFT, cmap=color.coolwarm)
	cset = ax.contourf(F12grid_FFT, F21grid_FFT, Wgrid_FFT, zdir='z', offset=0, cmap=color.coolwarm)
	ax.set_xlabel('$\overline{F}_{12}$')
	ax.set_xlim(-0.4, 0.4)
	ax.set_ylabel('$\overline{F}_{21}$')
	ax.set_ylim(-0.4, 0.4)
	ax.set_zlabel('$\overline{\psi}(\overline{\mathbf{F}})$')
	ax.set_zlim(0, 15)
	ax.view_init(elev=20, azim=-40)
	# ax.set_title('FFT solutions')

	fig = plt.figure('FFT2', figsize=(4.0, 3.5))
	ax = fig.add_subplot(nrows, ncols, 1, projection='3d')

	ax.plot_surface(F12grid_FFT, F21grid_FFT, P11grid_FFT, cmap=color.coolwarm)
	cset2 = ax.contourf(F12grid_FFT, F21grid_FFT, P11grid_FFT, zdir='z', offset=10, cmap=color.coolwarm)
	ax.set_xlabel('$\overline{F}_{12}$')
	ax.set_xlim(-0.4, 0.4)
	ax.set_ylabel('$\overline{F}_{21}$')
	ax.set_ylim(-0.4, 0.4)
	ax.set_zlabel('$\overline{P}_{11}$')
	ax.set_zlim(10, 55)
	ax.view_init(elev=20, azim=-40)

	fig = plt.figure('FFT3', figsize=(4.0, 3.5))
	ax = fig.add_subplot(nrows, ncols, 1, projection='3d')
	ax.plot_surface(F12grid_FFT, F21grid_FFT, C1111grid_FFT, cmap=color.coolwarm)
	cset3 = ax.contourf(F12grid_FFT, F21grid_FFT, C1111grid_FFT, zdir='z', offset=120, cmap=color.coolwarm)
	ax.set_xlabel('$\overline{F}_{12}$')
	ax.set_xlim(-0.4, 0.4)
	ax.set_ylabel('$\overline{F}_{21}$')
	ax.set_ylim(-0.4, 0.4)
	ax.set_zlabel('$\overline{\mathbb{C}}_{1111}$')
	ax.set_zlim(120, 280)
	ax.view_init(elev=20, azim=-40)

	fig = plt.figure()
	ax = fig.add_subplot(1, 1, 1)
	# Luu y: Chi so P[0, 0, 0, 0, :, 0] luc nay tuong trung cho P11 (2 so 0 dau) trong do i,j,l fixed, chay k (tuong ung voi F21).
	p11nn = ax.scatter(F12grid[0, :], P[0, 0, 0, 0, :, 0], color='r', facecolors='none', label='SM solutions') #, label='$\overline{P}_{11}$ (NN)')  # Fix F11 = 1.1, F22 = 1.1, F21 = -0.4
	p12nn = ax.scatter(F12grid[0, :], P[0, 1, 0, 0, :, 0], color='g', facecolors='none') #, label='$\overline{P}_{12}$ (NN)')
	p21nn = ax.scatter(F12grid[0, :], P[0, 2, 0, 0, :, 0], color='b', facecolors='none') #, label='$\overline{P}_{21}$ (NN)')
	p22nn = ax.scatter(F12grid[0, :], P[0, 3, 0, 0, :, 0], color='k', facecolors='none') #, label='$\overline{P}_{22}$ (NN)')

	p11fft, = ax.plot(F12grid_FFT[0, :], Pgrid_FFT[0, 0, 0, :], 'rx', fillstyle='none', label='FFT solutions') #, label='$\overline{P}_{11}$ (FFT)')
	p12fft, = ax.plot(F12grid_FFT[0, :], Pgrid_FFT[0, 1, 0, :], 'gx', fillstyle='none') #, label='$\overline{P}_{12}$ (FFT)')
	p21fft, = ax.plot(F12grid_FFT[0, :], Pgrid_FFT[1, 0, 0, :], 'bx', fillstyle='none') #, label='$\overline{P}_{21}$ (FFT)')
	p22fft, = ax.plot(F12grid_FFT[0, :], Pgrid_FFT[1, 1, 0, :], 'kx', fillstyle='none') #, label='$\overline{P}_{22}$ (FFT)')

	# ax.legend(loc='upper right')
	# ----------- small box --------------------
	# Shrink current axis by 99%
	box = ax.get_position()
	ax.set_position([box.x0, box.y0, box.width, box.height * 0.99])

	# Put a legend to the right of the current axis
	ax.legend(fontsize='x-small', \
	          ncol=3, fancybox=True, shadow=True, \
	          loc='upper left', bbox_to_anchor=(0.0, 1.14))
	# -------------------------------------------------------
	ax.grid(True)
	ax.set_xlabel(r'$\overline{F}_{12}$', fontsize=18)
	ax.set_ylabel(r'$\overline{P}_{ij}$', fontsize=18)
	# ax.set_title('First Piola-Kirchhoff stress comparison between NN and FFT')

	fig = plt.figure()
	ax = fig.add_subplot(1, 1, 1)
	ln1 = ax.scatter(F12grid[0, :], C[0, 0, 0, 0, :, 0], color='black', facecolor='none', label='SM solutions') #, label='$\overline{\mathbb{C}}_{1111}$ (NN)')  # Fix F11 = 1.1, F22 = 1.1, F21 = -0.4
	ln2 = ax.scatter(F12grid[0, :], C[0, 1, 0, 0, :, 0], color='green', facecolor='none') #, label='$\overline{\mathbb{C}}_{1112}$ (NN)')
	ln3 = ax.scatter(F12grid[0, :], C[0, 2, 0, 0, :, 0], color='blue', facecolor='none') #, label='$\overline{\mathbb{C}}_{1121}$ (NN)')
	ln4 = ax.scatter(F12grid[0, :], C[0, 3, 0, 0, :, 0], color='#641E16', facecolor='none') #, label='$\overline{\mathbb{C}}_{1122}$ (NN)')
	ln5 = ax.scatter(F12grid[0, :], C[1, 1, 0, 0, :, 0], color='magenta', facecolor='none') #, label='$\overline{\mathbb{C}}_{1212}$ (NN)')
	ln6 = ax.scatter(F12grid[0, :], C[1, 2, 0, 0, :, 0], color='chocolate', facecolor='none') #, label='$\overline{\mathbb{C}}_{1221}$ (NN)')
	ln7 = ax.scatter(F12grid[0, :], C[1, 3, 0, 0, :, 0], color='red', facecolor='none') #, label='$\overline{\mathbb{C}}_{1222}$ (NN)')
	ln8 = ax.scatter(F12grid[0, :], C[2, 2, 0, 0, :, 0], color='indigo', facecolor='none') #, label='$\overline{\mathbb{C}}_{2121}$ (NN)')
	ln9 = ax.scatter(F12grid[0, :], C[2, 3, 0, 0, :, 0], color='#7d6608', facecolor='none') #, label='$\overline{\mathbb{C}}_{2122}$ (NN)')
	ln10 = ax.scatter(F12grid[0, :], C[3, 3, 0, 0, :, 0], color='#008080', facecolor='none') #, label='$\overline{\mathbb{C}}_{2222}$ (NN)')

	lf1, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[0, 0, 0, :], color='black', marker='x', linestyle='', fillstyle='none', label='FFT solutions') #, label='$\overline{\mathbb{C}}_{1111}$ (FFT)')
	lf2, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[0, 1, 0, :], color='green', marker='x', linestyle='', fillstyle='none') #, label='$\overline{\mathbb{C}}_{1112}$ (FFT)')
	lf3, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[0, 2, 0, :], color='blue', marker='x', linestyle='', fillstyle='none') #, label='$\overline{\mathbb{C}}_{1121}$ (FFT)')
	lf4, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[0, 3, 0, :], color='#641E16', marker='x', linestyle='', fillstyle='none') #, label='$\overline{\mathbb{C}}_{1122}$ (FFT)')
	lf5, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[1, 1, 0, :], color='magenta', marker='x', linestyle='', fillstyle='none') #, label='$\overline{\mathbb{C}}_{1212}$ (FFT)')
	lf6, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[1, 2, 0, :], color='chocolate', marker='x', linestyle='', fillstyle='none') #, label='$\overline{\mathbb{C}}_{1221}$ (FFT)')
	lf7, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[1, 3, 0, :], color='red', marker='x', linestyle='', fillstyle='none') #, label='$\overline{\mathbb{C}}_{1222}$ (FFT)')
	lf8, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[2, 2, 0, :], color='indigo', marker='x', linestyle='', fillstyle='none') #, label='$\overline{\mathbb{C}}_{2121}$ (FFT)')
	lf9, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[2, 3, 0, :], color='#7d6608', marker='x', linestyle='', fillstyle='none') #, label='$\overline{\mathbb{C}}_{2122}$ (FFT)')
	lf10, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[3, 3, 0, :], color='#008080', marker='x', linestyle='', fillstyle='none') #, label='$\overline{\mathbb{C}}_{2222}$ (FFT)')
	# ax.legend(handles=[ln1, ln2, ln3, ln4, ln5, ln6, ln7, ln8, ln9, ln10, lf1, lf2, lf3, lf4, lf5, lf6, lf7, lf8, lf9, lf10], loc='upper right')
	# ax.legend(loc='upper right')
	# ----------- small box --------------------
	# Shrink current axis by 99%
	box = ax.get_position()
	ax.set_position([box.x0, box.y0, box.width, box.height * 0.99])

	# Put a legend to the right of the current axis
	ax.legend(fontsize='x-small', \
	          ncol=3, fancybox=True, shadow=True, \
	          loc='upper left', bbox_to_anchor=(0.0, 1.14))
	# -------------------------------------------------------
	ax.grid(True)
	ax.set_xlabel(r'$\overline{F}_{12}$', fontsize=18)
	ax.set_ylabel(r'$\overline{\mathbb{C}}_{ijkl}$', fontsize=18)
	# ax.set_title("Effective tangent moduli " + r" $\overline{\mathbb{C}}$ " + " comparison between NN and FFT solutions")
	plt.show()
