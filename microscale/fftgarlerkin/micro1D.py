#!/usr/bin/env python2
# ---------------------------------------------------------------------
# Author: minh.nguyen@ikm.uni-hannover.de
# Create date: 05/12/2018
# Galerkin FFT for microscopic RVE in 1D problem
# ---------------------------------------------------------------------
import numpy as np
import scipy.fftpack as fft
import scipy.sparse.linalg as sp
from numpy import pi, ones, sqrt, square
from matplotlib import pyplot as plt


def cal_effective_stiffness_1d_nonlinear(strain_avg):
	strain_avg = strain_avg[0][0]
	# strain_avg = 0.025
	energy_macro, stress_macro, effective_moduli = solve_micro_1d_nonlinear_fft(strain_avg)
	return energy_macro, stress_macro, effective_moduli


# The 1D nonlinear constitutive law
def constitutive_law(strain, omega, x):
	stress = H(omega, x) * (np.sqrt(1 + strain) - 1)
	moduli = 0.5 * H(omega, x) * (1.0 / np.power(1 + strain, 0.5))
	return stress, moduli


# The distribution of heterogeneity
def H(omega, x):
	return 3.0 / 2.0 + np.sin(2.0 * np.pi * omega * x)


# The potential energy
def get_energy(strain, omega, x):
	return H(omega, x) * (2.0 / 3.0 * np.power(1 + strain, 3.0 / 2.0) - strain - 2.0/3.0)


# ----------------------------------------------------------------------------------------------------
# Solving equilibrium equation (BVP) in micro scale problem by Galerkin FFT method in 1D
# ----------------------------------------------------------------------------------------------------
def solve_micro_1d_nonlinear_fft(strain_macro):
	# --------- setup grid -----------------
	omega = 10
	lamda = 1.0 / omega
	a = -lamda/2.0
	b =  lamda/2.0
	# Scale
	scale = (b - a) / (2 * np.pi)
	L = b - a
	vol = L
	N = 2 ** 2 + 1  # Odd number of grid points
	h = L / N
	k = np.fft.ifftshift(np.arange(-(N - 1) / 2., (N - 1) / 2. + 1)) * scale
	x = np.arange(a + h, b + h, h)  # in Matlab --> a+h:h:b
	DOF = len(x)
	# --------- end of the setup grid -----------------
	# --------- calculate projection in fourier space -----------------
	Ghat = np.zeros(N)
	Ghat[1:] = k[1:] / k[1:]
	Ghat[0] = 0
	# --------- end of the calculate projection in fourier space -----------------
	# --------- Newton raphson to solve Galerkin FFT & CG method -----------------
	strain = np.zeros(N)
	dstrain_initial = np.zeros(N)
	iterNR = 0
	maxiterNR = 100
	strain = strain_macro + dstrain_initial
	stress, hessian = constitutive_law(strain, omega, x)
	G_P = lambda sigma : np.real(fft.ifft(Ghat * fft.fft(sigma)))
	G_K_dF = lambda dstrain: np.real(fft.ifft(Ghat * fft.fft(hessian * dstrain)))
	while iterNR < maxiterNR:
		b = -G_P(stress)
		dstrain, _ = sp.cg(A=sp.LinearOperator(shape=(DOF, DOF), matvec=G_K_dF, dtype='float'), b=b, tol=1e-10, maxiter=50)
		strain = strain + dstrain
		stress, hessian = constitutive_law(strain, omega, x)
		stop = np.linalg.norm(dstrain)
		print('%10.2e' % stop)  # print residual to the screen
		if stop < 1.e-8 and iterNR > 0:
			break  # check convergence
		iterNR += 1
	if iterNR >= maxiterNR:
		print("The programme is not convergent !!!")
		return -777777
	# --------- End of the Newton raphson to solve Galerkin FFT & CG method -----------------
	energy = get_energy(strain, omega, x)
	# --------- Compute the sensitivity term -----------------
	dstrain_fluc = np.zeros(N)
	dstrain_mac = 1
	b = -G_P(hessian * dstrain_mac)
	dstrain, _ = sp.cg(A=sp.LinearOperator(shape=(DOF, DOF), matvec=G_K_dF, dtype='float'), b=b, tol=1e-10, maxiter=50)
	dstrain_fluc = np.copy(dstrain)
	sensitivity = dstrain_fluc / dstrain_mac
	# --------- End of the Compute the sensitivity term -----------------
	# --------- Compute the effective properties -----------------
	effective_moduli = 1.0 / vol * h * np.sum(hessian * (1 + sensitivity))
	energy_macro = 1.0 / vol * h * np.sum(energy)
	stress_macro = 1.0 / vol * h * np.sum(stress)
	# --------- End of the Compute the effective properties -----------------
	return energy_macro, stress_macro, effective_moduli


if __name__ == '__main__':
	strain_macro = [[0.011756856483]]
	print(cal_effective_stiffness_1d_nonlinear(strain_macro))
