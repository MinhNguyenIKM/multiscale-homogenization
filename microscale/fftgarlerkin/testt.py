#!/usr/bin/env python2
# ---------------------------------------------------------------------------------
# Galerkin-FFT based solver for 2D periodic microscopic structure
# Large deformation, hyperelasticity problem
# Create date: 06/09/2018
# Author: minh.nguyen@ikm.uni-hannover.de
# ---------------------------------------------------------------------------------
import numpy as np
from numpy import power, ones, zeros
import scipy.sparse.linalg as sp
import itertools
import time
from util import micro2D_utility as m2Dutil
from util.mytensor import delta, ddot42_v1, dyad22, ddot42, dot22, trans2, dot24, ddot44, dot42, ddot44_v1, \
	ddot24_v1
import common as cm
from matplotlib import pyplot as plt
from matplotlib import cm as color
from mpl_toolkits.mplot3d import Axes3D

ax, bx = (-0.5, 0.5)
ay, by = (-0.5, 0.5)
# Nx, Ny = (2 ** 3 + 1, 2 ** 8 + 1)  # Laminate
Nx, Ny = (2 ** 2 + 1, 2 ** 2 + 1)  # Circular inclusion
dim = 2
Lx = bx - ax
Ly = by - ay
NDOF = (dim ** 2) * (Nx * Ny)  # number of degrees-of-freedom
vol = (bx - ax) * (by - ay)


#  -----------------------------------------------------------------------------
#                   determinant of grid of 2nd-order tensors
#  -----------------------------------------------------------------------------
def det2(A2):
	return A2[0, 0] * A2[1, 1] - A2[1, 0] * A2[0, 1]


#  -----------------------------------------------------------------------------
#                   inverse of grid of 2nd-order tensors
#  -----------------------------------------------------------------------------
def inv2(A2):
	A2det = det2(A2)
	A2inv = np.empty([2, 2, Nx, Ny])
	A2inv[0, 0] = A2[1, 1] / A2det
	A2inv[0, 1] = -A2[0, 1] / A2det
	A2inv[1, 0] = -A2[1, 0] / A2det
	A2inv[1, 1] = A2[0, 0] / A2det
	return A2inv


#  -----------------------------------------------------------------------------
#                           projection operator
#  -----------------------------------------------------------------------------
def get_Green_Operator(xi):
	Ghat4 = np.zeros([dim, dim, dim, dim, Nx, Ny])  # zero initialzation
	# - compute
	normXi = np.sqrt(xi[0] * xi[0] + xi[1] * xi[1])
	normXi[0][0] = 1.0  # Assign 1 to avoid the singularity
	for i, j, k, l in itertools.product(range(dim), repeat=4):
		Ghat4[i, j, k, l] = delta(i, k) * xi[j] * xi[l] / np.power(normXi, 2)
		Ghat4[i, j, k, l, 0, 0] = 0  # Like boundary conditions
	return Ghat4


def cal_average_stress_strain(F, hx, hy):
	vol = (bx - ax) * (by - ay)
	F_macro = zeros([dim, dim])
	for i, j in itertools.product(range(dim), repeat=2):
		F_macro[i, j] = 1.0 / vol * hx * hy * np.sum(F[i, j, :, :])
	return F_macro


#  -----------------------------------------------------------------------------
#               SAINT-VENANT model (Like HOOKS model in small strain)
#  -----------------------------------------------------------------------------
# identity tensor (single tensor)
identity = np.eye(2)
# identity tensors (grid)
I = np.einsum('ij,xy', identity, ones([Nx, Ny]))
I4 = np.einsum('ijkl,xy->ijklxy', np.einsum('il,jk', identity, identity), ones([Nx, Ny]))
I4rt = np.einsum('ijkl,xy->ijklxy', np.einsum('ik,jl', identity, identity), ones([Nx, Ny]))
I4s = (I4 + I4rt) / 2.
II = dyad22(I, I)
II4 = np.einsum('klmn,xy->klmnxy', np.einsum('km,ln', identity, identity), ones([Nx, Ny]))


