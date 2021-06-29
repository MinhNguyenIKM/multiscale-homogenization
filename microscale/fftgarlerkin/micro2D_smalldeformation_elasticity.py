#!/usr/bin/env python2
# ---------------------------------------------------------------------------------
# Galerkin-FFT based solver for 2D periodic microscopic structure
# Small deformation, linear elasticity
# Create date: 11/07/2018
# Modified date: 11/09/2018
# Author: minh.nguyen@ikm.uni-hannover.de
# ---------------------------------------------------------------------------------
from util import micro2D_utility as m2Dutil
from util.mytensor import delta, ddot42_v1, dyad22, ddot24_v1, ddot44_v1
import time
import numpy as np
from numpy import ones, zeros
import scipy.sparse.linalg as sp
import itertools
from matplotlib import pyplot as plt
from matplotlib import cm as color
import common as cm
from mpl_toolkits.mplot3d import Axes3D


ax, bx = (-np.pi, np.pi)
ay, by = (-np.pi, np.pi)
Nx, Ny = (2 ** 3 + 1, 2 ** 8 + 1)
dim = 2
Lx = bx - ax
Ly = by - ay
NDOF = (dim ** 2) * (Nx * Ny)  # number of degrees-of-freedom
vol = (bx - ax) * (by - ay)


#  -----------------------------------------------------------------------------
#                           projection operator
#  -----------------------------------------------------------------------------
def get_Green_Operator(xi):
	Ghat4 = zeros([dim, dim, dim, dim, Nx, Ny])  # zero initialize
	normXi = np.sqrt(xi[0] * xi[0] + xi[1] * xi[1])
	normXi[0][0] = 1.0  # Assign 1 to avoid the singularity
	for i, j, l, m in itertools.product(range(dim), repeat=4):
		# centerPoint = where(freq - 0.0 < 1e-10)
		Ghat4[i, j, l, m, :, :] = -(xi[i] * xi[j] * xi[l] * xi[m]) / np.power(normXi, 4) + \
								  (delta(j, l) * xi[i] * xi[m] + delta(j, m) * xi[i] * xi[l] + \
								   delta(i, l) * xi[j] * xi[m] + delta(i, m) * xi[j] * xi[l]) / (2. * np.power(normXi, 2))
		Ghat4[i, j, l, m, 0, 0] = 0  # Like boundary condition
	return Ghat4


#  -----------------------------------------------------------------------------
#               Our Wrapper for Fast Fourier Transform
#  -----------------------------------------------------------------------------
def myFFT(x): return np.fft.fftn(x, [Nx, Ny])


#  -----------------------------------------------------------------------------
#               Our Wrapper for inverse Fast Fourier Transform
#  -----------------------------------------------------------------------------
def myIFFT(x): return np.fft.ifftn(x, [Nx, Ny])


# identity tensor (single tensor)
identity = np.eye(2)
# identity tensors (grid)
I = np.einsum('ij,xy', identity, ones([Nx, Ny]))
I4 = np.einsum('ijkl,xy->ijklxy', np.einsum('il,jk', identity, identity), ones([Nx, Ny]))
I4rt = np.einsum('ijkl,xy->ijklxy', np.einsum('ik,jl', identity, identity), ones([Nx, Ny]))
I4s = (I4 + I4rt) / 2.
II = dyad22(I, I)
II4 = np.einsum('klmn,xy->klmnxy', np.einsum('km,ln', identity, identity), ones([Nx, Ny]))


#  -----------------------------------------------------------------------------
#               CONSTITUTIVE LAW
#  -----------------------------------------------------------------------------
def constitutive_Hook_Law(K_phase, mu_phase):
	# K4 = K_phase * II + 2. * mu_phase * (I4s - 1. / 3. * II)
	K4 = K_phase * II + mu_phase * (I4 + I4rt)
	return K4


#  -----------------------------------------------------------------------------
#                       SETUP: Matrix and Inclusion structure
#  -----------------------------------------------------------------------------
def setup_circular_inclusion(X, Y, X_grid, Y_grid, centerPointX, centerPointY):
	phase = np.zeros([Nx, Ny])
	R = (bx - ax) / 6.0
	for idx, x in enumerate(X_grid):
		idy = np.sqrt(
			np.power(x - X[centerPointX, centerPointY], 2) + np.power(Y_grid - Y[centerPointX, centerPointY], 2)) < R
		phase[idx, idy] = 1
	return phase


