import numpy as np

#----------------------------------------------------------------------------------------------------
#	Utility module
# 	minh.nguyen@ikm.uni-hannover.de
#	Create date: 20/09/2018
#----------------------------------------------------------------------------------------------------
def trapz2d(z, x=None, y=None, dx=1., dy=1.):
	""" Integrates a regularly spaced 2D grid using the composite trapezium rule.
	IN:
	   z : 2D array
	   x : (optional) grid values for x (1D array)
	   y : (optional) grid values for y (1D array)
	   dx: if x is not supplied, set it to the x grid interval
	   dy: if y is not supplied, set it to the x grid interval
	"""
	sum = np.sum
	# if x != None: original if
	if len(x) != 0:  # Minh modified
		dx = (x[-1] - x[0]) / (np.shape(x)[0] - 1)
	# if y != None: original if
	if len(y) != 0:  # Minh modified
		dy = (y[-1] - y[0]) / (np.shape(y)[0] - 1)
	s1 = z[0, 0] + z[-1, 0] + z[0, -1] + z[-1, -1]
	s2 = sum(z[1:-1, 0]) + sum(z[1:-1, -1]) + sum(z[0, 1:-1]) + sum(z[-1, 1:-1])
	s3 = sum(z[1:-1, 1:-1])
	return 0.25 * dx * dy * (s1 + 2 * s2 + 4 * s3)


# ----------------------------------------------------------------------------
#       Transform from 4th-order tensor to 2nd-order tensor
#       for large strain
# ----------------------------------------------------------------------------
def transform_4thTensor_to_2ndTensor_inlargestrain(fourth):
	second = np.zeros([4, 4])
	second[0, 0] = fourth[0, 0, 0, 0]
	second[0, 1] = fourth[0, 0, 0, 1]
	second[0, 2] = fourth[0, 0, 1, 0]
	second[0, 3] = fourth[0, 0, 1, 1]
	second[1, 0] = fourth[0, 1, 0, 0]
	second[1, 1] = fourth[0, 1, 0, 1]
	second[1, 2] = fourth[0, 1, 1, 0]
	second[1, 3] = fourth[0, 1, 1, 1]
	second[2, 0] = fourth[1, 0, 0, 0]
	second[2, 1] = fourth[1, 0, 0, 1]
	second[2, 2] = fourth[1, 0, 1, 0]
	second[2, 3] = fourth[1, 0, 1, 1]
	second[3, 0] = fourth[1, 1, 0, 0]
	second[3, 1] = fourth[1, 1, 0, 1]
	second[3, 2] = fourth[1, 1, 1, 0]
	second[3, 3] = fourth[1, 1, 1, 1]
	return second


# ----------------------------------------------------------------------------
#       Transform from a Matrix to a Vector with follow index:
#		[[11, 12], [21, 22]] -> [11, 12, 21, 22]
# ----------------------------------------------------------------------------
def transform_matrix_to_vector(matrix):
	vec = np.zeros(4)
	vec[0] = matrix[0, 0]
	vec[1] = matrix[0, 1]
	vec[2] = matrix[1, 0]
	vec[3] = matrix[1, 1]
	return vec