# --------------------------------------------------------------------------
# This is retrieved from Geus and Zeman paper. However, I found that this is not the correct derivation.
# Please see my derivation and implement in file
# /home/minh/Documents/PHD/dev/homogenization/PyFEM/pyfem-1.0/pyfem/materials/SaintVenantPF.py
#

def constitutive_Saint_Venant(F, mu, kappa):
	C4 = (kappa * II) + 2.0 * mu * (I4s - 1.0 / 3.0 * II)
	S = ddot42(C4, 0.5 * (dot22(trans2(F), F) - I))
	P = dot22(F, S)
	K4 = dot24(S, I4) + ddot44(ddot44(I4rt, dot42(dot24(F, C4), trans2(F))), I4rt)
	return P, K4


#  -----------------------------------------------------------------------------
#                       NEO-HOOK model
#  -----------------------------------------------------------------------------
def constitutive_Neo_Hookean(F, mu, beta):
	# First derivate of W:Neo-Hookean free energy w.r.t F
	detF = det2(F)
	invF = inv2(F)
	P = np.zeros([dim, dim, Nx, Ny])
	for i, j in itertools.product(range(dim), repeat=2):
		P[i, j, :, :] = mu * F[i, j, :, :] - mu * power(detF, -beta) * invF[j, i, :, :]
	# Second derivate of W:Neo-Hookean free energy w.r.t F
	K4 = np.zeros([dim, dim, dim, dim, Nx, Ny])
	for i, j, k, l in itertools.product(range(dim), repeat=4):
		K4[i, j, k, l, :, :] = mu * delta(i, k) * delta(j, l) + mu * power(detF, -beta) \
							   * (beta * invF[j, i, :, :] * invF[l, k, :, :] + invF[l, i, :, :] * invF[j, k, :, :])
	return P, K4


#  -----------------------------------------------------------------------------
#                       NEO-HOOKEAN energy form
#   Create date: 13/09/2018
#  -----------------------------------------------------------------------------
def get_energy_Neo_Hookean(F, mu, beta):
	dim = F.shape[0]
	C = dot22(trans2(F), F)
	trC = np.zeros([F.shape[2], F.shape[3]])
	for i in range(dim):
		trC += C[i, i, :, :]
	detF = det2(F)
	energy = mu/2 * (trC - dim) + mu/beta * (np.power(detF, -beta) - 1)
	return energy


#  -----------------------------------------------------------------------------
#                       NEO-HOOKEAN model in Yvonnet paper
#  -----------------------------------------------------------------------------
def constitutive_Neo_Hookean2(F, mu, lam):
	# First derivate of W:Neo-Hookean free energy w.r.t F
	detF = det2(F)
	if np.any(detF < 0): # That means the calculation will return wrong values
		return -1, -1
		# pass
	invF = inv2(F)
	P = np.zeros([dim, dim, Nx, Ny])
	for i, j in itertools.product(range(dim), repeat=2):
		P[i, j, :, :] = (lam * np.log(detF) - mu) * invF[j, i, :, :] + mu * F[i, j, :, :]
	# Second derivate of W:Neo-Hookean free energy w.r.t F
	K4 = np.zeros([dim, dim, dim, dim, Nx, Ny])
	for i, j, k, l in itertools.product(range(dim), repeat=4):
		K4[i, j, k, l, :, :] = lam * invF[j, i, :, :] * invF[l, k, :, :] - (lam * np.log(detF) - mu) *\
							   (invF[j, k, :, :] * invF[l, i, :, :]) + mu * delta(i, k) * delta(j, l)
	return P, K4


def get_energy_Neo_Hookean2(F, mu, lam):
	dim = F.shape[0]
	C = dot22(trans2(F), F)
	trC = np.zeros([F.shape[2], F.shape[3]])
	for i in range(dim):
		trC += C[i, i, :, :]
	detF = det2(F)
	energy = 0.5 * lam * np.power(np.log(detF), 2) - mu * np.log(detF) + 0.5 * mu * (trC - 2)
	return energy

