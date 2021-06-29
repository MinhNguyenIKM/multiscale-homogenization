#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Wed Feb 28 14:48:50 2018

@author: minh.nguyen@ikm.uni-hannover.de
Purpose: FFT to homogenize 2-phase Laminate in 2D
"""
# -------------------------------------------------------------------------------------------
#                       CONVENTIONAL FFT Homogenization for small strain
#                       ODD NUMBER
# -------------------------------------------------------------------------------------------
import numpy as np
from numpy import pi, sqrt, square, mean, power, zeros
from numpy.linalg import norm
import scipy.fftpack as fft
import time
import copy
from matplotlib import pyplot as plt
from matplotlib import cm
from mpl_toolkits.mplot3d import Axes3D
# from mayavi import mlab
import itertools  # To avoid parent-child loop


# ---------------------------------------------------------------------------
dim = 2
ax, bx = (-pi/100.0, pi/100.0)
ay, by = (-pi/100.0, pi/100.0)
GRID = (2**7 + 1, 2**7 + 1)  # number of pixels/voxels (assumed equal for all directions)
Nx, Ny = (GRID[1], GRID[0])
ndof = (dim ** 2) * (Nx * Ny)
# --------------- Set up GRID ----------------------------------------------
Lx = bx - ax
Ly = by - ay
scaleX, scaleY = ((2 * pi) / (bx - ax), (2 * pi) / (by - ay))
freqX = scaleX * np.arange(-(Nx - 1) / 2., (Nx - 1) / 2. + 1)  # coordinate axis -> freq. axis # Even node number
freqY = scaleY * np.arange(-(Ny - 1) / 2., (Ny - 1) / 2. + 1)  # coordinate axis -> freq. axis # Even node number
centerPointX = np.where(abs(freqX - 0.0) < 1e-10)[0][0]
centerPointY = np.where(abs(freqY - 0.0) < 1e-10)[0][0]
hx = (bx - ax) / Nx
hy = (by - ay) / Ny
X_center = np.arange(ax + hx / 2.0, bx - hx / 2.0 + hx, hx)  # ax+hx/2 : bx-hx/2
Y_center = np.arange(ay + hy / 2.0, by - hy / 2.0 + hy, hy)  # ay+hy/2 : by-hy/2
X_grid = X_center + hx / 2
Y_grid = Y_center + hy / 2
X, Y = np.meshgrid(Y_grid, X_grid)  # Be attention to the order of Y and X
xi = np.zeros([2, Nx, Ny])
xi1, xi2 = np.meshgrid(freqY, freqX)  # Be attention to the order of Y and X
xi[0] = xi1
xi[1] = xi2
# --------------------------------------------------------------------------
ddot42 = lambda A4, B2: np.einsum('ijklxy,lkxy->ijxy', A4, B2)
ddot44 = lambda A4, B4: np.einsum('ijmnxy,nmklxy->ijklxy', A4, B4)
dyad22 = lambda A2, B2: np.einsum('ijxy,klxy->ijklxy', A2, B2)

# identity tensor
identity = np.eye(dim)
I2 = np.einsum('ij,xy', identity, np.ones([Nx, Ny]))
I4rt = np.einsum('ijkl,xy->ijklxy', np.einsum('ik,jl', identity, identity), np.ones([Nx, Ny]))
I4 = np.einsum('ijkl,xy->ijklxy', np.einsum('il,jk', identity, identity), np.ones([Nx, Ny]))
II = dyad22(I2, I2)


# (inverse) Fourier transform (for each tensor component in each direction)
myfft    = lambda v: np.fft.fftshift(np.fft.fftn(np.fft.ifftshift(v), [Nx, Ny]))
myifft   = lambda v: np.fft.fftshift(np.fft.ifftn(np.fft.ifftshift(v), [Nx, Ny]))


def cal_effective_stiffness_linear(strain_macro):
    x, y, S11, S22, S12, E11, E22, E12 = solve_micro2D()
    C_effective = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]  # Pseduo value for effective
    return C_effective


def homogenize_microstructure(strain_macro):
    C_effective = np.array([[1, 0, 0], [0, 1, 0], [0, 0, 1]])  # Pseduo value for effective
    stress_homogenized = np.array([[0.02, 0.05], [0.05, 0.01]])  # Pseduo value for stress
    return C_effective, stress_homogenized


def get_C(lam, mu):
    # ISOTROPIC LINEAR MATERIAL STIFFNESS
    C4 = lam * II + mu * (I4 + I4rt)
    return C4


# ------------------- PROBLEM DEFINITION / CONSTITIVE MODEL -------------------
def computeGreenOperator(Nx, Ny, lamda0, mu0, xi1, xi2):
    xi = np.array([xi1, xi2])
    normXi = sqrt(xi1 * xi1 + xi2 * xi2)
    normXi[centerPointX][centerPointY] = 1.0  # any value to avoid the singular in matrix N0 when taking into account the inverse of K0
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Computing GREEN Operator
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    f_gamma0 = zeros([dim, dim, dim, dim, Nx, Ny])
    I = np.eye(dim)
    factor1 = 1 / (4 * mu0 * square(normXi))
    factor2 = (lamda0 + mu0) / (mu0 * (lamda0 + 2 * mu0))
    for i, j, k, l in itertools.product(range(dim), repeat=4):
        f_gamma0[i, j, k, l, :, :] = -factor1 * (I[i, k] * xi[j] * xi[l] + I[j, k] * xi[i] * xi[l] + \
                                                 I[i, l] * xi[j] * xi[k] + I[j, l] * xi[i] * xi[k]) \
                                     + (factor2 * xi[i] * xi[j] * xi[k] * xi[l]) / power(normXi, 4)
        f_gamma0[i, j, k, l, centerPointX, centerPointY] = 0
    return f_gamma0


def executeFixedPointMethod(f_gamma0, C, Nx, Ny, E_avg, xi1, xi2):
    xi = np.array([xi1, xi2])
    E = np.zeros([dim, dim, Nx, Ny])
    # Initial Strain
    for i, j, in itertools.product(range(dim), repeat=2):
        E[i, j, :, :] = E_avg[i, j]
    # Initial Stress
    S = ddot42(C, E)
    # # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Fixed Points Algorithm to solve Lippmman-Schwinger Equation.
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    maxIteration1 = 100
    iter1 = 0
    TOL = 1e-10
    while iter1 < maxIteration1:
        # FFT of Stress
        f_S = myfft(S)
        # Checking Convergence
        if iter1 > -1 and norm([f_S[0, 0, centerPointX, centerPointY], f_S[0, 1, centerPointX, centerPointY]]) != 0:
            error = norm(xi[0] * f_S[0, 0, :, :] + xi[1] * f_S[0, 1, :, :])
            error = error / norm([f_S[0, 0, centerPointX, centerPointY], f_S[0, 1, centerPointX, centerPointY]])
            print('Step ' + str(iter1) + ' - Convergence of fixed-point method : ' + str(error.real))
            if error.real < TOL:
                print('Step ' + str(iter1) + ' - Convergence of fixed-point method : ' + str(error.real))
                break
        f_E = ddot42(f_gamma0, f_S) + myfft(E)
        # Boundary condition
        f_E[:, :, centerPointX, centerPointY] = Nx * Ny * E_avg[:, :]
        # Update solution for Strain
        E = myifft(f_E).real
        # Update solution for Stress
        S = ddot42(C, E)
        iter1 += 1
        # ++++++++++++++++++++++++++ END OF ALGORITHM +++++++++++++++++++++++++++++++++++++++++++++ #
    return S, E


def cal_average_stress_strain(S, E, hx, hy, ax, bx, ay, by):
    vol = (bx - ax) * (by - ay)
    S_macro = zeros([dim, dim])
    E_macro = zeros([dim, dim])
    for i, j in itertools.product(range(dim), repeat=2):
        S_macro[i, j] = 1.0 / vol * hx * hy * np.sum(S[i, j, :, :])
        E_macro[i, j] = 1.0 / vol * hx * hy * np.sum(E[i, j, :, :])
    return S_macro, E_macro


def cal_tangent_effective_moduli(f_gamma0, C, C0, Nx, Ny, hx, hy, ax, bx, ay, by, xi1, xi2, S_homogenized, E_homogenized):
    xi = np.array([xi1, xi2])
    alpha = zeros((dim, dim, dim, dim, Nx, Ny))
    C_delta = C - C0
    C_consistent_tangent = zeros((dim, dim, dim, dim))
    vol = (bx - ax) * (by - ay)
    # ----------------------------------------------------------------------------
    #   Part I: Calculate \frac{\partial \tilde{\epsilon}}{\partial \bar {\epsilon}}
    # ----------------------------------------------------------------------------
    TOL = 1e-10
    maxIter2 = 100
    iter2 = 1
    while iter2 < maxIter2:
        f_alpha = ddot44(f_gamma0, myfft(C_delta + ddot44(C_delta, alpha)))
        # Boundary condition
        f_alpha[:, :, :, :, centerPointX, centerPointY] = 0
        alpha = myifft(f_alpha).real

        # CHECK CONVERGENCE
        if iter2 > 0 and norm(S_homogenized) != 0:
            # Calculate consistent tangent stiffness
            beta = ddot44(C, (I4 + alpha))
            for i, j, k, l in itertools.product(range(dim), repeat=4):
                C_consistent_tangent[i, j, k, l] = 1.0 / vol * hx * hy * np.sum(beta[i, j, k, l, :, :])
            S = np.einsum('ijkl,lk->ij', C_consistent_tangent, E_homogenized)
            error = norm(S - S_homogenized) / norm(S_homogenized)
            print('Step ' + str(iter2) + ' - Convergence of tangent moduli : ' + str(error.real))
            if error.real < TOL:
                print('Step ' + str(iter2) + ' - Convergence of tangent moduli : ' + str(error.real))
                return C_consistent_tangent
        iter2 += 1

    # ----------------------------------------------------------------------------
    #   Part II: Calculate consistent tangent stiffness based on
    # \frac{\partial \tilde{\epsilon}}{\partial \bar {\epsilon}}
    # ----------------------------------------------------------------------------
    C_consistent_tangent = zeros((dim, dim, dim, dim))
    vol = (bx - ax) * (by - ay)
    beta = ddot44(C, (I4 + alpha))
    for i, j, k, l in itertools.product(range(dim), repeat=4):
        C_consistent_tangent[i, j, k, l] = 1.0 / vol * hx * hy * np.sum(beta[i, j, k, l, :, :])
    return C_consistent_tangent


def setup_Laminate():
    phase = np.zeros([Nx, Ny])
    phase[:, X[0, :] < ax + Lx/4.0] = 1
    phase[:, X[0, :] > bx - Lx/4.0] = 1
    return phase


def setup_matrix_inclusion():
    phase = np.zeros([Nx, Ny])
    R = (bx - ax) / 6.0
    for idx, xCoord in enumerate(X_grid):
        idy = sqrt(power(xCoord - X[centerPointX, centerPointY], 2) + power(Y_grid - Y[centerPointX, centerPointY], 2)) < R
        phase[idx, idy] = 1
    return phase


def setup_parameters(p0, p1, phase):
    return p0 * np.ones([Nx, Ny]) * phase + p1 * np.ones([Nx, Ny]) * (1 - phase)


def get_lamda_mu(mat):
    lamda1 = mat.p1.E * mat.p1.nu / ((1 + mat.p1.nu) * (1 - 2 * mat.p1.nu))
    lamda2 = mat.p2.E * mat.p2.nu / ((1 + mat.p2.nu) * (1 - 2 * mat.p2.nu))
    mu1 = mat.p1.E / (2 * (1 + mat.p1.nu))
    mu2 = mat.p2.E / (2 * (1 + mat.p2.nu))
    lamda = np.array([lamda1, lamda2])
    mu = np.array([mu1, mu2])
    return lamda, mu

def solve_micro2D(mat, macro_strain):
    # macro_strain = [1.0 / 100, 2.0 / 100, 0.00]
    print("macro strain : ", macro_strain)
    t = time.time()
    lamda, mu = get_lamda_mu(mat)
    # print(Lx, Ly, hx, hy, X_grid, Y_grid, X, Y, freqX, freqY, xi1, xi2, centerPointX, centerPointY)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # MATERIAL PARAMETERS
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # lamda = (1, 2)
    # mu = (1, 2)
    mu0 = mean(mu)
    lamda0 = mean(lamda)
    phase = setup_matrix_inclusion()
    lambda_phase = setup_parameters(lamda[0], lamda[1], phase)
    mu_phase = setup_parameters(mu[0], mu[1], phase)
    lambda0_phase = setup_parameters(lamda0, lamda0, phase)
    mu0_phase = setup_parameters(mu0, mu0, phase)
    C = get_C(lambda_phase, mu_phase)
    C0 = get_C(lambda0_phase, mu0_phase)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Computing GREEN Operator
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    f_gamma0 = computeGreenOperator(Nx, Ny, lamda0, mu0, xi1, xi2)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Prescribed Strains
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # E11_avg = 1.0 / 100
    # E22_avg = 2.0 / 100
    # E12_avg = 0.02
    E11_avg = macro_strain[0]
    E22_avg = macro_strain[1]
    E12_avg = macro_strain[2] / 2.0
    E_avg = np.array([[E11_avg, E12_avg], [E12_avg, E22_avg]])
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Fixed Points Algorithm to solve Lippmann-Schwinger Equ.
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    stress, strain = executeFixedPointMethod(f_gamma0, C, Nx, Ny, E_avg, xi1, xi2)
    print("Completed fixed-point method in : ", (time.time() - t))
    stress_homogenized, strain_homogenized = cal_average_stress_strain(stress, strain, hx, hy, ax, bx, ay, by)
    C_homogenized = cal_tangent_effective_moduli(f_gamma0, C, C0, Nx, Ny, hx, hy, ax, bx, ay, by, xi1, xi2, stress_homogenized, strain_homogenized)
    C_homogenized_matrix = transform_4thTensor_to_2ndTensor(C_homogenized)
    print("Completed whole program in : ", (time.time() - t))
    return X, Y, stress, strain, stress_homogenized, strain_homogenized, C_homogenized_matrix


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


if __name__ == '__main__':
    macro_strain = [1.0/100, 2.0/100, 0.00]
    # mat = {
    #     "p1": {
    #         "type": "PlaneStrain",
    #         "E": 2.666666,
    #         "nu": 0.333333
    #     },
    #     "p2": {
    #         "type": "PlaneStrain",
    #         "E": 133.333333,
    #         "nu": 0.333333
    #     }
    # }
    x, y, stress_micro, strain_micro, stress_average, strain_average, C_effective_tangent = solve_micro2D(None, macro_strain)
    # x, y, stress_micro, strain_micro = solve_micro2D()
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Plotting & Validating the results
    # PLOT 3D with mplot3d
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    fig = plt.figure(figsize=plt.figaspect(0.5))
    ax = fig.add_subplot(1, 1, 1, projection='3d')
    surf = ax.plot_surface(x, y, strain_micro[0, 0], rstride=1, cstride=1, cmap=cm.coolwarm)
    # ax.view_init(elev=90., azim=90)
    # ax.plot_surface(x, y, strain_micro[1, 1], rstride=1, cstride=1, cmap=cm.coolwarm)
    # ax.view_init(elev=90., azim=90)
    # ax = fig.add_subplot(3, 1, 3, projection='3d')
    # ax.plot_surface(x, y, strain_micro[0, 1], rstride=1, cstride=1, cmap=cm.coolwarm)
    cbar = fig.colorbar(surf, shrink=0.5, aspect=5)
    cbar.set_label("strain_xx")
    # ax.view_init(elev=60., azim=70)
    ax.view_init(elev=90., azim=90)
    # ax.grid(False)
    ax.grid(True)
    # ax.w_zaxis.line.set_lw(0.)
    # ax.set_zticks([])
    plt.show()
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    # ---------- MAYAVI Plot -------------------
    # from mayavi import mlab
    # mlab.figure(1, bgcolor=(1, 1, 1), fgcolor=(0, 0, 0), size=(400, 300))
    # mlab.clf()
    # mlab.mesh(X, Y, strain_micro[0,0], representation='surface', colormap='jet')
    # mlab.colorbar(label_fmt='%.5f', title='E11', orientation='vertical')
    # mlab.view(90, 70, 6.2, (-1.3, -2.9, 0.25))
    # mlab.savefig(filename='test.eps')
    # mlab.show()