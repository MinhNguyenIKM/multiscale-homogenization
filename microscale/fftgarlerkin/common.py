#  -----------------------------------------------------------------------------
#       Common methods for large deformation and small deformation
#       Create date: 13/09/2018
#       Author: minh.nguyen@ikm.uni-hannover.de
#  -----------------------------------------------------------------------------
import itertools
import numpy as np


#  -----------------------------------------------------------------------------
#                           homogenize solutions
#  -----------------------------------------------------------------------------
def homogenization(Axy, hx, hy, ax, ay, bx, by, dim, obj='energy'):
	volume = (bx - ax) * (by - ay)
	if obj == 'energy':
		Psi = 1.0 / volume * hx * hy * np.sum(Axy[:, :])
		return Psi
	if obj == 'F' or obj == 'P':
		A2_macro = np.zeros([dim, dim])
		for i, j in itertools.product(range(dim), repeat=2):
			A2_macro[i, j] = 1.0 / volume * hx * hy * np.sum(Axy[i, j, :, :])
		return A2_macro
	if obj == 'C':
		C_consistent_tangent = np.zeros((dim, dim, dim, dim))
		for i, j, k, l in itertools.product(range(dim), repeat=4):
			C_consistent_tangent[i, j, k, l] = 1.0 / volume * hx * hy * np.sum(Axy[i, j, k, l, :, :])
		return C_consistent_tangent


#  -----------------------------------------------------------------------------
#                       SETUP: Matrix and Inclusion structure
#  -----------------------------------------------------------------------------
def setup_circular_inclusion(Nx, Ny, ax, bx, Xl, Yl, X_grid, Y_grid):
	centerPointX = (Nx - 1) / 2
	centerPointY = (Ny - 1) / 2
	phase = np.zeros([Nx, Ny])
	# R = (bx - ax) / 4.0
	volumeFraction = 0.2
	R = np.sqrt(volumeFraction*((bx-ax)**2)/np.pi)
	# R = 0.252313  # so that area fraction f = 0.2
	for idx, x in enumerate(Xl):
		idy = np.sqrt(
			np.power(x - X_grid[centerPointX, centerPointY], 2) + np.power(Yl - Y_grid[centerPointX, centerPointY], 2)) < R
		phase[idx, idy] = 1
	return phase


#  -----------------------------------------------------------------------------
#                       SETUP: Laminate structure
#  -----------------------------------------------------------------------------
def setup_Laminate(Nx, Ny, X, Y, ax, bx, L1, L2):
	phase = np.zeros([Nx, Ny])
	phase[:, X[0, :] < ax + L1 / 4.0] = 1
	phase[:, X[0, :] > bx - L1 / 4.0] = 1
	return phase