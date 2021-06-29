#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Wed Feb 28 14:48:50 2018

@author: minh.nguyen@ikm.uni-hannover.de
Purpose: FFT to homogenize 2-phase Laminate in 2D
"""

import numpy as np
from numpy import pi, sqrt, square, mean, power, zeros
import scipy.fftpack as fft
import time
import copy
from matplotlib import pyplot as plt
from matplotlib import cm
from mpl_toolkits.mplot3d import Axes3D
# from mayavi import mlab
import itertools  # To avoid parent-child loop

dim = 2
phase_number = 2


# ddot42 = lambda C, E: np.einsum('ijklxy,lkxy->ijxy', C, E)


def cal_effective_stiffness_linear(strain_macro):
    x, y, S11, S22, S12, E11, E22, E12 = solve_micro2D()
    C_effective = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]  # Pseduo value for effective
    return C_effective


def homogenize_microstructure(strain_macro):
    C_effective = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]  # Pseduo value for effective
    stress_homogenized = [0.5, 0.5, 0.5]  # Pseduo value for stress
    return C_effective, stress_homogenized


def setupMaterialPhase(lamda, mu):
    C = zeros([phase_number, dim, dim, dim, dim])
    I = np.eye(dim)
    # ISOTROPIC LINEAR MATERIAL STIFFNESS
    for phase_idx in range(phase_number):
        for i, j, k, l in itertools.product(range(dim), repeat=4):
            C[phase_idx, i, j, k, l] = lamda[phase_idx] * I[i, j] * I[k, l] + mu[phase_idx] * (I[i, k] * I[j, l] + I[i, l] * I[j, k])
        # for i in range(dim):
        #     for j in range(dim):
        #         for k in range(dim):
        #             for l in range(dim):
        #                 C[phase_idx, i, j, k, l] = lamda[phase_idx] * I[i, j] * I[k, l] + mu[phase_idx] * (I[i, k] * I[j, l] + I[i, l] * I[j, k])
    return C


def setupGrid(Lx, Ly, Nx, Ny):
    ax, bx = (-Lx / 2, Lx / 2)
    ay, by = (-Ly / 2, Ly / 2)
    scaleX, scaleY = ((bx - ax) / (2 * pi), (by - ay) / (2 * pi))
    hx, hy = ((bx - ax) / Nx, (by - ay) / Ny)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # SET UP GRID
    # SET UP GRID in REAL SPACE
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    xv = np.arange(ax + hx, bx + hx, hx)  # in Matlab --> a+h:h:b
    yv = np.arange(ay + hy, by + hy, hy)
    x, y = np.meshgrid(xv, yv)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # SET UP GRID in FOURIER SPACE
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    kxv1 = np.arange(0, Nx / 2 + 1, 1)  # in Matlab --> 0:Nx/2
    kxv2 = np.arange(-Nx / 2 + 1, -1 + 1, 1)  # in Matlab --> -Nx/2+1:-1
    kxv = scaleX * np.concatenate((kxv1, kxv2))
    kyv1 = np.arange(0, Ny / 2 + 1, 1)  # in Matlab --> 0:Ny/2
    kyv2 = np.arange(-Ny / 2 + 1, -1 + 1, 1)  # in Matlab --> -Ny/2+1:-1
    kyv = scaleY * np.concatenate((kyv1, kyv2))
    k1, k2 = np.meshgrid(kxv, kyv)
    return hx, hy, ax, bx, ay, by, xv, yv, x, y, kxv, kyv, k1, k2


def computeGreenOperator(Nx, Ny, lamda0, mu0, xi1, xi2):
    xi = np.array([xi1, xi2])
    normXi = sqrt(xi1 * xi1 + xi2 * xi2)
    normXi[0][0] = 1.0  # any value to avoid the singular in matrix N0 when taking into account the inverse of K0
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
        f_gamma0[i, j, k, l, 0, 0] = 0
    # for i in range(dim):
    #     for j in range(dim):
    #         for k in range(dim):
    #             for l in range(dim):
    #                 f_gamma0[i, j, k, l, :, :] = -factor1 * (I[i, k] * xi[j] * xi[l] + I[j, k] * xi[i] * xi[l] + \
    #                                                          I[i, l] * xi[j] * xi[k] + I[j, l] * xi[i] * xi[k])   \
    #                                              + (factor2 * xi[i] * xi[j] * xi[k] * xi[l]) / power(normXi, 4)
    #                 f_gamma0[i, j, k, l, 0, 0] = 0
    # ++++++++++++++++++++++++ END OF COMPUTING ++++++++++++++++++++++++++++++++++++++++++++++ #
    return f_gamma0


def executeFixedPointMethod(f_gamma0, C, Nx, Ny, E_avg):
    S = np.zeros([dim, dim, Nx, Ny])
    E = np.zeros([dim, dim, Nx, Ny])
    # Initial Strain
    for i, j, in itertools.product(range(dim), repeat=2):
        E[i, j, :, :] = E_avg[i, j]
    # for i in range(dim):
    #     for j in range(dim):
    #         E[i, j, :, :] = E_avg[i, j]
    # Initial Stress
    for i, j, k, l in itertools.product(range(dim), repeat=4):
        S[i, j, :, :] += C[i, j, k, l] * E[k, l, :, :]
    # for i in range(dim):
    #     for j in range(dim):
    #         for k in range(dim):
    #             for l in range(dim):
    #                 S[i, j, :, :] += C[i, j, k, l] * E[k, l, :, :]
    # # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Fixed Points Algorithm to solve Lippmman-Schwinger Equation.
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    maxIteration = 200
    for iter1 in range(0, maxIteration, 1):
        # FFT of Strain
        f_E = zeros(np.shape(E), dtype=complex)
        for i in range(dim):
            for j in range(dim):
                for k in range(dim):
                    for l in range(dim):
                        f_E[i, j, :, :] += f_gamma0[i, j, k, l, :, :] * fft.fft2(S[k, l, :, :])
                f_E[i, j, :, :] += fft.fft2(E[i, j, :, :])
        # Update solution for Strain
        f_E[:, :, 0, 0] = Nx * Ny * E_avg[:, :]
        E = fft.ifft2(f_E).real
        # Update solution for Stress
        S_temporary = zeros(np.shape(S))
        for i, j, k, l in itertools.product(range(dim), repeat=4):
            S_temporary[i, j, :, :] += C[i, j, k, l] * E[k, l, :, :]
        # for i in range(dim):
        #     for j in range(dim):
        #         for k in range(dim):
        #             for l in range(dim):
        #                 S_temporary[i, j, :, :] += C[i, j, k, l] * E[k, l, :, :]
        S = np.copy(S_temporary)
        # ++++++++++++++++++++++++++ END OF ALGORITHM +++++++++++++++++++++++++++++++++++++++++++++ #
    return S, E


def cal_average_stress_strain(S, E, hx, hy, ax, bx, ay, by):
    vol = (bx - ax) * (by - ay)
    S_macro = zeros([dim, dim])
    E_macro = zeros([dim, dim])
    for i in range(dim):
        for j in range(dim):
            S_macro[i, j] = 1.0 / vol * hx * hy * np.sum(S[i, j, :, :])
            E_macro[i, j] = 1.0 / vol * hx * hy * np.sum(E[i, j, :, :])
    return S_macro, E_macro


def cal_tangent_effective_moduli(f_gamma0, C, C0, Nx, Ny, x, y, hx, hy, ax, bx, ay, by):
    alpha = zeros((dim, dim, dim, dim, Nx, Ny))
    # C_delta = zeros([dim, dim, dim, dim, Nx, Ny])
    C_delta = C - C0
    # ----------------------------------------------------------------------------
    #   Part I: Calculate \frac{\partial \tilde{\epsilon}}{\partial \bar {\epsilon}}
    # ----------------------------------------------------------------------------
    maxIter2 = 10
    for iter2 in range(0, maxIter2, 1):
        C_delta_alpha = zeros((dim, dim, dim, dim, Nx, Ny))
        f_alpha = zeros((dim, dim, dim, dim, Nx, Ny), dtype=complex)
        for m, n, k, l, p, q in itertools.product(range(dim), repeat=6):
            C_delta_alpha[m, n, k, l, :, :] += C_delta[m, n, p, q, :, :] * alpha[p, q, k, l, :, :]
        # for m in range(dim):
        #     for n in range(dim):
        #         for k in range(dim):
        #             for l in range(dim):
        #                 for p in range(dim):
        #                     for q in range(dim):
        #                         C_delta_alpha[m, n, k, l, :, :] += C_delta[m, n, p, q, :, :] * alpha[p, q, k, l, :, :]

        C_delta_delta_alpha = C_delta + C_delta_alpha
        for i, j, k, l, m, n in itertools.product(range(dim), repeat=6):
            f_alpha[i, j, k, l, :, :] += f_gamma0[i, j, m, n, :, :] * fft.fft2(C_delta_delta_alpha[m, n, k, l, :, :])
        # for i in range(dim):
        #     for j in range(dim):
        #         for k in range(dim):
        #             for l in range(dim):
        #                 for m in range(dim):
        #                     for n in range(dim):
        #                         f_alpha[i, j, k, l, :, :] += f_gamma0[i, j, m, n, :, :] * fft.fft2(C_delta_delta_alpha[m, n, k, l, :, :])

        f_alpha[:, :, :, :, 0, 0] = 0
        alpha = fft.ifft2(f_alpha).real
    # ----------------------------------------------------------------------------
    #   Part II: Calculate consistent tangent stiffness based on
    # \frac{\partial \tilde{\epsilon}}{\partial \bar {\epsilon}}
    # ----------------------------------------------------------------------------
    beta = zeros((dim, dim, dim, dim, Nx, Ny))
    C_consistent_tangent = zeros((dim, dim, dim, dim))
    vol = (bx - ax) * (by - ay)
    for i, j, k, l, m, n in itertools.product(range(dim), repeat=6):
        beta[i, j, k, l, :, :] += C[i, j, m, n, :, :] * alpha[m, n, k, l, :, :]
    # for i in range(dim):
    #     for j in range(dim):
    #         for k in range(dim):
    #             for l in range(dim):
    #                 for m in range(dim):
    #                     for n in range(dim):
    #                         beta[i, j, k, l, :, :] += C[i, j, m, n, :, :] * alpha[m, n, k, l, :, :]
    beta = C + beta
    for i, j, k, l in itertools.product(range(dim), repeat=4):
        C_consistent_tangent[i, j, k, l] = 1.0 / vol * hx * hy * np.sum(beta[i, j, k, l, :, :])
    # for i in range(dim):
    #     for j in range(dim):
    #         for k in range(dim):
    #             for l in range(dim):
    #                 C_consistent_tangent[i, j, k, l] = 1.0 / vol * hx * hy * np.sum(beta[i, j, k, l, :, :])
    return C_consistent_tangent


def trapz2d(z, x=None, y=None, dx=1., dy=1.):
    ''' Integrates a regularly spaced 2D grid using the composite trapezium rule.
    IN:
       z : 2D array
       x : (optional) grid values for x (1D array)
       y : (optional) grid values for y (1D array)
       dx: if x is not supplied, set it to the x grid interval
       dy: if y is not supplied, set it to the x grid interval
    '''
    import numpy as N
    sum = N.sum
    # if x != None: original if
    if len(x) != 0: # Minh modified
        dx = (x[-1] - x[0]) / (N.shape(x)[0] - 1)
    # if y != None: original if
    if len(y) != 0: # Minh modified
        dy = (y[-1] - y[0]) / (N.shape(y)[0] - 1)

    s1 = z[0, 0] + z[-1, 0] + z[0, -1] + z[-1, -1]
    s2 = sum(z[1:-1, 0]) + sum(z[1:-1, -1]) + sum(z[0, 1:-1]) + sum(z[-1, 1:-1])
    s3 = sum(z[1:-1, 1:-1])
    return 0.25 * dx * dy * (s1 + 2 * s2 + 4 * s3)


def solve_micro2D():
    t = time.time()
    Lx, Ly = (2 * pi, 2 * pi)
    Nx, Ny = (2 ** 8, 2 ** 8)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # MATERIAL PARAMETERS
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    lamda = (1, 2)
    mu = (1, 2)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    CPhase = setupMaterialPhase(lamda, mu)
    hx, hy, ax, bx, ay, by, xv, yv, x, y, kxv, kyv, xi1, xi2 = setupGrid(Lx, Ly, Nx, Ny)

    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Serious bug may appear here
    # Be careful, here please of index X and index Y with the coordinate corresponding
    # The y index will be corresponding to the X coordinate
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Set up constituent materials
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    C = np.zeros([dim, dim, dim, dim, Nx, Ny])
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Set up reference material
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    mu0 = mean(mu)
    lamda0 = mean(lamda)
    CRef = setupMaterialPhase((lamda0, lamda0), (mu0, mu0))
    C0 = np.zeros([dim, dim, dim, dim, Nx, Ny])
    for m, valM in enumerate(yv):
        for n, valN in enumerate(xv):
            if (xv[n] < ax + Lx / 4.0) or (xv[n] > bx - Lx / 4.0):
                C[:, :, :, :, m, n] = np.copy(CPhase[0])  # Phase 1
                C0[:, :, :, :, m, n] = np.copy(CRef[0])  # Phase 1
            else:
                C[:, :, :, :, m, n] = np.copy(CPhase[1])  # Phase 2
                C0[:, :, :, :, m, n] = np.copy(CRef[1])  # Phase 2
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Computing GREEN Operator
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    f_gamma0 = computeGreenOperator(Nx, Ny, lamda0, mu0, xi1, xi2)

    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Prescribed Strains
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    E11_avg = 1.0 / 100
    E22_avg = 2.0 / 100
    E12_avg = 0.0
    E_avg = np.array([[E11_avg, E12_avg], [E12_avg, E22_avg]])
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Fixed Points Algorithm to solve Lippmann-Schwinger Equ.
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    stress, strain = executeFixedPointMethod(f_gamma0, C, Nx, Ny, E_avg)
    stress_homogenized, strain_homogenized = cal_average_stress_strain(stress, strain, hx, hy, ax, bx, ay, by)
    C_homogenized = cal_tangent_effective_moduli(f_gamma0, C, C0, Nx, Ny, xv, yv, hx, hy, ax, bx, ay, by)
    C_homogenized_matrix = transform_4thTensor_to_2ndTensor(C_homogenized)
    print(time.time() - t)
    return x, y, stress, strain, stress_homogenized, strain_homogenized, C_homogenized_matrix


def transform_4thTensor_to_2ndTensor(fourth):
    second = np.zeros([3, 3])
    second[0, 0] = fourth[0,0,0,0]
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
    x, y, stress_micro, strain_micro, stress_average, strain_average, C_effective_tangent = solve_micro2D()
    # x, y, stress_micro, strain_micro = solve_micro2D()
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Plotting & Validating the results
    # PLOT 3D with mplot3d
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    fig = plt.figure(figsize=plt.figaspect(0.5))
    ax = fig.add_subplot(3, 1, 1, projection='3d')
    ax.plot_surface(x, y, strain_micro[0,0], rstride=1, cstride=1, cmap=cm.coolwarm)
    ax = fig.add_subplot(3, 1, 2, projection='3d')
    ax.plot_surface(x, y, strain_micro[1,1], rstride=1, cstride=1, cmap=cm.coolwarm)
    ax = fig.add_subplot(3, 1, 3, projection='3d')
    ax.plot_surface(x, y, strain_micro[0,1], rstride=1, cstride=1, cmap=cm.coolwarm)
    plt.show()
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # surf = mlab.surf(x, y, strain[0, :, :], warp_scale="auto")
    # mlab.show()