#  -----------------------------------------------------------------------------
#        Solver for non-linear 2D problems based on Galerkin-FFT method
#  -----------------------------------------------------------------------------
def solve_smalldeformation_GalerkinFFT(mode='stiffness', domain='laminate'):
	t = time.time()
	xi, hx, hy, X, Y, X_center, Y_center, _, _, _, _, _, _ = m2Dutil.setup_mesh(ax, bx, ay, by, Nx, Ny, dim)
	Ghat4 = get_Green_Operator(xi)
	G = lambda A2: np.real(myIFFT(ddot24_v1(myFFT(A2), Ghat4))).reshape(-1)
	K_deps = lambda depsm: ddot42_v1(K4, depsm.reshape(dim, dim, Nx, Ny))
	G_K_deps = lambda depsm: G(K_deps(depsm))
	if domain == 'laminate':
		phase = cm.setup_Laminate(Nx, Ny, X, Y, ax, bx, Lx, Ly)
	elif domain == 'inclusion':
		phase = cm.setup_circular_inclusion(Nx, Ny, ax, bx, X_center, Y_center, X, Y)
	param = lambda p0, p1: p0 * np.ones([Nx, Ny]) * (phase) + p1 * np.ones([Nx, Ny]) * (1-phase)
	K_phase = param(1, 2)
	mu_phase = param(1, 2)
	eps_macro = np.array([
		[1.0/100, 0.00],
		[0.00, 2.0/100]
	])
	eps = np.zeros([dim, dim, Nx, Ny])
	deps = np.zeros([dim, dim, Nx, Ny])
	for i, j in itertools.product(range(dim), repeat=2):
		eps[i, j, :, :] = eps_macro[i, j] + deps[i, j, :, :]
	iteration = 0
	K4 = constitutive_Hook_Law(K_phase, mu_phase)
	while True:
		sig = ddot42_v1(K4, eps)
		b = -G(sig)
		depsm, _ = sp.cgs(A=sp.LinearOperator(shape=(NDOF, NDOF), matvec=G_K_deps, dtype='float'), b=b, tol=1e-8,
						maxiter=50)
		eps = eps + depsm.reshape(dim, dim, Nx, Ny)
		stop = np.linalg.norm(depsm) / np.linalg.norm(eps)
		print('Step ' + str(iteration) + '-Convergence of newton-raphson : %10.2e' % stop)  # print residual to the screen
		if stop < 1.e-6 and iteration > 0:
			break  # check convergence
		iteration += 1
	print(eps[:, :, 0, 0])

	if mode == 'stiffness':
		sig = ddot42_v1(K4, eps)
		C_homogenized = compute_effective_moduli(eps, K4, G, G_K_deps, hx, hy, vol)
		C_homogenized2D = m2Dutil.transform_4thTensor_to_2ndTensor(C_homogenized)
		print(C_homogenized2D)

	# -------------------------------------------------------------------------------------------
	#                   HOMOGENIZED STRESS and STRAIN
	# -------------------------------------------------------------------------------------------
	print("Completed newton-raphson method in : " + str(time.time() - t))
	# vol = (bx - ax) * (by - ay)
	S_macro = np.zeros([dim, dim])
	E_macro = np.zeros([dim, dim])
	for i, j in itertools.product(range(dim), repeat=2):
		S_macro[i, j] = 1.0 / vol * hx * hy * np.sum(sig[i, j, :, :])
		E_macro[i, j] = 1.0 / vol * hx * hy * np.sum(eps[i, j, :, :])
	# print(S_macro)
	# print(E_macro)
	# -------------------------------------------------------------------------------------------
	#   PLOT MESH and VALUES
	# -------------------------------------------------------------------------------------------
	fig = plt.figure(figsize=plt.figaspect(0.5))
	sub = fig.add_subplot(3, 1, 1, projection='3d')
	sub.plot_surface(X, Y, eps[0, 0], rstride=1, cstride=1, cmap=color.coolwarm)
	sub = fig.add_subplot(3, 1, 2, projection='3d')
	sub.plot_surface(X, Y, eps[1, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	sub = fig.add_subplot(3, 1, 3, projection='3d')
	sub.plot_surface(X, Y, eps[0, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	plt.show()


#  -----------------------------------------------------------------------------
#        Compute the effective moduli
#  -----------------------------------------------------------------------------
def compute_effective_moduli(eps, K4, G, G_K_deps, hx, hy, vol):
	ALPHA4 = np.zeros([dim, dim, dim, dim, Nx, Ny])
	for alpha in range(dim):
		for beta in range(dim):
			delta_epsbar_alpha_beta = 1
			b = -G(K4[:, :, alpha, beta] * delta_epsbar_alpha_beta)
			depsm, _ = sp.cgs(A=sp.LinearOperator(shape=(eps.size, eps.size), matvec=G_K_deps, dtype='float'), b=b,
							tol=1e-8, maxiter=50)
			ALPHA4[:, :, alpha, beta, :, :] = depsm.reshape(dim, dim, Nx, Ny)
	F_ALPHA4 = ddot44_v1(K4, (II4 + ALPHA4))
	C_consistent_tangent = zeros((dim, dim, dim, dim))
	for i, j, k, l in itertools.product(range(dim), repeat=4):
		C_consistent_tangent[i, j, k, l] = 1.0 / vol * hx * hy * np.sum(F_ALPHA4[i, j, k, l, :, :])
	return C_consistent_tangent


#  -----------------------------------------------------------------------------
#        MAIN PROGRAMME
#  -----------------------------------------------------------------------------
if __name__ == '__main__':
	""" Result K4 for the example below
		[[4.00519481 	1.33506494 		0.]
	 	 [1.33506494 	4.45020971 		0.]
		 [0.			0.				1.33506494]]
	Completed newton-raphson method in: 0.132436990738"""
	epsilon = solve_smalldeformation_GalerkinFFT()
