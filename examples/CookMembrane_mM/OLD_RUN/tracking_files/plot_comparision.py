#!/usr/bin/env python2
from util import FileProcessing as fp
from numpy import dot, exp, ones
import numpy as np
from matplotlib import pyplot as plt
from matplotlib import cm as color
from mpl_toolkits.mplot3d import Axes3D
import itertools
import re

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
	return hessian * (1.0 / dgdf) * np.dot(dxidx.reshape(6, 1), dxidx.reshape(1, 6))

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
	elif type == '2DLaminate':
		filename = 'yvonnetFunction3d_1com_3_NNs.dat'
	dimD, dimd, L, N, activation_func_type, min_input, max_input, min_max_output, \
	A, w, c, b, d, d0 = fp.get_NN_parameters(filename)
	F_macro = tramnnmx(F_macro.reshape(-1), min_input, max_input)
	sigma_macro = np.zeros(6)
	P = np.zeros(6)
	C_effective = np.zeros([6, 6])
	energy = 0
	for i in range(0, L):
		y = dot(A[:, :, i], F_macro) + b[:, :, i].reshape(-1)
		for n in range(0, N):
			z = dot(w[n, :, i], y) + d[n, :, i]
			zm = dot(w[n, :, i], y)
			energy += c[n,:,i] * tansig(z)
			sigma_macro += c[n, :, i] * dot(w[n, :, i], A[:, :, i]) * derivative_activation(z)
			C_effective += c[n, :, i] * dot(dot(w[n, :, i], A[:, :, i]).reshape(6, 1), dot(w[n, :, i], A[:, :, i]).reshape(1, 6)) \
						   * 4 * ((-2 * exp(-2*z) / (1 + exp(-2*z)) ** 2) + (4 * exp(-4*z) / (1 + exp(-2*z)) ** 3))
		energy += d0[:, :, i].reshape(-1)
	# return the real scale data
	energy_aver = postmnmx(energy, min_max_output[0], min_max_output[1])
	P = return_to_rescale_for_stress(sigma_macro, min_input, max_input, min_max_output[0], min_max_output[1])
	# P[0] = return_to_rescale_for_stress(sigma_macro[0], min_input[0], max_input[0], min_max_output[0], min_max_output[1])
	# P[1] = return_to_rescale_for_stress(sigma_macro[1], min_input[1], max_input[1], min_max_output[0], min_max_output[1])
	# P[2] = return_to_rescale_for_stress(sigma_macro[2], min_input[2], max_input[2], min_max_output[0], min_max_output[1])
	# P[3] = return_to_rescale_for_stress(sigma_macro[3], min_input[3], max_input[3], min_max_output[0], min_max_output[1])
	# sigma_macro[0] = postmnmx2(sigma_macro[0], min_max_output[0], min_max_output[1])
	# sigma_macro[1] = postmnmx2(sigma_macro[1], min_max_output[0], min_max_output[1])
	# sigma_macro[2] = postmnmx2(sigma_macro[2], min_max_output[0], min_max_output[1])
	# sigma_macro[3] = postmnmx2(sigma_macro[3], min_max_output[0], min_max_output[1])
	print(sigma_macro)
	# C_effective = postmnmx(C_effective, min_max_output[0], min_max_output[1])
	C_effective_unscaled = unnormalize_for_hessian(C_effective, min_input, max_input, min_max_output[0], min_max_output[1])
	return energy_aver, P, C_effective_unscaled


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
if __name__ == '__main__':
	# infile = './tracking_DeformationGradient_NeoHooke_FEM.txt'
	infile = './tracking_DeformationGradient.txt'
	try:
		with open(infile) as f:
			content = np.array(f.readlines())
	except IOError as e:
		print("An error occurred trying to read the file: " + e.filename)
		exit()
	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	eof = len(content)
	F = np.zeros([2, 2, eof])
	P = np.zeros([2, 2, eof])
	W = np.zeros(eof)
	i = -1
	while i < eof-1:
		i += 1
		line = content[i]
		res = re.sub('[( \t\n\r)+]', '', line).split(';')
		segments = np.array(res).astype(np.float)
		if segments.size == 0:
			continue
		else:
			F[0, 0, i] = segments[0]
			F[0, 1, i] = segments[1]
			F[1, 0, i] = segments[2]
			F[1, 1, i] = segments[3]
			P[0, 0, i] = segments[4]
			P[0, 1, i] = segments[5]
			P[1, 0, i] = segments[6]
			P[1, 1, i] = segments[7]
			# W[i] = segments[4]
	# infile = './tracking_DeformationGradient_NeoHooke_NN.txt'
	infile = './tracking_DeformationGradient_NN.txt'
	try:
		with open(infile) as f:
			content = np.array(f.readlines())
	except IOError as e:
		print("An error occurred trying to read the file: " + e.filename)
		exit()
	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	eof = len(content)
	F_NN = np.zeros([2, 2, eof])
	P_NN = np.zeros([2, 2, eof])
	W_NN = np.zeros(eof)
	i = -1
	while i < eof - 1:
		i += 1
		line = content[i]
		res = re.sub('[( \t\n\r)+]', '', line).split(';')
		segments = np.array(res).astype(np.float)
		if segments.size == 0:
			continue
		else:
			F_NN[0, 0, i] = segments[0]
			F_NN[0, 1, i] = segments[1]
			F_NN[1, 0, i] = segments[2]
			F_NN[1, 1, i] = segments[3]
			P_NN[0 ,0, i] = segments[4]
			P_NN[0, 1, i] = segments[5]
			P_NN[1, 0, i] = segments[6]
			P_NN[1, 1, i] = segments[7]
			# W_NN[i] = segments[4]
	# print(F)
	# print(P)
	# -------------------------------------------------------------------------------------------
	#   PLOT MESH and VALUES
	# -------------------------------------------------------------------------------------------
	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub1 = fig.add_subplot(1, 1, 1)
	# sub1 = fig.add_subplot(1, 1, 1)
	index_sorted_decending = np.argsort(F[0, 0, :])
	sub1.scatter(F[0, 0, index_sorted_decending], P[0, 0, index_sorted_decending])

	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub2 = fig.add_subplot(1, 1, 1)
	# sub2 = fig.add_subplot(1, 1, 1)

	index_sorted_decending = np.argsort(F_NN[0, 0, :])
	sub2.scatter(F_NN[0, 0, index_sorted_decending], P_NN[0, 0, index_sorted_decending])

	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub3 = fig.add_subplot(1, 1, 1)
	index_sorted_decending = np.argsort(F_NN[0, 0, :])
	sub3.scatter(F_NN[0, 0, index_sorted_decending], P_NN[0, 0, index_sorted_decending])
	plt.show()
	exit()
	functionF = lambda Xparam, Yparam: np.exp(np.sin(np.pi * Xparam) * np.cos(np.pi * Yparam))
	functionF2 = lambda X1, X2, X3, X4, X5, X6: X1**2 + X2**2 + X3**2 + X4**2 + X5**2 + X6**2
	F_macro = np.array([-0.67180406282, 0.056881170223])
	# F_macro = np.array([[1.067180406282, 0],
	# 				[0, 0.842115285381]])
	type = '2DLaminate'
	size = 1
	exactW = np.zeros([size,size,size,size,size,size])
	W = np.zeros([size,size,size,size,size,size])
	P = np.zeros([1,6,size,size,size,size,size,size])
	C = np.zeros([6,6,size,size,size,size,size,size])
	X = np.linspace(-1, 1, size)
	# Xmesh, Ymesh = np.meshgrid(X, Y)
	for i, j, k, l, m, n in itertools.product(range(size), repeat=6):
		F_macro = np.array([X[i], X[j], X[k], X[l], X[m], X[n]])
		# F_macro = np.array([0.5, 0.5])
		exactW[i, j, k, l, m, n] = functionF2(X[i], X[j], X[k], X[l], X[m], X[n])
		print(exactW[i, j, k, l, m, n])
		W[i, j, k, l, m, n], P[:, :, i, j, k, l, m, n], C[:, :, i, j, k, l, m, n] = cal_material_parameter2D(F_macro, type)
		print(W[i, j, k, l, m, n])
	# -------------------------------------------------------------------------------------------
	#   PLOT MESH and VALUES
	# -------------------------------------------------------------------------------------------
	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub1 = fig.add_subplot(1, 1, 1, projection='3d')
	# sub1.plot(Xmesh, Ymesh, W, rstride=1, cstride=1, cmap=color.coolwarm)
	# sub2 = fig.add_subplot(3, 1, 2, projection='3d')
	# sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	sub1.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	# plt.show()
	# -------------------------------------------------------------------------------------------
	#   PLOT MESH and VALUES
	# -------------------------------------------------------------------------------------------
	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub11 = fig.add_subplot(1, 1, 1, projection='3d')
	# sub11.plot_surface(Xmesh, Ymesh, exactW, rstride=1, cstride=1, cmap=color.coolwarm)
	# sub2 = fig.add_subplot(3, 1, 2, projection='3d')
	# sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	sub11.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	# plt.show()
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
	sub2.plot_surface(Xmesh, Ymesh, P[0,0,:,:], rstride=1, cstride=1, cmap=color.coolwarm)
	# sub2 = fig.add_subplot(3, 1, 2, projection='3d')
	# sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	sub2.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	# plt.show()
	# --------------------------------END PLOT ----------------------------------------------------
	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub3 = fig.add_subplot(1, 1, 1, projection='3d')
	sub3.plot_surface(Xmesh, Ymesh, P[0, 1, :, :], rstride=1, cstride=1, cmap=color.coolwarm)
	# sub2 = fig.add_subplot(3, 1, 2, projection='3d')
	# sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	sub3.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	# plt.show()
	# --------------------------------END PLOT ----------------------------------------------------
	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub4 = fig.add_subplot(1, 1, 1, projection='3d')
	sub4.plot_surface(Xmesh, Ymesh, C[0, 0, :, :], rstride=1, cstride=1, cmap=color.coolwarm)
	# sub2 = fig.add_subplot(3, 1, 2, projection='3d')
	# sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	sub4.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	# plt.show()
	# --------------------------------END PLOT ----------------------------------------------------
	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub5 = fig.add_subplot(1, 1, 1, projection='3d')
	sub5.plot_surface(Xmesh, Ymesh, C[1, 1, :, :], rstride=1, cstride=1, cmap=color.coolwarm)
	# sub2 = fig.add_subplot(3, 1, 2, projection='3d')
	# sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	sub5.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	# plt.show()
	# --------------------------------END PLOT ----------------------------------------------------
	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub6 = fig.add_subplot(1, 1, 1, projection='3d')
	sub6.plot_surface(Xmesh, Ymesh, C[0, 1, :, :], rstride=1, cstride=1, cmap=color.coolwarm)
	# sub2 = fig.add_subplot(3, 1, 2, projection='3d')
	# sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	sub6.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	# plt.show()
	# --------------------------------END PLOT ----------------------------------------------------
	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub7 = fig.add_subplot(1, 1, 1, projection='3d')
	sub7.plot_surface(Xmesh, Ymesh, C[1, 0, :, :], rstride=1, cstride=1, cmap=color.coolwarm)
	# sub2 = fig.add_subplot(3, 1, 2, projection='3d')
	# sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	# sub3 = fig.add_subplot(3, 1, 3, projection='3d')
	# sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	sub7.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	plt.show()
