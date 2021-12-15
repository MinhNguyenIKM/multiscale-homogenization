# https://scipython.com/blog/visualizing-the-bivariate-gaussian-distribution/
import numpy as np
import matplotlib.pyplot as plt
from matplotlib import cm
import pylab as p
import mpl_toolkits.mplot3d.axes3d as p3
from mpl_toolkits.mplot3d import Axes3D
from scipy.stats import multivariate_normal
# Our 2-dimensional distribution will be over variables X and Y
N = 10
dim = 3
X = np.linspace(-10e-3, 10e-3, N)
Y = np.linspace(-10e-3, 10e-3, N)
Z = np.linspace(-10e-3, 10e-3, N)
# X, Y = np.meshgrid(X1, Y1)
x, y, z = np.meshgrid(X, Y, Z)
# Mean vector and covariance matrix
mu = np.array([0.0, 0.0, 0.0])
Sigma = np.array([[1.0, 0.0, 0.0], [0.0,  1.0, 0.0], [0.0, 0.0, 1.0]])

# Pack X and Y into a single 3-dimensional array
pos = np.zeros([N, N, N, 3])
pos[:, :, :, 0] = x
pos[:, :, :, 1] = y
pos[:, :, :, 2] = z

# rv = multivariate_normal([0.5, -0.2], [[2.0, 0.3], [0.3, 0.5]])
def multivariate_gaussian(pos, mu, Sigma):
    """Return the multivariate Gaussian distribution on array pos.

    pos is an array constructed by packing the meshed arrays of variables
    x_1, x_2, x_3, ..., x_k into its _last_ dimension.

    """
    Sigma_det = np.linalg.det(Sigma)
    Sigma_inv = np.linalg.inv(Sigma)
    N = np.sqrt((2*np.pi)**dim * Sigma_det)
    # This einsum call calculates (x-mu)T.Sigma-1.(x-mu) in a vectorized
    # way across all the input variables.
    fac = np.einsum('...k,kl,...l->...', pos-mu, Sigma_inv, pos-mu)
    return np.exp(-fac / 2) / N

# The distribution on the variables X, Y packed into pos.
F = multivariate_gaussian(pos, mu, Sigma)
# Fcolor = np.zeros([N,3])
# Fcolor[:,0] = F[:,0,0]
# Fcolor[:,1] = F[0,:,0]
# Fcolor[:,2] = F[0,0,:]
# Create a surface plot and projected filled contour plot under it.
# ax = plt.axes(projection='3d')
# ax.plot_surface(np.log(X), np.log(Y), np.log(Z), rstride=3, cstride=3, linewidth=1, antialiased=True, cmap=cm.viridis)

from mayavi import mlab

mlab.points3d(x, y, z, F[:,:,:])
mlab.show()

# ax.scatter(1000*X, 1000*Y, 1000*Z, c=1000*Z, rstride=3, cstride=3, linewidth=1, antialiased=True, cmap=cm.viridis)
# ax = plt.axes(projection='3d')
# ax.scatter(1000*X, 1000*Y, 1000*Z, c=1000*Z, cmap='viridis', linewidth=0.5);
# ax.view_init(elev=90., azim=90)
# ax.plot_surface(x, y, strain_micro[1, 1], rstride=1, cstride=1, cmap=cm.coolwarm)
# ax.view_init(elev=90., azim=90)
# ax = fig.add_subplot(3, 1, 3, projection='3d')
# ax.plot_surface(x, y, strain_micro[0, 1], rstride=1, cstride=1, cmap=cm.coolwarm)
# cbar = fig.colorbar(surf, shrink=0.5, aspect=5)
# cbar.set_label("strain_xx")
# ax.view_init(elev=60., azim=70)
# ax.view_init(elev=90., azim=90)
# ax.grid(False)
# ax.grid(True)
# ax.w_zaxis.line.set_lw(0.)
# ax.set_zticks([])
# plt.show()



# cset = ax.contourf(np.log10(X), np.log10(Y), np.log10(Z), zdir='z', offset=-0.15, cmap=cm.coolwarm)

# Adjust the limits, ticks and view angle
# ax.set_zlim(-0.15,0.2)
# ax.set_zticks(np.linspace(0,0.2,5))
# ax.view_init(27, -21)
# plt.show()
#
# import numpy as np
# from scipy.stats import multivariate_normal
# import matplotlib.pyplot as plt
# x = np.linspace(0, 5, 10, endpoint=False)
# y = multivariate_normal.pdf(x, mean=2.5, cov=0.5); y
# np.array([ 0.00108914,  0.01033349,  0.05946514,  0.20755375,  0.43939129,
#         0.56418958,  0.43939129,  0.20755375,  0.05946514,  0.01033349])
# plt.plot(x, y)
# plt.show()