#  -----------------------------------------------------------------------------
#                               PLOTTING
#  -----------------------------------------------------------------------------
def plot_results(X, Y, F):
	# -------------------------------------------------------------------------------------------
	#   PLOT MESH and VALUS
	# -------------------------------------------------------------------------------------------
	# fig, ax = plt.subplot()
	fig = plt.figure(figsize=(5, 4))
	ax = fig.add_subplot(1, 1, 1)
	Z = F[0, 0]
	# Z = F
	# Z = np.copy(F) # for energy plot
	# Z = Z[:-1, :-1]
	p1 = ax.pcolor(X, Y, Z, cmap=color.coolwarm, vmin=Z.min(), vmax=Z.max())
	cb = fig.colorbar(p1)
	ax.set_xlabel('X')
	ax.set_ylabel('Y')
	# ax.set_xlim(-0.6, 0.6)
	# ax.set_ylim(-0.6, 0.6)
	# cb.set_label("$P_{11}$")
	cb.set_label("$\Psi(\mathbf{F})$")
	# plt.show()  # for energy
	# exit()  # for energy
	fig = plt.figure(figsize=(5, 4))
	ax = fig.add_subplot(1, 1, 1)
	Z = F[0, 1]
	# Z = Z[:-1, :-1]
	p1 = ax.pcolor(X, Y, Z, cmap=color.coolwarm, vmin=Z.min(), vmax=Z.max())
	cb = fig.colorbar(p1)
	ax.set_xlabel('X')
	ax.set_ylabel('Y')
	# ax.set_xlim(-0.6, 0.6)
	# ax.set_ylim(-0.6, 0.6)
	cb.set_label("$P_{12}$")

	fig = plt.figure(figsize=(5, 4))
	ax = fig.add_subplot(1, 1, 1)
	Z = F[1, 1]
	# Z = Z[:-1, :-1]
	p1 = ax.pcolor(X, Y, Z, cmap=color.coolwarm, vmin=Z.min(), vmax=Z.max())
	cb = fig.colorbar(p1)
	ax.set_xlabel('X')
	ax.set_ylabel('Y')
	# ax.set_xlim(-0.6, 0.6)
	# ax.set_ylim(-0.6, 0.6)
	cb.set_label("$P_{22}$")

	fig = plt.figure(figsize=(5, 4))
	ax = fig.add_subplot(1, 1, 1)
	Z = F[1, 0]
	# Z = Z[:-1, :-1]
	p1 = ax.pcolor(X, Y, Z, cmap=color.coolwarm, vmin=Z.min(), vmax=Z.max())
	cb = fig.colorbar(p1)
	ax.set_xlabel('X')
	ax.set_ylabel('Y')
	cb.set_label("$P_{21}$")
	# fig = plt.figure(figsize=plt.figaspect(0.8))

	fig = plt.figure(figsize=(5, 5))
	sub1 = fig.add_subplot(1, 1, 1, projection='3d')
	sub1.plot_surface(X, Y, F[0, 0], rstride=1, cstride=1, cmap=color.coolwarm)
	sub1.set_xlabel('X')
	sub1.set_xlim(-0.5, 0.5)
	sub1.set_ylabel('Y')
	sub1.set_ylim(-0.5, 0.5)
	sub1.set_zlabel('$F_{11}$')
	sub1.tick_params(labelsize=7)
	# sub1.set_axis_off()

	fig = plt.figure(figsize=(5, 5))
	sub2 = fig.add_subplot(1, 1, 1, projection='3d')
	sub2.plot_surface(X, Y, F[1, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	sub2.set_xlabel('X')
	sub2.set_xlim(-0.5, 0.5)
	sub2.set_ylabel('Y')
	sub2.set_ylim(-0.5, 0.5)
	sub2.set_zlabel('$F_{22}$')
	sub2.tick_params(labelsize=7)
	# sub2.set_axis_off()

	fig = plt.figure(figsize=(5, 5))
	sub3 = fig.add_subplot(1, 1, 1, projection='3d')
	sub3.plot_surface(X, Y, F[0, 1], rstride=1, cstride=1, cmap=color.coolwarm)
	sub3.set_xlabel('X')
	sub3.set_xlim(-0.5, 0.5)
	sub3.set_ylabel('Y')
	sub3.set_ylim(-0.5, 0.5)
	sub3.set_zlabel('$F_{12}$')
	sub3.tick_params(labelsize=7)
	# sub3.set_axis_off()
	# sub3.set_axis_off()
	# sub3.w_zaxis.line.set_lw(0.)
	# sub3.set_zticks([])
	# sub1.view_init(elev=90., azim=90)
	# sub2.view_init(elev=90., azim=90)
	# sub3.view_init(elev=90., azim=90)
	plt.show()


# print(F_t[:,:,0,0])
# print(F_t[:,:,64,64])
# from mayavi import mlab
# mlab.figure(1, bgcolor=(1, 1, 1), fgcolor=(0, 0, 0), size=(400, 300))
# mlab.clf()
# mlab.plot3d(X_grid, Y_grid, Z_grid, F_t[0,0,0,0,:], representation='surface', colormap='jet')
# mlab.colorbar(label_fmt='%.5f', title='F11', orientation='vertical')
# mlab.view(90, 70, 6.2, (-1.3, -2.9, 0.25))
# mlab.show()
# F = zeros([2,2,1,1])
# i = eye(2)
# I = zeros([2,2,1,1])
# I[:,:,0,0] = i
# Nx = 1
# Ny = 1
# number = 10
# P_plot = np.empty(number)
# F_plot = np.empty(number)
# ii = 0
# for i in np.arange(0.1, 1, number):
#     print(i)
#     F[0, 0] = I[0, 0] + i
#     F[0, 1] = I[0, 1] + i
#     F[1, 0] = I[1, 0] + i
#     F[1, 1] = I[1, 1] + i
#     P, K4 = constitutive_Neo_Hookean(F)
#     F_plot[ii] = F[1, 1]
#     P_plot[ii] = P[1, 1]
#     ii += 1
# plt.plot(F_plot, P_plot)
# plt.show()


#  -----------------------------------------------------------------------------
#               Our Wrapper for Fast Fourier Transform
#  -----------------------------------------------------------------------------
def myFFT(x): return np.fft.fftn(x, [Nx, Ny])


#  -----------------------------------------------------------------------------
#               Our Wrapper for inverse Fast Fourier Transform
#  -----------------------------------------------------------------------------
def myIFFT(x): return np.fft.ifftn(x, [Nx, Ny])


#  -----------------------------------------------------------------------------
#        Solver for non-linear 2D problems based on Galerkin-FFT method
#  -----------------------------------------------------------------------------
def solve_nonlinear_GalerkinFFT(F_macro=None, kind='neo-hookean', mode='stiffness', domain='laminate'):
	xi, hx, hy, X, Y, X_center, Y_center, _, _, _, _, _, _ = m2Dutil.setup_mesh(ax, bx, ay, by, Nx, Ny, dim)
	# xi, hx, hy, X, Y, X_center, Y_center, _, _, _, _, _, _ = m2Dutil.setup_mesh_with_modifiedWavenumber_to_reduce_Gibbs(ax, bx, ay, by, Nx, Ny, dim)
	Ghat4 = get_Green_Operator(xi)
	# G = lambda A2: np.real(myIFFT(ddot42_v2(Ghat4, myFFT(A2)))).reshape(-1)
	G = lambda A2: np.real(myIFFT(ddot24_v1(myFFT(A2), Ghat4))).reshape(-1)
	K_dF = lambda dFm: ddot42_v1(K4, dFm.reshape(dim, dim, Nx, Ny))
	G_K_dF = lambda dFm: G(K_dF(dFm))
	if domain == 'laminate':
		phase = cm.setup_Laminate(Nx, Ny, X, Y, ax, bx, Lx, Ly)
	elif domain == 'inclusion':
		phase = cm.setup_circular_inclusion(Nx, Ny, ax, bx, X_center, Y_center, X, Y)
	param = lambda p0, p1: p0 * np.ones([Nx, Ny]) * (1 - phase) + p1 * np.ones([Nx, Ny]) * phase
	if F_macro is None:
		# F_macro = np.array([
		# 	[1.10, 1.20],
		# 	[0.10, 1.20]
		# ])
		# F_macro = np.array([[0.863856888935, -0.241168451622],[-0.253055864905,0.717614627910]])
		# F_macro = np.array([[0.813602454143, 0.206370647816], [-0.272914132255, 0.712287076109]])
		# F_macro = np.array([[0.701503008731, -0.125844109995], [-0.289006896125, 0.915362385357]])

		# F_macro = np.array([
		# 	[0.911658365001, 0.278656852689],
		# 	[0.382623449699, 0.906153259761]
		# ])

		F_macro = np.array([
			[1.100000000000, +0.4],
			[-0.4, 1.100000000000]
		])

	 # F_macro = np.array([
		# 	[1.2, -0.2],
		# 	[0.2, 1.2]
		# ])

		# F_macro = np.array([
		# 	[1.0, 0.4],
		# 	[-0.3, 1.0]
		# ])

		# F_macro = np.array([
		# 	[1.067180406282, 0.0],
		# 	[0.0, 0.842115285381]
		# ])
	F_n = np.zeros([dim, dim, Nx, Ny])
	dF = np.zeros([dim, dim, Nx, Ny])
	for i, j in itertools.product(range(dim), repeat=2):
		F_n[i, j, :, :] = F_macro[i, j] + dF[i, j, :, :]
	iteration = 0
	maxIteration = 15
	if kind == 'neo-hookean':
		# mu = param(2, 1)
		# beta = param(10, 10)
		mu = param(1000, 100)
		beta = param(1, 1)
		P, K4 = constitutive_Neo_Hookean(F_n, mu, beta)
	elif kind == 'neo-hookean2':
		mu = param(35.7143, 384.615)
		lam = param(142.857, 576.923)
		P, K4 = constitutive_Neo_Hookean2(F_n, mu, lam)
		if type(P) == int and type(K4) == int:
			return -888888
	elif kind == 'saint-venant':
		pass
	while iteration < maxIteration:
		b = -G(P)
		t1 = time.time()
		dFm, _ = sp.cg(A=sp.LinearOperator(shape=(F_n.size, F_n.size), matvec=G_K_dF, dtype='float'), b=b, tol=1e-8,
						maxiter=50)
		t2 = time.time()
		if t2 - t1 > 60:
			# The cell is penetrable - khong hoi tu duoc
			return -999999
			# pass
		F_n = F_n + dFm.reshape(dim, dim, Nx, Ny)
		if kind == 'neo-hookean':
			P, K4 = constitutive_Neo_Hookean(F_n, mu, beta)
		if kind == 'neo-hookean2':
			P, K4 = constitutive_Neo_Hookean2(F_n, mu, lam)
			if type(P) == int and type(K4) == int: # The cell is penetrable - khong hoi tu duoc - determinat of F has some negative value
				print('-888888')
				return -888888
		elif kind == 'saint-venant':
			pass
		stop = np.linalg.norm(dFm) / np.linalg.norm(F_n)
		print('%10.2e' % stop)  # print residual to the screen
		if stop < 1.e-5 and iteration > 0:
			break  # check convergence
		iteration += 1
	# print(F_n[:, :, 0, 0])
	if iteration >= maxIteration:
		print("The programme is not convergent !!!")
		return -777777
	if mode == 'energy':
		psi = np.zeros([1, Nx, Ny])
		if kind == 'neo-hookean':
			psi = get_energy_Neo_Hookean(F_n, mu, beta)
		elif kind == 'neo-hookean2':
			psi = get_energy_Neo_Hookean2(F_n, mu, lam)
		average_energy = cm.homogenization(psi, hx, hy, ax, ay, bx, by, dim, obj='energy')
		return average_energy
	if mode == 'stiffness':
		C_homogenized = compute_effective_moduli(F_n, K4, G, G_K_dF, hx, hy, vol)
		C_homogenized2D = m2Dutil.transform_4thTensor_to_2ndTensor_inlargestrain(C_homogenized)
		F_homogenized = cm.homogenization(F_n, hx, hy, ax, ay, bx, by, dim, obj='F')
		P_homogenized = cm.homogenization(P, hx, hy, ax, ay, bx, by, dim, obj='P')
		print(C_homogenized2D)
		print(P_homogenized)
		plot_results(X, Y, P)
		return F_homogenized, P_homogenized, C_homogenized2D
	if mode == 'everything':
		psi = np.zeros([1, Nx, Ny])
		if kind == 'neo-hookean':
			psi = get_energy_Neo_Hookean(F_n, mu, beta)
		elif kind == 'neo-hookean2':
			psi = get_energy_Neo_Hookean2(F_n, mu, lam)
		average_energy = cm.homogenization(psi, hx, hy, ax, ay, bx, by, dim, obj='energy')
		C_homogenized = compute_effective_moduli(F_n, K4, G, G_K_dF, hx, hy, vol)
		C_homogenized2D = m2Dutil.transform_4thTensor_to_2ndTensor_inlargestrain(C_homogenized)
		F_homogenized = cm.homogenization(F_n, hx, hy, ax, ay, bx, by, dim, obj='F')
		P_homogenized = cm.homogenization(P, hx, hy, ax, ay, bx, by, dim, obj='P')
		# plot_results(X, Y, psi)
		print(average_energy)
		return average_energy, P_homogenized, C_homogenized2D
	return F_n


#  -----------------------------------------------------------------------------
#        Compute the effective moduli
#  -----------------------------------------------------------------------------
def compute_effective_moduli(F_n, K4, G, G_K_dF, hx, hy, vol):
	ALPHA4 = np.zeros([dim, dim, dim, dim, Nx, Ny])
	for alpha in range(dim):
		for beta in range(dim):
			deltaFbar_alpha_beta = 1
			b = -G(K4[:, :, alpha, beta] * deltaFbar_alpha_beta)
			dFm, _ = sp.cg(A=sp.LinearOperator(shape=(F_n.size, F_n.size), matvec=G_K_dF, dtype='float'), b=b,
							tol=1e-10, maxiter=50)
			ALPHA4[:, :, alpha, beta, :, :] = dFm.reshape(dim, dim, Nx, Ny)
	# print(ALPHA4)
	F_ALPHA4 = ddot44_v1(K4, (II4 + ALPHA4))
	C_consistent_tangent = zeros((dim, dim, dim, dim))
	for i, j, k, l in itertools.product(range(dim), repeat=4):
		C_consistent_tangent[i, j, k, l] = 1.0 / vol * hx * hy * np.sum(F_ALPHA4[i, j, k, l, :, :])
	return C_consistent_tangent


#  -----------------------------------------------------------------------------
#        MAIN PROGRAMME
#  -----------------------------------------------------------------------------
if __name__ == '__main__':
	""" Result for K4_bar the below example 257 x 257
	[[3.22013952  	-0.10098116 	-1.88507459  	1.58007559]
	 [-0.10098116  	1.51990422  	0.30499899 		-0.06128361]
	 [-1.88507459  	0.30499899		3.22013952 		-1.78409343]
	 [1.58007559 	-0.06128361 	-1.78409343  	3.20301649]]
	"""
	F_macro = np.array([
			[0.989140658968, 0.153480418209],
			[-0.156514066285, 0.986779632680]
		])
	# F = solve_nonlinear_GalerkinFFT(F_macro, kind='neo-hookean', mode='stiffness', domain='laminate')
	F = solve_nonlinear_GalerkinFFT(F_macro, domain='inclusion', kind='neo-hookean2', mode='stiffness')
	# F = solve_nonlinear_GalerkinFFT(kind='neo-hookean', domain='inclusion')
	# F = solve_nonlinear_GalerkinFFT(kind='neo-hookean2', domain='inclusion')
