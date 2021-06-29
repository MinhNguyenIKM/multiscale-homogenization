# ---------------------------------------------------------------------------------
# The Utilities package for 2D microscopic structure
# Create date: 07/09/2018
# Author: minh.nguyen@ikm.uni-hannover.de
# ---------------------------------------------------------------------------------
import numpy as np
import util.Utility as ut

#  -----------------------------------------------------------------------------
#                   SET UP Periodic Mesh
#  -----------------------------------------------------------------------------
def setup_mesh(ax, bx, ay, by, Nx, Ny, dim):
	# ax, bx = (-0.5, 0.5)
	# ay, by = (-0.5, 0.5)
	# Nx, Ny = (2 ** 3 + 1, 2 ** 3 + 1)
	Lx = bx - ax
	Ly = by - ay
	scaleX = (2 * np.pi) / Lx
	scaleY = (2 * np.pi) / Ly
	freqX = scaleX * np.fft.ifftshift(np.arange(-(Nx - 1) / 2., (Nx - 1) / 2. + 1))  # coordinate axis -> freq. axis # Even node number
	freqY = scaleY * np.fft.ifftshift(np.arange(-(Ny - 1) / 2., (Ny - 1) / 2. + 1))  # coordinate axis -> freq. axis # Even node number
	# centerPointX = np.where(abs(freqX - 0.0) < 1e-10)[0][0]
	# centerPointY = np.where(abs(freqY - 0.0) < 1e-10)[0][0]
	# centerPointX = 0
	# centerPointY = 0
	hx = (bx - ax) / Nx
	hy = (by - ay) / Ny
	X_center = np.arange(ax + hx / 2.0, bx - hx / 2.0 + hx, hx)  # ax+hx/2 : bx-hx/2
	Y_center = np.arange(ay + hy / 2.0, by - hy / 2.0 + hy, hy)  # ay+hy/2 : by-hy/2
	Xc, Yc = np.meshgrid(Y_center, X_center)  # Be attention to the order of Y and X
	xi = np.zeros([2, Nx, Ny])
	xi1, xi2 = np.meshgrid(freqY, freqX)  # Be attention to the order of Y and X
	xi[0] = xi1
	xi[1] = xi2
	return xi, hx, hy, Xc, Yc, X_center, Y_center, ax, ay, bx, by, Lx, Ly


#  -----------------------------------------------------------------------------
#                   SET UP Periodic Mesh
#  -----------------------------------------------------------------------------
def setup_mesh_with_modifiedWavenumber_to_reduce_Gibbs(ax, bx, ay, by, Nx, Ny, dim):
	# ax, bx = (-0.5, 0.5)
	# ay, by = (-0.5, 0.5)
	# Nx, Ny = (2 ** 3 + 1, 2 ** 3 + 1)
	deltaX = 0.01
	deltaY = 0.01
	Lx = bx - ax
	Ly = by - ay
	scaleX = (2 * np.pi) / Lx
	scaleY = (2 * np.pi) / Ly
	freqX = scaleX * np.fft.ifftshift(np.arange(-(Nx - 1) / 2., (Nx - 1) / 2. + 1))  # coordinate axis -> freq. axis # Even node number
	freqY = scaleY * np.fft.ifftshift(np.arange(-(Ny - 1) / 2., (Ny - 1) / 2. + 1))  # coordinate axis -> freq. axis # Even node number
	# freqX = scaleX * np.fft.ifftshift(np.sin(np.arange(-(Nx - 1) / 2., (Nx - 1) / 2. + 1) * deltaX) / deltaX)
	# freqY = scaleY * np.fft.ifftshift(np.sin(np.arange(-(Nx - 1) / 2., (Nx - 1) / 2. + 1) * deltaY) / deltaY)
	# centerPointX = np.where(abs(freqX - 0.0) < 1e-10)[0][0]
	# centerPointY = np.where(abs(freqY - 0.0) < 1e-10)[0][0]
	# centerPointX = 0
	# centerPointY = 0
	hx = (bx - ax) / Nx
	hy = (by - ay) / Ny
	X_center = np.arange(ax + hx / 2.0, bx - hx / 2.0 + hx, hx)  # ax+hx/2 : bx-hx/2
	Y_center = np.arange(ay + hy / 2.0, by - hy / 2.0 + hy, hy)  # ay+hy/2 : by-hy/2
	Xc, Yc = np.meshgrid(Y_center, X_center)  # Be attention to the order of Y and X
	xi = np.zeros([2, Nx, Ny])
	xi1, xi2 = np.meshgrid(freqY, freqX)  # Be attention to the order of Y and X
	# first-order reduce Gibbs
	xi1 = np.sin(xi1 * deltaX) / deltaX
	xi2 = np.sin(xi2 * deltaY) / deltaY
	# second-order reduce Gibbs
	# xi1 = (4.0 / 3.0 * np.sin(xi1 * deltaX) - 1.0 / 6.0 * np.sin(2 * xi1 * deltaX)) / deltaX
	# xi2 = (4.0 / 3.0 * np.sin(xi2 * deltaY) - 1.0 / 6.0 * np.sin(2 * xi2 * deltaY)) / deltaY
	xi[0] = xi1
	xi[1] = xi2
	return xi, hx, hy, Xc, Yc, X_center, Y_center, ax, ay, bx, by, Lx, Ly

# ----------------------------------------------------------------------------
#       Transform from 4th-order tensor to 2nd-order tensor
#       for small strain
# ----------------------------------------------------------------------------
def transform_4thTensor_to_2ndTensor(fourth):
	second = np.zeros([3, 3])
	second[0, 0] = fourth[0, 0, 0, 0]
	second[0, 1] = fourth[0, 0, 1, 1]
	second[0, 2] = fourth[0, 0, 0, 1]
	second[1, 0] = fourth[1, 1, 0, 0]
	second[1, 1] = fourth[1, 1, 1, 1]
	second[1, 2] = fourth[1, 1, 0, 1]
	second[2, 0] = fourth[0, 1, 0, 0]
	second[2, 1] = fourth[0, 1, 1, 1]
	second[2, 2] = fourth[0, 1, 0, 1]
	return second


# ----------------------------------------------------------------------------
#       Transform from 4th-order tensor to 2nd-order tensor
#       for large strain
# ----------------------------------------------------------------------------
def transform_4thTensor_to_2ndTensor_inlargestrain(fourth):
	return ut.transform_4thTensor_to_2ndTensor_inlargestrain(fourth)



