#!/usr/bin/env python2
from util import FileProcessing as fp
from numpy import dot, exp, ones
import numpy as np

dim = 1
size = dim * dim

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
	return hessian * (1.0 / dgdf) * np.dot(dxidx.reshape(size, 1), dxidx.reshape(1, size))

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
		# filename = 'Mechanics1D_Nonlinear_1_NNs.dat'
		filename = 'Mechanics1D_Nonlinear_1d_1com_5N_100M_1_NNs.dat'
	elif type == '2DLaminate':
		filename = 'Laminate2_4_NNs.dat'
	elif type == 'SaintVenant':
		filename = '/home/minh/Documents/PHD/dev/homogenization/machinelearning/training_results/SaintVenant_4d_10com_10N_30000M_4_NNs.dat'
	elif type == 'NeoHookean':
		filename = '/home/minh/Documents/PHD/dev/homogenization/machinelearning/training_results/NeoHookean_4d_10com_10N_30000M_4_NNs.dat'
	elif type =='Inclusion-NeoHookean2':
		filename = '/home/minh/Documents/PHD/dev/homogenization/machinelearning/training_results/Inclusion_50x50_NeoHookean2/Inclusion_NeoHookean2_4d_15com_20N_80epoch_30000M_4_NNs.dat'
	dimD, dimd, L, N, activation_func_type, min_input, max_input, min_max_output, \
	A, w, c, b, d, d0 = fp.get_NN_parameters(filename)
	F_macro = tramnnmx(F_macro.reshape(-1), min_input, max_input)
	sigma_macro = np.zeros(size)
	P = np.zeros(size)
	C_effective = np.zeros([size, size])
	energy = 0
	for i in range(0, L):
		y = dot(A[:, :, i], F_macro) + b[:, :, i].reshape(-1)
		for n in range(0, N):
			z = dot(w[n, :, i], y) + d[n, :, i]
			zm = dot(w[n, :, i], y)
			energy += c[n, :, i] * tansig(z)
			sigma_macro += c[n, :, i] * dot(w[n, :, i], A[:, :, i]) * derivative_activation(z)
			C_effective += c[n, :, i] * dot(dot(w[n, :, i], A[:, :, i]).reshape(size, 1), dot(w[n, :, i], A[:, :, i]).reshape(1, size)) \
						   * 4 * ((-2 * exp(-2*z) / (1 + exp(-2*z)) ** 2) + (4 * exp(-4*z) / (1 + exp(-2*z)) ** 3))
		energy += d0[:, :, i].reshape(-1)
	# return the real scale data
	energy_aver = postmnmx(energy, min_max_output[0], min_max_output[1])
	P = return_to_rescale_for_stress(sigma_macro, min_input, max_input, min_max_output[0], min_max_output[1])
	P = P.reshape(dim, dim)
	# print(P)
	C_effective_unscaled = unnormalize_for_hessian(C_effective, min_input, max_input, min_max_output[0], min_max_output[1])
	return P, C_effective_unscaled, energy_aver


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
if __name__ == '__main__':
	F_macro = np.array([
		[1.067180406282, 0.056881170223],
		[-0.017531358124, 0.842115285381]
	])
	# F_macro = np.array([-0.67180406282, 0.056881170223])
	# F_macro = np.array([[1.067180406282, 0],
	# 				[0, 0.842115285381]])
	type = 'SaintVenant'
	cal_material_parameter2D(F_macro, type)
