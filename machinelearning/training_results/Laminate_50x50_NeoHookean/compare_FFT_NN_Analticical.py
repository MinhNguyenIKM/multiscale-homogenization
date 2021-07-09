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
colorplot = color.coolwarm

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
		[1.067180406282, 0.056881170223],
		[-0.017531358124, 0.842115285381]
	])
	type = 'NeoHooke-Laminate'
	numberM = 50

	W = np.zeros([numberM, numberM, numberM, numberM])
	P = np.zeros([1, 4, numberM, numberM, numberM, numberM])
	C = np.zeros([4, 4, numberM, numberM, numberM, numberM])

	F11 = np.linspace(0.8, 1.2, numberM)
	F12 = np.linspace(-0.2, 0.2, numberM)
	F21 = np.linspace(-0.2, 0.2, numberM)
	F22 = np.linspace(0.8, 1.2, numberM)
	# for i, valF11 in enumerate(F11):
	# 	for j, valF12 in enumerate(F12):
	# 		for k, valF21 in enumerate(F21):
	# 			for l, valF22 in enumerate(F22):
	# 				F_macro = np.array([[valF11, valF12], [valF21, valF22]])
	# 				W[i, j, k, l], P[:, :, i, j, k, l], C[:, :, i, j, k, l] = cal_material_parameter2D(F_macro, type)
	F12grid, F21grid = np.meshgrid(F21, F12)
	valF11 = 1.2
	valF22 = 1.2
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
			filename = './FFT_Laminate_NeoHookean_50x50.dat'
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
						W_FFT[i, j, k, l], P_FFT[:, :, i, j, k, l], C_FFT[:, :, i, j, k, l] = mic2D.solve_nonlinear_GalerkinFFT(F_macro, kind='neo-hookean', mode='everything', domain='laminate')
						print(W_FFT[i, j, k, l])
						# f.write("%0.12f;\t%0.12f;\t%0.12f;\t%0.12f;\t%0.12f\n" % (F_macro[0, 0], F_macro[0, 1], F_macro[1, 0], F_macro[1, 1], W_FFT[i, j, k, l]))
						fileFFT.write("%0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f\n\r" \
						% (F_macro[0, 0], F_macro[0, 1], F_macro[1, 0], F_macro[1, 1], W_FFT[i, j, k, l], \
						   P_FFT[0, 0, i, j, k, l], P_FFT[0, 1, i, j, k, l], P_FFT[1, 0, i, j, k, l], P_FFT[1, 1, i, j, k, l], \
						   C_FFT[0, 0, i, j, k, l], C_FFT[0, 1, i, j, k, l], C_FFT[0, 2, i, j, k, l], C_FFT[0, 3, i, j, k, l], \
						   C_FFT[1, 0, i, j, k, l], C_FFT[1, 1, i, j, k, l], C_FFT[1, 2, i, j, k, l], C_FFT[1, 3, i, j, k, l], \
						   C_FFT[2, 0, i, j, k, l], C_FFT[2, 1, i, j, k, l], C_FFT[2, 2, i, j, k, l], C_FFT[2, 3, i, j, k, l], \
						   C_FFT[3, 0, i, j, k, l], C_FFT[3, 1, i, j, k, l], C_FFT[3, 2, i, j, k, l], C_FFT[3, 3, i, j, k, l]))
		fileFFT.close()
	# --------------------------------------------------- END RUN FFT ---------------------------------------------------

	# ---------------------------------------------------------------------------------------------
	#			ANALYTICAL SOLUTIONS
	# ---------------------------------------------------------------------------------------------
	# file_analytical = './Analytical_F11_F22_50x50_NeoHookean_F_W.dat'
	file_analytical = './Analytical_F12_F21_Laminate_NeoHookean_50x50.dat'
	try:
		with open(file_analytical) as f:
			content = np.array(f.readlines())
	except IOError as e:
		print("An error occurred trying to read the file: " + e.filename)
		exit()
	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	eof = len(content)
	F12_exact = np.zeros(eof)
	F21_exact = np.zeros(eof)
	W_exact = np.zeros(eof)
	rows = 50;
	columns = 50;
	F12grid_exact = np.zeros([rows, columns])
	F21grid_exact = np.zeros([rows, columns])
	Wgrid_exact = np.zeros([rows, columns])
	P11grid_exact = np.zeros([rows, columns])
	Pgrid_exact = np.zeros([2, 2, rows, columns])
	C1111grid_exact = np.zeros([rows, columns])
	Cgrid_exact = np.zeros([4, 4, rows, columns])
	i = -1
	while i < eof - 1:
		i += 1
		line = content[i]
		# print(line)
		if re.search('#*[a-zA-Z]+', line):
			continue
		else:
			segments = fp.get_values_wsplit(line, ';')
			F12_exact[i] = segments[0]
			F21_exact[i] = segments[1]
			W_exact[i] = segments[2]
			F12grid_exact[i % rows, i / columns] = segments[0]
			F21grid_exact[i % rows, i / columns] = segments[1]
			Wgrid_exact[i % rows, i / columns] = segments[2]
			P11grid_exact[i % rows, i / columns] = segments[3]
			Pgrid_exact[0, 0, i % rows, i / columns] = segments[3]
			Pgrid_exact[0, 1, i % rows, i / columns] = segments[4]
			Pgrid_exact[1, 0, i % rows, i / columns] = segments[5]
			Pgrid_exact[1, 1, i % rows, i / columns] = segments[6]
			C1111grid_exact[i % rows, i / columns] = segments[7]
			Cgrid_exact[0, 0, i % rows, i / columns] = segments[7]
			Cgrid_exact[0, 1, i % rows, i / columns] = segments[8]
			Cgrid_exact[0, 2, i % rows, i / columns] = segments[9]
			Cgrid_exact[0, 3, i % rows, i / columns] = segments[10]
			Cgrid_exact[1, 0, i % rows, i / columns] = segments[11]
			Cgrid_exact[1, 1, i % rows, i / columns] = segments[12]
			Cgrid_exact[1, 2, i % rows, i / columns] = segments[13]
			Cgrid_exact[1, 3, i % rows, i / columns] = segments[14]
			Cgrid_exact[2, 0, i % rows, i / columns] = segments[15]
			Cgrid_exact[2, 1, i % rows, i / columns] = segments[16]
			Cgrid_exact[2, 2, i % rows, i / columns] = segments[17]
			Cgrid_exact[2, 3, i % rows, i / columns] = segments[18]
			Cgrid_exact[3, 0, i % rows, i / columns] = segments[19]
			Cgrid_exact[3, 1, i % rows, i / columns] = segments[20]
			Cgrid_exact[3, 2, i % rows, i / columns] = segments[21]
			Cgrid_exact[3, 3, i % rows, i / columns] = segments[22]

	# ---------------------------------------------------------------------------------------------
	#			FFT SOLUTIONS
	# ---------------------------------------------------------------------------------------------
	file_FFT = './FFT_Laminate_NeoHookean_50x50.dat'
	try:
		with open(file_FFT) as f:
			content = np.array(f.readlines())
	except IOError as e:
		print("An error occurred trying to read the file: " + e.filename)
		exit()
	eof = len(content)
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
			continue
		else:
			segments = fp.get_values_wsplit(line, ';')
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
	# fig, ax = plt.subplots(3, 1)
	# fig.subplots_adjust(hspace=0.3)
	# plt.subplot(331)
	Z = W[0, :, :, 0]
	# ax = fig.gca(projection='3d')
	ax.plot_surface(X, Y, Z, cmap=colorplot)
	cset = ax.contourf(X, Y, Z, zdir='z', offset=30, cmap=colorplot)
	ax.set_xlabel('$\overline{F}_{12}$')
	ax.set_xlim(-0.2, 0.2)
	ax.set_ylabel('$\overline{F}_{21}$')
	ax.set_ylim(-0.2, 0.2)
	ax.set_zlabel('$\overline{\psi}(\overline{\mathbf{F}})$')
	ax.set_zlim(30, 60)
	ax.view_init(elev=20, azim=-40)
	# ax.set_title("SM solutions")

	fig = plt.figure('SM2', figsize=(4.0, 3.5))
	ax = fig.add_subplot(nrows, ncols, 1, projection='3d')
	Z = P[0, 0, 0, :, :, 0] # P_11 at all grid points
	# ax = fig.gca(projection='3d')
	ax.plot_surface(X, Y, Z, cmap=colorplot)
	cset2 = ax.contourf(X, Y, Z, zdir='z', offset=97, cmap=colorplot)
	ax.set_xlabel('$\overline{F}_{12}$')
	ax.set_xlim(-0.2, 0.2)
	ax.set_ylabel('$\overline{F}_{21}$')
	ax.set_ylim(-0.2, 0.2)
	ax.set_zlabel('$\overline{P}_{11}$')
	ax.set_zlim(97, 107)
	ax.view_init(elev=20, azim=-40)

	fig = plt.figure('SM3', figsize=(4.0, 3.5))
	ax = fig.add_subplot(nrows, ncols, 1, projection='3d')
	Z = C[0, 0, 0, :, :, 0]  # C_1111 at all grid points
	# ax = fig.gca(projection='3d')
	ax.plot_surface(X, Y, Z, cmap=colorplot)
	cset3 = ax.contourf(X, Y, Z, zdir='z', offset=280, cmap=colorplot)
	ax.set_xlabel('$\overline{F}_{12}$')
	ax.set_xlim(-0.2, 0.2)
	ax.set_ylabel('$\overline{F}_{21}$')
	ax.set_ylim(-0.2, 0.2)
	ax.set_zlabel('$\overline{\mathbb{C}}_{1111}$')
	ax.set_zlim(280, 320)
	ax.view_init(elev=20, azim=-40)

	fig = plt.figure('FFT1', figsize=(4.0, 3.5))
	ax = fig.add_subplot(nrows, ncols, 1, projection='3d')
	ax.plot_surface(F12grid_FFT, F21grid_FFT, Wgrid_FFT, cmap=colorplot)
	cset = ax.contourf(F12grid_FFT, F21grid_FFT, Wgrid_FFT, zdir='z', offset=30, cmap=colorplot)
	ax.set_xlabel('$\overline{F}_{12}$')
	ax.set_xlim(-0.2, 0.2)
	ax.set_ylabel('$\overline{F}_{21}$')
	ax.set_ylim(-0.2, 0.2)
	ax.set_zlabel('$\overline{\psi}(\overline{\mathbf{F}})$')
	ax.set_zlim(30, 60)
	ax.view_init(elev=20, azim=-40)
	# ax.set_title('FFT solutions')

	fig = plt.figure('FFT2', figsize=(4.0, 3.5))
	ax = fig.add_subplot(nrows, ncols, 1, projection='3d')
	ax.plot_surface(F12grid_FFT, F21grid_FFT, P11grid_FFT, cmap=colorplot)
	cset2 = ax.contourf(F12grid_FFT, F21grid_FFT, P11grid_FFT, zdir='z', offset=97, cmap=colorplot)
	ax.set_xlabel('$\overline{F}_{12}$')
	ax.set_xlim(-0.2, 0.2)
	ax.set_ylabel('$\overline{F}_{21}$')
	ax.set_ylim(-0.2, 0.2)
	ax.set_zlabel('$\overline{P}_{11}$')
	ax.set_zlim(97, 107)
	ax.view_init(elev=20, azim=-40)

	fig = plt.figure('FFT3', figsize=(4.0, 3.5))
	ax = fig.add_subplot(nrows, ncols, 1, projection='3d')
	ax.plot_surface(F12grid_FFT, F21grid_FFT, C1111grid_FFT, cmap=colorplot)
	cset3 = ax.contourf(F12grid_FFT, F21grid_FFT, C1111grid_FFT, zdir='z', offset=280, cmap=colorplot)
	ax.set_xlabel('$\overline{F}_{12}$')
	ax.set_xlim(-0.2, 0.2)
	ax.set_ylabel('$\overline{F}_{21}$')
	ax.set_ylim(-0.2, 0.2)
	ax.set_zlabel('$\overline{\mathbb{C}}_{1111}$')
	ax.set_zlim(280, 320)
	ax.view_init(elev=20, azim=-40)

	# ---- Exact
	fig = plt.figure('Exact1', figsize=(4.0, 3.5))
	# fig = plt.figure(figsize=(10, 16))
	ax = fig.add_subplot(nrows, ncols, 1, projection='3d')
	ax.plot_surface(F12grid_exact, F21grid_exact, Wgrid_exact, cmap=colorplot)
	cset = ax.contourf(F12grid_exact, F21grid_exact, Wgrid_exact, zdir='z', offset=30, cmap=colorplot)
	ax.set_xlabel('$\overline{F}_{12}$')
	ax.set_xlim(-0.2, 0.2)
	ax.set_ylabel('$\overline{F}_{21}$')
	ax.set_ylim(-0.2, 0.2)
	ax.set_zlabel('$\overline{\psi}(\overline{\mathbf{F}})$')
	ax.set_zlim(30, 60)
	ax.view_init(elev=20, azim=-40)
	# ax.set_title('Analytical solutions')

	fig = plt.figure('Exact2', figsize=(4.0, 3.5))
	ax = fig.add_subplot(nrows, ncols, 1, projection='3d')
	ax.plot_surface(F12grid_exact, F21grid_exact, P11grid_exact, cmap=colorplot)
	cset2 = ax.contourf(F12grid_exact, F21grid_exact, P11grid_exact, zdir='z', offset=97, cmap=colorplot)
	ax.set_xlabel('$\overline{F}_{12}$')
	ax.set_xlim(-0.2, 0.2)
	ax.set_ylabel('$\overline{F}_{21}$')
	ax.set_ylim(-0.2, 0.2)
	ax.set_zlabel('$\overline{P}_{11}$')
	ax.set_zlim(97, 107)
	ax.view_init(elev=20, azim=-40)

	fig = plt.figure('Exact3', figsize=(4.0, 3.5))
	ax = fig.add_subplot(nrows, ncols, 1, projection='3d')
	ax.plot_surface(F12grid_exact, F21grid_exact, C1111grid_exact, cmap=colorplot)
	cset3 = ax.contourf(F12grid_exact, F21grid_exact, C1111grid_exact, zdir='z', offset=280, cmap=colorplot)
	ax.set_xlabel('$\overline{F}_{12}$')
	ax.set_xlim(-0.2, 0.2, auto=True)
	ax.set_ylabel('$\overline{F}_{21}$')
	ax.set_ylim(-0.2, 0.2)
	ax.set_zlabel('$\overline{\mathbb{C}}_{1111}$')
	ax.set_zlim(280, 320)
	ax.view_init(elev=20, azim=-40)

	# plt.show()
	# exit()
	fig2 = plt.figure(figsize=(7, 5))
	# ax = fig2.add_subplot(1, 1, 1)
	ax = fig2.add_subplot(1, 1, 1, projection='3d')
	X = F12grid ; Y = F21grid ; Z = W[0, :, :, 0]
	# ax.plot_surface(X, Y, Z, cmap=colorplot)
	ax.plot_surface(X, Y, (Z - Wgrid_exact) / (Wgrid_exact), cmap=colorplot)
	# cset = ax.contourf(X, Y, Z, zdir='z', offset=30, cmap=colorplot)
	# Werror = (Z - Wgrid_exact) / (Wgrid_exact)
	# p1 = ax.pcolor(X, Y, Werror, cmap=color.coolwarm, vmin=Werror.min(), vmax=Werror.max())
	# cb = fig.colorbar(p1)
	ax.set_xlabel('$\overline{F}_{12}$')
	ax.set_xlim(-0.2, 0.2)
	ax.set_ylabel('$\overline{F}_{21}$')
	ax.set_ylim(-0.2, 0.2)
	ax.set_zlabel('error')
	# ax.tick_params(labelsize=7)
	# ax.set_title('Relative error between NN and Exact energy', fontsize=8)
	# ax.set_zlim(30, 60)
	# ax.view_init(elev=20, azim=-40)

	fig22 = plt.figure('relative error',figsize=(7, 5))
	ax = fig22.add_subplot(1, 1, 1, projection='3d')
	X = F12grid_FFT ; Y = F21grid_FFT ; Z = Wgrid_FFT
	# ax.plot_surface(X, Y, Z, cmap=colorplot)
	ax.plot_surface(X, Y, (Z - Wgrid_exact) / (Wgrid_exact), cmap=colorplot)
	# cset = ax.contourf(X, Y, Z, zdir='z', offset=30, cmap=colorplot)
	# ax = fig22.add_subplot(1, 1, 1)
	# Werror = (Z - Wgrid_exact) / (Wgrid_exact)
	# p1 = ax.pcolor(X, Y, Werror, cmap=color.coolwarm, vmin=Werror.min(), vmax=Werror.max())
	# cb = fig22.colorbar(p1)
	# cb.set_label("$Error$")
	ax.set_xlabel(r'$\overline{F}_{12}$')
	ax.set_xlim(-0.2, 0.2)
	ax.set_ylabel(r'$\overline{F}_{21}$')
	ax.set_ylim(-0.2, 0.2)
	ax.set_zlabel('error')
	ax.tick_params()
	# ax.set_title('Relative error between FFT and Exact energy', fontsize=8)
	# ax.set_zlim(30, 60)
	# ax.view_init(elev=20, azim=-40)


	fig = plt.figure()
	ax = fig.add_subplot(1, 1, 1)

	# Luu y: Chi so P[0, 0, 0, 0, :, 0] luc nay tuong trung cho P11 (2 so 0 dau) trong do i,j,l fixed, chay k (tuong ung voi F21).
	p11nn = ax.scatter(F12grid[0, :], P[0, 0, 0, 0, :, 0], color='r', facecolors='none', label='SM solutions')  # Fix F11 = 1.2, F22 = 1.2, F21 = -0.2
	p12nn = ax.scatter(F12grid[0, :], P[0, 1, 0, 0, :, 0], color='g', facecolors='none') #, label='$\overline{P}_{12}$ (NN)')
	p21nn = ax.scatter(F12grid[0, :], P[0, 2, 0, 0, :, 0], color='b', facecolors='none') #, label='$\overline{P}_{21}$ (NN)')
	p22nn = ax.scatter(F12grid[0, :], P[0, 3, 0, 0, :, 0], color='k', facecolors='none') #, label='$\overline{P}_{22}$ (NN)')
	# ax.legend([p11nn, p12nn, p21nn, p22nn], ['', 'P_12 (NN)', 'P_21 (NN)', 'P_22 (NN)'])
	p11fft, = ax.plot(F12grid_FFT[0, :], Pgrid_FFT[0, 0, 0, :], 'rx', label='FFT solutions')
	p12fft, = ax.plot(F12grid_FFT[0, :], Pgrid_FFT[0, 1, 0, :], 'gx') #, label='$\overline{P}_{12}$ (FFT)')
	p21fft, = ax.plot(F12grid_FFT[0, :], Pgrid_FFT[1, 0, 0, :], 'bx') #, label='$\overline{P}_{21}$ (FFT)')
	p22fft, = ax.plot(F12grid_FFT[0, :], Pgrid_FFT[1, 1, 0, :], 'kx') #, label='$\overline{P}_{22}$ (FFT)')
	# ax.legend([], ['P_11 (FFT)', 'P_12 (FFT)', 'P_21 (FFT)', 'P_22 (FFT)'])
	pa1, = ax.plot(F12grid_exact[0, :], Pgrid_exact[0, 0, 0, :], 'r--') #, label='$\overline{P}_{11}$')
	pa2, = ax.plot(F12grid_exact[0, :], Pgrid_exact[0, 1, 0, :], 'g--') #, label='$\overline{P}_{12}$')
	pa3, = ax.plot(F12grid_exact[0, :], Pgrid_exact[1, 0, 0, :], 'b--') #, label='$\overline{P}_{21}$')
	pa4, = ax.plot(F12grid_exact[0, :], Pgrid_exact[1, 1, 0, :], 'k--') #, label='$\overline{P}_{22}$')
	# ax.legend(['P_11 (Analytical)', 'P_12 (Analytical)', 'P_21 (Analytical)', 'P_22 (Analytical)'])
	pa5, = ax.plot(F12grid_exact[0, 0], Pgrid_exact[0, 0, 0, 0], 'r--', label='Analytical solutions')  # This is just for legent explanation
	# ax.legend(handles=[pa1, pa2, pa3, pa4, p11nn, p11fft, pa5], loc='upper right')
	# ----------- small box --------------------
	# Shrink current axis by 99%
	box = ax.get_position()
	ax.set_position([box.x0, box.y0, box.width, box.height*0.99])

	# Put a legend to the right of the current axis
	ax.legend(fontsize='x-small',#, handles=[pa1, pa2, pa3, pa4, p11nn, p11fft, pa5], \
	          ncol=3, fancybox=True, shadow=True, \
	          loc='upper left', bbox_to_anchor=(0.0, 1.14))
	#-------------------------------------------------------
	ax.grid(True)
	ax.set_xlabel(r'$\overline{F}_{12}$')
	ax.set_ylabel(r'$\overline{P}_{ij}$')
	# ax.set_title('First Piola-Kirchhoff stress comparison between NN, FFT and Analytical solutions')

	fig = plt.figure()
	ax = fig.add_subplot(1, 1, 1)
	ln1 = ax.scatter(F12grid[0, :], C[0, 0, 0, 0, :, 0], color='r', facecolor='none', label='SM solutions')  # Fix F11 = 1.2, F22 = 1.2, F21 = -0.2
	ln2 = ax.scatter(F12grid[0, :], C[0, 1, 0, 0, :, 0], color='g', facecolor='none') #, label='$\overline{\mathbb{C}}_{1112}$ (NN)')
	ln3 = ax.scatter(F12grid[0, :], C[0, 2, 0, 0, :, 0], color='b', facecolor='none') #, label='$\overline{\mathbb{C}}_{1121}$ (NN)')
	ln4 = ax.scatter(F12grid[0, :], C[0, 3, 0, 0, :, 0], color='k', facecolor='none') #, label='$\overline{\mathbb{C}}_{1122}$ (NN)')
	ln5 = ax.scatter(F12grid[0, :], C[1, 1, 0, 0, :, 0], color='C1',  facecolor='none')  # , label='$\overline{\mathbb{C}}_{1212}$ (NN)')
	ln6 = ax.scatter(F12grid[0, :], C[1, 2, 0, 0, :, 0], color='C2', facecolor='none') #, label='$\overline{\mathbb{C}}_{1221}$ (NN)')
	ln7 = ax.scatter(F12grid[0, :], C[1, 3, 0, 0, :, 0], color='C3', facecolor='none') #, label='$\overline{\mathbb{C}}_{1122}$ (NN)')
	ln8 = ax.scatter(F12grid[0, :], C[2, 2, 0, 0, :, 0], color='C4', facecolor='none') #, label='$\overline{\mathbb{C}}_{2121}$ (NN)')
	ln9 = ax.scatter(F12grid[0, :], C[2, 3, 0, 0, :, 0], color='C5', facecolor='none') #, label='$\overline{\mathbb{C}}_{2122}$ (NN)')
	ln10 = ax.scatter(F12grid[0, :], C[3, 3, 0, 0, :, 0], color='C6', facecolor='none') #, label='$\overline{\mathbb{C}}_{2222}$ (NN)')

	lf1, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[0, 0, 0, :], 'rx', label='FFT solutions')
	lf2, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[0, 1, 0, :], 'gx') #, label='$\overline{\mathbb{C}}_{1112}$ (FFT)')
	lf3, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[0, 2, 0, :], 'bx') #, label='$\overline{\mathbb{C}}_{1121}$ (FFT)')
	lf4, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[0, 3, 0, :], 'kx') #, label='$\overline{\mathbb{C}}_{1122}$ (FFT)')
	lf5, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[1, 1, 0, :], 'C1x') #, label='$\overline{\mathbb{C}}_{1212}$ (FFT)')
	lf6, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[1, 2, 0, :], 'C2x') #, label='$\overline{\mathbb{C}}_{1221}$ (FFT)')
	lf7, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[1, 3, 0, :], 'C3x') #, label='$\overline{\mathbb{C}}_{1122}$ (FFT)')
	lf8, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[2, 2, 0, :], 'C4x') #, label='$\overline{\mathbb{C}}_{2121}$ (FFT)')
	lf9, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[2, 3, 0, :], 'C5x') #, label='$\overline{\mathbb{C}}_{2122}$ (FFT)')
	lf10, = ax.plot(F12grid_FFT[0, :], Cgrid_FFT[3, 3, 0, :], 'C6x') #, label='$\overline{\mathbb{C}}_{2222}$ (FFT)')

	la1, = ax.plot(F12grid_exact[0, :], Cgrid_exact[0, 0, 0, :], 'r--') #, label='$\overline{\mathbb{C}}_{1111}$')
	la2, = ax.plot(F12grid_exact[0, :], Cgrid_exact[0, 1, 0, :], 'g--') #, label='$\overline{\mathbb{C}}_{1112}$')
	la3, = ax.plot(F12grid_exact[0, :], Cgrid_exact[0, 2, 0, :], 'b--') #, label='$\overline{\mathbb{C}}_{1121}$')
	la4, = ax.plot(F12grid_exact[0, :], Cgrid_exact[0, 3, 0, :], 'k--') #, label='$\overline{\mathbb{C}}_{1122}$')
	la5, = ax.plot(F12grid_exact[0, :], Cgrid_exact[1, 1, 0, :], 'C1--') #, label='$\overline{\mathbb{C}}_{1212}$')
	la6, = ax.plot(F12grid_exact[0, :], Cgrid_exact[1, 2, 0, :], 'C2--') #, label='$\overline{\mathbb{C}}_{1221}$')
	la7, = ax.plot(F12grid_exact[0, :], Cgrid_exact[1, 3, 0, :], 'C3--') #, label='$\overline{\mathbb{C}}_{1222}$')
	la8, = ax.plot(F12grid_exact[0, :], Cgrid_exact[2, 2, 0, :], 'C4--') #, label='$\overline{\mathbb{C}}_{2121}$')
	la9, = ax.plot(F12grid_exact[0, :], Cgrid_exact[2, 3, 0, :], 'C5--') #, label='$\overline{\mathbb{C}}_{2122}$')
	la10, = ax.plot(F12grid_exact[0, :], Cgrid_exact[3, 3, 0, :], 'C6--') #, label='$\overline{\mathbb{C}}_{2222}$')
	# ax.legend(loc='upper right')
	la11, = ax.plot(F12grid_exact[0, 0], Cgrid_exact[0, 0, 0, 0], 'r--', label='Analytical solutions')  # This is just for legent explanation
	# plt.legend(handles=[la1, la2, la3, la4, la5, la6, la7, la8, la9, la10, ln1, lf1, la11], loc='upper right')
	# ----------- small box --------------------
	# Shrink current axis by 99%
	box = ax.get_position()
	ax.set_position([box.x0, box.y0, box.width, box.height * 0.99])

	# Put a legend to the right of the current axis
	ax.legend(fontsize='x-small', #, handles=[la1, la2, la3, la4, la5, la6, la7, la8, la9, la10, ln1, lf1, la11], \
	          ncol=3, fancybox=True, shadow=True, \
	          loc='upper left', bbox_to_anchor=(0.0, 1.14))
	# -------------------------------------------------------
	ax.grid(True)
	ax.set_xlabel(r'$\overline{F}_{12}$')
	ax.set_ylabel(r'$\overline{\mathbb{C}}_{ijkl}$')
	# ax.set_title("Effective tangent moduli " + r" $\overline{\mathbb{C}}$ " + " comparison between NN, FFT and Analytical solutions")
	plt.show()
	exit()

	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub1 = fig.add_subplot(1, 1, 1, projection='3d')
	# sub1 = fig.add_subplot(1, 1, 1)
	# sub1.plot(F12, W[0, :, 0, 0])
	# sub1 = fig.add_subplot(3, 1, 2, projection='3d')
	sub1.plot_surface(F12grid, F21grid, W[0, :, :, 0], rstride=1, cstride=1, cmap=colorplot)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=colorplot)
	cset = sub1.contourf(F12grid, F21grid, W[0, :, :, 0], zdir='z', offset=-100, cmap=colorplot)
	sub1.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	# plt.show()
	# exit()

	# fig = plt.figure()
	# ax = fig.gca(projection='3d')
	# X, Y, Z = axes3d.get_test_data(0.05)
	# ax.plot_surface(X, Y, Z, rstride=8, cstride=8, alpha=0.3)
	# cset = ax.contourf(X, Y, Z, zdir='z', offset=-100, cmap=cm.jet)
	# cset = ax.contourf(X, Y, Z, zdir='x', offset=-40, cmap=cm.jet)
	# cset = ax.contourf(X, Y, Z, zdir='y', offset=40, cmap=cm.jet)
	#
	# ax.set_xlabel('X')
	# ax.set_xlim(-40, 40)
	# ax.set_ylabel('Y')
	# ax.set_ylim(-40, 40)
	# ax.set_zlabel('Z')
	# ax.set_zlim(-100, 100)

	# -------------------------------------------------------------------------------------------
	#   PLOT MESH and VALUES
	# -------------------------------------------------------------------------------------------
	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub2 = fig.add_subplot(1, 1, 1, projection='3d')
	sub2.plot_surface(F12grid, F21grid, P[0, 3, 0, :, :, 0], rstride=1, cstride=1, cmap=colorplot)
	# sub2 = fig.add_subplot(3, 1, 2, projection='3d')
	# sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=colorplot)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=colorplot)
	sub2.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	# plt.show()

	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub3 = fig.add_subplot(1, 1, 1, projection='3d')
	sub3.plot_surface(F12grid, F21grid, C[0, 0, 0, :, :, 0], rstride=1, cstride=1, cmap=colorplot)
	# sub2 = fig.add_subplot(3, 1, 2, projection='3d')
	# sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=colorplot)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=colorplot)
	sub3.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	plt.show()
	exit()
	RMSE_W = np.power(1.0/(size**6) * np.sum(np.power(exactW - W, 2)), 0.5)
	print(RMSE_W)
	M = 10**3
	X = np.linspace(-1, 1, M)
	W_exact = np.zeros(M)
	W_NN = np.zeros(M)
	for i in range(M):
		X1 = X[i]
		W_exact[i] = functionF2(X1, X1, X1, X1, X1, X1)
		print(W_exact[i])
		F_macro = np.array([X1, X1, X1, X1, X1, X1])
		W_NN[i], _,_ = cal_material_parameter2D(F_macro, type)
		print(W_NN[i])
	fig = plt.figure(figsize=plt.figaspect(0.5))
	RMSE_W2 = np.power(1.0 / (M) * np.sum(np.power(W_exact - W_NN, 2)), 0.5)
	print(RMSE_W2)
	sub12 = fig.add_subplot(1, 1, 1)
	sub12.plot(X, W_exact)
	sub12.plot(X, W_NN)
	plt.show()
	exit()
	# --------------------------------END PLOT ----------------------------------------------------
	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub2 = fig.add_subplot(1, 1, 1, projection='3d')
	sub2.plot_surface(Xmesh, Ymesh, P[0,0,:,:], rstride=1, cstride=1, cmap=colorplot)
	# sub2 = fig.add_subplot(3, 1, 2, projection='3d')
	# sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=colorplot)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=colorplot)
	sub2.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	# plt.show()
	# --------------------------------END PLOT ----------------------------------------------------
	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub3 = fig.add_subplot(1, 1, 1, projection='3d')
	sub3.plot_surface(Xmesh, Ymesh, P[0, 1, :, :], rstride=1, cstride=1, cmap=colorplot)
	# sub2 = fig.add_subplot(3, 1, 2, projection='3d')
	# sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=colorplot)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=colorplot)
	sub3.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	# plt.show()
	# --------------------------------END PLOT ----------------------------------------------------
	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub4 = fig.add_subplot(1, 1, 1, projection='3d')
	sub4.plot_surface(Xmesh, Ymesh, C[0, 0, :, :], rstride=1, cstride=1, cmap=colorplot)
	# sub2 = fig.add_subplot(3, 1, 2, projection='3d')
	# sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=colorplot)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=colorplot)
	sub4.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	# plt.show()
	# --------------------------------END PLOT ----------------------------------------------------
	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub5 = fig.add_subplot(1, 1, 1, projection='3d')
	sub5.plot_surface(Xmesh, Ymesh, C[1, 1, :, :], rstride=1, cstride=1, cmap=colorplot)
	# sub2 = fig.add_subplot(3, 1, 2, projection='3d')
	# sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=colorplot)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=colorplot)
	sub5.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	# plt.show()
	# --------------------------------END PLOT ----------------------------------------------------
	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub6 = fig.add_subplot(1, 1, 1, projection='3d')
	sub6.plot_surface(Xmesh, Ymesh, C[0, 1, :, :], rstride=1, cstride=1, cmap=colorplot)
	# sub2 = fig.add_subplot(3, 1, 2, projection='3d')
	# sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=colorplot)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=colorplot)
	sub6.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	# plt.show()
	# --------------------------------END PLOT ----------------------------------------------------
	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub7 = fig.add_subplot(1, 1, 1, projection='3d')
	sub7.plot_surface(Xmesh, Ymesh, C[1, 0, :, :], rstride=1, cstride=1, cmap=colorplot)
	# sub2 = fig.add_subplot(3, 1, 2, projection='3d')
	# sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=colorplot)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=colorplot)
	sub7.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	plt.show()
