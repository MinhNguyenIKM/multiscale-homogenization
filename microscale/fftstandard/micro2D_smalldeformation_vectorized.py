#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Wed Feb 28 14:48:50 2018

@author: minh
"""

import numpy as np
from numpy import pi, sqrt, square, mean, power
import scipy.fftpack as fft
import time
import copy
from matplotlib import pyplot as plt
from matplotlib import cm
from mpl_toolkits.mplot3d import Axes3D
#from mayavi import mlab


def cal_effective_stiffness_linear(strain_macro):
    x, y, S11, S22, S12, E11, E22, E12 = solve_micro2D()
    C_effective = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]  # Pseduo value for effective
    return C_effective


def homogenize_microstructure(strain_macro):
    C_effective = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]  # Pseduo value for effective
    stress_homogenized = [0.5, 0.5, 0.5]  # Pseduo value for stress
    return C_effective, stress_homogenized


def setupMaterialPhase(lamda, mu):
    return {
        '1': np.array([
                [lamda[0] + 2*mu[0], lamda[0], 0],
                [lamda[0], lamda[0] + 2*mu[0], 0],
                [0, 0, mu[0]]
        ]),
        '2': np.array([
                [lamda[1] + 2 * mu[1], lamda[1], 0],
                [lamda[1], lamda[1] + 2 * mu[1], 0],
                [0, 0, mu[1]]
        ])
    }


def setupGrid(Lx, Ly, Nx, Ny):
    ax, bx = (-Lx/2, Lx/2)
    ay, by = (-Ly/2, Ly/2)
    scaleX, scaleY = ((bx-ax)/(2*pi), (by-ay)/(2*pi))
    hx, hy = ((bx-ax)/Nx, (by-ay)/Ny)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # SET UP GRID
    # SET UP GRID in REAL SPACE
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    xv = np.arange(ax+hx, bx+hx, hx) # in Matlab --> a+h:h:b
    yv = np.arange(ay+hy, by+hy, hy)
    x, y = np.meshgrid(xv, yv)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # SET UP GRID in FOURIER SPACE
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    kxv1 = np.arange(0, Nx/2 + 1, 1) # in Matlab --> 0:Nx/2
    kxv2 = np.arange(-Nx/2+1, -1 + 1, 1)  # in Matlab --> -Nx/2+1:-1
    kxv = scaleX * np.concatenate((kxv1, kxv2))
    kyv1 = np.arange(0, Ny/2 + 1, 1)  # in Matlab --> 0:Ny/2
    kyv2 = np.arange(-Ny/2+1, -1 + 1, 1)  # in Matlab --> -Ny/2+1:-1
    kyv = scaleY * np.concatenate((kyv1, kyv2))
    k1, k2 = np.meshgrid(kxv, kyv)
    return ax, bx, xv, yv, x, y, kxv, kyv, k1, k2


def computeGreenOperatorDefault(Nx, Ny, lamda0, mu0, xi1, xi2):
    normXi = sqrt(xi1 * xi1 + xi2 * xi2)
    K0 = np.zeros([2, 2, Nx, Ny])
    normXi[0][0] = 1.0  # any value to avoid the singular in matrix N0 when taking into account the inverse of K0
    K0[0, 0, :, :] = (lamda0 + mu0) * square(xi1) + mu0 * square(normXi)
    K0[0, 1, :, :] = (lamda0 + mu0) * xi1 * xi2
    K0[1, 0, :, :] = K0[0, 1, :, :]
    K0[1, 1, :, :] = (lamda0 + mu0) * square(xi2) + mu0 * square(normXi)
    N0 = np.zeros([2, 2, Nx, Ny])
    for m in range(0, Ny, 1):
        for n in range(0, Nx, 1):
            N0[:, :, m, n] = np.linalg.inv(K0[:, :, m, n])
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Another way to calculate NO
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # N0 = np.zeros([2, 2, Nx, Ny])
    # #normXi[0][0] = 1  # whatever number to avoid singular in calculating N0
    # N0[0, 0, :, :] = 1 / (mu0 * square(normXi)) * (np.eye([Nx, Ny]) - ((lamda0 + mu0) * xi1 * xi2) / ((lamda0 + 2 * mu0) * square(normXi)))
    # N0[0, 1, :, :] = 1 / (mu0 * square(normXi)) * ( -((lamda0 + mu0) * xi1 * xi2) / ((lamda0 + 2*mu0) * square(normXi)))
    # N0[1, 0, :, :] = N0[0, 1, :, :]
    # N0[1, 1, :, :] = 1 / (mu0 * square(normXi)) * (np.ones([Nx, Ny]) - ((lamda0 + mu0) * xi1 * xi2) / ((lamda0 + 2 * mu0) * square(normXi)))
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Computing GREEN Operator
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    fgamma0_1111 = -1.0 / 4.0 * (N0[0, 0, :, :] * xi1 * xi1) * 4.0
    fgamma0_1122 = -1.0 / 4.0 * (N0[0, 1, :, :] * xi1 * xi2) * 4.0
    fgamma0_1112 = -1.0 / 4.0 * (2.0 * N0[0, 0, :, :] * xi1 * xi2 + 2.0 * N0[0, 1, :, :] * xi1 * xi1)
    fgamma0_2211 = fgamma0_1122[:]
    fgamma0_2222 = -1.0 / 4.0 * (N0[1, 1, :, :] * xi2 * xi2) * 4.0
    fgamma0_2212 = -1.0 / 4.0 * (2.0 * N0[1, 0, :, :] * xi2 * xi2 + 2.0 * N0[1, 1, :, :] * xi2 * xi1)
    fgamma0_1211 = fgamma0_1112[:]
    fgamma0_1222 = fgamma0_2212[:]
    fgamma0_1212 = -1.0 / 4.0 * (
            N0[0, 0, :, :] * xi2 * xi2 + N0[1, 0, :, :] * xi1 * xi2 + N0[0, 1, :, :] * xi2 * xi1 + N0[1, 1, :,
                                                                                                   :] * xi1 * xi1)
    fgamma0 = np.zeros([3, 3, Nx, Ny])
    fgamma0[0, 0, :, :] = fgamma0_1111
    fgamma0[0, 1, :, :] = fgamma0_1122
    fgamma0[0, 2, :, :] = fgamma0_1112
    fgamma0[1, 0, :, :] = fgamma0_2211
    fgamma0[1, 1, :, :] = fgamma0_2222
    fgamma0[1, 2, :, :] = fgamma0_2212
    fgamma0[2, 0, :, :] = fgamma0_1211
    fgamma0[2, 1, :, :] = fgamma0_1222
    fgamma0[2, 2, :, :] = fgamma0_1212
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    return fgamma0


def computeGreenOperator(Nx, Ny, lamda0, mu0, xi1, xi2):
    normXi = sqrt(xi1*xi1 + xi2*xi2)
    normXi[0][0] = 1.0  # any value to avoid the singular in matrix N0 when taking into account the inverse of K0
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Computing GREEN Operator
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    factor1 = 1 / (4 * mu0 * square(normXi))
    factor2 = (lamda0 + mu0) / (mu0 * (lamda0 + 2 * mu0))
    fgamma0_1111 = -factor1 * (4 * xi1 * xi1) + factor2 * (xi1 * xi1 * xi1 * xi1) / power(normXi, 4)
    fgamma0_1122 = factor2 * (xi1 * xi1 * xi2 * xi2) / power(normXi, 4)
    fgamma0_1112 = -factor1 * (2 * xi1 * xi2) + factor2 * (xi1 * xi1 * xi1 * xi2) / power(normXi, 4)
    fgamma0_2211 = fgamma0_1122[:]
    fgamma0_2222 = -factor1 * (4 * xi2 * xi2) + factor2 * (xi2 * xi2 * xi2 * xi2) / power(normXi, 4)
    fgamma0_2212 = -factor1 * (2 * xi2 * xi1) + factor2 * (xi2 * xi2 * xi1 * xi2) / power(normXi, 4)
    fgamma0_1211 = fgamma0_1112[:]
    fgamma0_1222 = fgamma0_2212[:]
    fgamma0_1212 = -factor1 * (xi2 * xi2 + xi1 * xi1) + factor2 * (xi1 * xi2 * xi1 * xi2) / power(normXi, 4)
    fgamma0 = np.zeros([3, 3, Nx, Ny])
    fgamma0[0, 0, :, :] = fgamma0_1111
    fgamma0[0, 1, :, :] = fgamma0_1122
    fgamma0[0, 2, :, :] = fgamma0_1112
    fgamma0[1, 0, :, :] = fgamma0_2211
    fgamma0[1, 1, :, :] = fgamma0_2222
    fgamma0[1, 2, :, :] = fgamma0_2212
    fgamma0[2, 0, :, :] = fgamma0_1211
    fgamma0[2, 1, :, :] = fgamma0_1222
    fgamma0[2, 2, :, :] = fgamma0_1212
    # ++++++++++++++++++++++++ END OF COMPUTING ++++++++++++++++++++++++++++++++++++++++++++++ #
    return fgamma0


def executeFixedPointMethod(fgamma0, S11, S22, S12, E11, E22, E12, C, Nx, Ny, E_avg):
    E11_avg = E_avg[0]
    E22_avg = E_avg[1]
    E12_avg = E_avg[2]
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Fixed Points Algorithm to solve Lippman-Schwinger Equ.
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    maxIteration = 200
    fstress11 = np.zeros([Nx, Ny], dtype=complex)
    fstress22 = np.zeros([Nx, Ny], dtype=complex)
    fstress12 = np.zeros([Nx, Ny], dtype=complex)
    fstrain11 = np.zeros([Nx, Ny], dtype=complex)
    fstrain22 = np.zeros([Nx, Ny], dtype=complex)
    fstrain12 = np.zeros([Nx, Ny], dtype=complex)
    for i in range(0, maxIteration, 1):
        fstress11 = fft.fft2(S11)  # Sigma_11
        fstress22 = fft.fft2(S22)  # Sigma_22
        fstress12 = fft.fft2(S12)  # Sigma_12

        fstrain11 = fft.fft2(E11)  # Epsilon_11
        fstrain22 = fft.fft2(E22)  # Epsilon_22
        fstrain12 = fft.fft2(E12)  # Epsilon_12

        fstrain11 = fstrain11 + (fgamma0[0, 0, :, :] * fstress11 + fgamma0[0, 1, :, :] * fstress22 + 2 * fgamma0[0, 2, :, :] * fstress12)
        fstrain22 = fstrain22 + (fgamma0[1, 0, :, :] * fstress11 + fgamma0[1, 1, :, :] * fstress22 + 2 * fgamma0[1, 2, :, :] * fstress12)
        fstrain12 = fstrain12 + (fgamma0[2, 0, :, :] * fstress11 + fgamma0[2, 1, :, :] * fstress22 + 2 * fgamma0[2, 2, :, :] * fstress12)
        fstrain11[0, 0] = Nx * Ny * E11_avg
        fstrain22[0, 0] = Nx * Ny * E22_avg
        fstrain12[0, 0] = Nx * Ny * E12_avg

        E11 = fft.ifft2(fstrain11).real  # Epsilon_11
        E22 = fft.ifft2(fstrain22).real  # Epsilon_22
        E12 = fft.ifft2(fstrain12).real  # 2*Epsilon_12

        S11 = C[0, 0, :, :] * E11 + C[0, 1, :, :] * E22 + 2 * C[0, 2, :, :] * E12
        S22 = C[1, 0, :, :] * E11 + C[1, 1, :, :] * E22 + 2 * C[1, 2, :, :] * E12
        S12 = C[2, 0, :, :] * E11 + C[2, 1, :, :] * E22 + 2 * C[2, 2, :, :] * E12
    # ++++++++++++++++++++++++++ END OF ALGORITHM +++++++++++++++++++++++++++++++++++++++++++++ #
    return S11, S22, S12, E11, E22, E12


def solve_micro2D():
    t = time.time()
    Lx, Ly = (2*pi, 2*pi)
    Nx, Ny = (2**8, 2**8)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # MATERIAL PARAMETERS
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    lamda = (1, 2)
    mu = (1, 2)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    CPhase = setupMaterialPhase(lamda, mu)
    ax, bx, xv, yv, x, y, kxv, kyv, xi1, xi2 = setupGrid(Lx, Ly, Nx, Ny)

    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Serious bug may appear here
    # Be careful, here please of index X and index Y with the coordinate corresponding
    # The y index will be corresponding to the X coordinate
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    C = np.zeros([3, 3, Nx, Ny])
    for m, valM in enumerate(yv):
        for n, valN in enumerate(xv):
            if (xv[n] < ax + Lx/4) or (xv[n] > bx - Lx/4):
                C[:, :, m, n] = copy.copy(CPhase['1'])
            else:
                C[:, :, m, n] = copy.copy(CPhase['2'])

    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Computing GREEN Operator
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    mu0 = mean(mu)
    lamda0 = mean(lamda)
    fgamma0 = computeGreenOperator(Nx, Ny, lamda0, mu0, xi1, xi2)
  
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Prescribed Strains
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    E11_avg = 1.0/100
    E22_avg = 2.0/100
    E12_avg = 0.0
    E_avg = (E11_avg, E22_avg, E12_avg)

    E11 = np.ones([Nx, Ny])
    E22 = np.ones([Nx, Ny])
    E12 = np.ones([Nx, Ny])

    S11 = np.ones([Nx, Ny])
    S22 = np.ones([Nx, Ny])
    S12 = np.ones([Nx, Ny])

    E11[:, :] = E11_avg  # Epsilon_11
    E22[:, :] = E22_avg  # Epsilon_22
    E12[:, :] = E12_avg  # 2*Epsilon_12 - Engineering strain

    S11 = C[0, 0, :, :] * E11 + C[0, 1, :, :] * E22 + 2 * C[0, 2, :, :] * E12
    S22 = C[1, 0, :, :] * E11 + C[1, 1, :, :] * E22 + 2 * C[1, 2, :, :] * E12
    S12 = C[2, 0, :, :] * E11 + C[2, 1, :, :] * E22 + 2 * C[2, 2, :, :] * E12

    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Fixed Points Algorithm to solve Lippmann-Schwinger Equ.
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    S11, S22, S12, E11, E22, E12 = executeFixedPointMethod(fgamma0, S11, S22, S12, E11, E22, E12, C, Nx, Ny, E_avg)
    print(time.time() - t)
    return x, y, S11, S22, S12, E11, E22, E12



if __name__ == '__main__':
    x, y, S11, S22, S12, E11, E22, E12 = solve_micro2D()
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Plotting & Validating the results
    # PLOT 3D with mplot3d
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    fig = plt.figure(figsize=plt.figaspect(0.5))
    ax = fig.add_subplot(3, 1, 1, projection='3d')
    ax.plot_surface(x, y, E11, rstride=1, cstride=1, cmap=cm.coolwarm)
    ax = fig.add_subplot(3, 1, 2, projection='3d')
    ax.plot_surface(x, y, E22, rstride=1, cstride=1, cmap=cm.coolwarm)
    ax = fig.add_subplot(3, 1, 3, projection='3d')
    ax.plot_surface(x, y, E12, rstride=1, cstride=1, cmap=cm.coolwarm)
    plt.show()
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # surf = mlab.surf(x, y, strain[0, :, :], warp_scale="auto")
    # mlab.show()
