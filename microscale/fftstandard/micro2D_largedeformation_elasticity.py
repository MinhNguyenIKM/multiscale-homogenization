#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Wed Feb 28 14:48:50 2018

@author: minh.nguyen@ikm.uni-hannover.de
Purpose: Homogenization based FFT for a microscopic structure in nonlinear material within finite strain
"""

import numpy as np
from numpy import pi, sqrt, square, mean, power, zeros
from numpy.linalg import norm
import scipy.fftpack as fft
import time
from numpy.linalg import tensorinv as tsinv
import copy
from matplotlib import pyplot as plt
from matplotlib import cm
from mpl_toolkits.mplot3d import Axes3D
# from mayavi import mlab
import itertools  # To avoid parent-child loop

dim = 2
phase_number = 2
Lx, Ly = (2 * pi, 2 * pi)
Nx, Ny = (2 ** 8, 2 ** 8)

trans2 = lambda A2   : np.einsum('ijxyz          ->jixyz  ',A2)
trans4 = lambda A4   : np.einsum('ijklxyz          ->lkjixyz  ', A4)
ddot42 = lambda A4, B2: np.einsum('ijklxy,lkxy->ijxy', A4, B2)
ddot44 = lambda A4, B4: np.einsum('ijmnxy,nmklxy->ijklxy', A4, B4)
dot141 = lambda C1, A4, B1: np.einsum('ixy,ijkxy->jkxy', C1, np.einsum('ijklxy,lxy->ijkxy', A4, B1))
dot242 = lambda C2, A4, B2: np.einsum('imxy,mjklxy->ijklxy', C2, np.einsum('mjknxy, nlxy -> mjklxy', A4, B2))
dyad22 = lambda A2, B2: np.einsum('ijxy,klxy->ijklxy', A2, B2)
dyad121 = lambda C1, A2, B1: np.einsum('ixy,jklxy->ijklxy', C1, np.einsum('jkxy,lxy->jklxy', A2, B1))


# identity tensor
identity = np.eye(dim)
I2 = np.einsum('ij,xy', identity, np.ones([Nx, Ny]))
I4rt = np.einsum('ijkl,xy->ijklxy', np.einsum('ik,jl', identity, identity), np.ones([Nx, Ny]))
I4 = np.einsum('ijkl,xy->ijklxy', np.einsum('il,jk', identity, identity), np.ones([Nx, Ny]))
II = dyad22(I2, I2)


def cal_effective_stiffness_linear(strain_macro):
    x, y, S11, S22, S12, E11, E22, E12 = solve_micro2D()
    C_effective = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]  # Pseduo value for effective
    return C_effective


def homogenize_microstructure(strain_macro):
    C_effective = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]  # Pseduo value for effective
    stress_homogenized = [0.5, 0.5, 0.5]  # Pseduo value for stress
    return C_effective, stress_homogenized


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


def get_P(mu, beta, F):
    # Neo-Hookean free energy
    detF = F[0, 0, :, :] * F[1, 1, :, :] - F[0, 1, :, :] * F[1, 0, :, :]
    invFT = np.zeros([dim, dim, Nx, Ny])
    for x in range(Nx):
        for y in range(Ny):
            invFT[:, :, x, y] = np.linalg.inv(F[:, :, x, y]).T
    P = np.zeros([dim, dim, Nx, Ny])
    for i, j in itertools.product(range(dim), repeat=2):
        P[i, j, :, :] = mu * F[i, j, :, :] - mu * power(detF, -beta) * invFT[i, j, :, :]
    return P


def get_C(mu, beta, F):
    # Neo-Hookean free energy
    delta = np.eye(dim)
    detF = F[0, 0, :, :] * F[1, 1, :, :] - F[0, 1, :, :] * F[1, 0, :, :]
    invFT = np.zeros([dim, dim, Nx, Ny])
    for x in range(Nx):
        for y in range(Ny):
            invFT[:, :, x, y] = np.linalg.inv(F[:, :, x, y]).T
    C = np.zeros([dim, dim, dim, dim, Nx, Ny])
    for i, j, k, l in itertools.product(range(dim), repeat=4):
        C[i, j, k, l, :, :] = mu * delta[i, k] * delta[j, l] + mu * power(detF, -beta) \
                              * (beta * invFT[i, j, :, :] * invFT[k, l, :, :] + invFT[i, l, :, :] * invFT[k, j, :, :])
    return C


def get_C0(lam, mu):
    # ISOTROPIC LINEAR MATERIAL STIFFNESS
    C0 = lam * II + mu * (I4 + I4rt)
    # C0 = II
    return C0


def computeGreenOperator(C0, xi1, xi2):
    xi = np.zeros([2, Nx, Ny])
    xi[0, :, :] = np.copy(xi1)
    xi[1, :, :] = np.copy(xi2)
    # Assign 1 so that xi != 0 to avoid singularity
    xi[0, :, 0] = 1
    xi[1, 0, :] = 1
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Computing GREEN Operator
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    f_gamma0 = np.zeros([dim, dim, dim, dim, Nx, Ny])
    A = np.zeros([dim, dim, Nx, Ny])
    invAT = np.zeros([dim, dim, Nx, Ny])
    for i, j, k, l in itertools.product(range(dim), repeat=4):
        A[k, i, :, :] = xi[l, :, :] * C0[l, k, i, j, :, :] * xi[j, :, :]
    for x in range(Nx):
        for y in range(Ny):
            invAT[:, :, x, y] = np.transpose(np.linalg.inv(A[:, :, x, y]))
    for i, j, k, l in itertools.product(range(dim), repeat=4):
        f_gamma0[i, j, k, l, :, :] = -xi[j] * invAT[k, i, :, :] * xi[l]
    f_gamma0[:, :, :, :, 0, 0] = 0
    return f_gamma0


def executeFixedPointMethod(f_gamma0, mu, beta, Nx, Ny, F_avg, xi1, xi2):
    xi = np.array([xi1, xi2])
    F = np.zeros([dim, dim, Nx, Ny])
    # Initial Strain
    for i, j, in itertools.product(range(dim), repeat=2):
        F[i, j, :, :] = F_avg[i, j]
    # Initial Stress
    P = get_P(mu, beta, F)
    # S = ddot42(C, E)
    # # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Fixed Points Algorithm to solve Lippmman-Schwinger Equation.
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    maxIteration1 = 200
    iter1 = 0
    TOL = 1e-6
    while iter1 < maxIteration1:
        # FFT of FIRST PIOLA KIRCHHOFF STRESS
        f_P = fft.fft2(P)
        # Checking Convergence
        if iter1 > -1:
            error = norm(xi[0] * f_P[0, 0, :, :] + xi[1] * f_P[0, 1, :, :])
            error = error / norm([f_P[0, 0, 0, 0], f_P[0, 1, 0, 0]])
            print(iter1)
            print(error.real)
            # error = sqrt(1.0 / (Nx * Ny) * np.sum((f_S[0, 0, :, :] * xi[0] + f_S[0, 1, :, :] * xi[1]) ** 2 + \
            #                                       (f_S[1, 0, :, :] * xi[0] + f_S[1, 1, :, :] * xi[1]) ** 2)) / np.linalg.norm(f_S[:, :, 0, 0])
            if error.real < TOL:
                print("error")
                print(error.real)
                break
        # SOLVE THE EQUILIBRIUM
        f_F = ddot42(f_gamma0, f_P) + fft.fft2(F)
        # Boundary condition
        f_F[:, :, 0, 0] = Nx * Ny * F_avg[:, :]
        # Update solution for Strain
        F = fft.ifft2(f_F).real
        # Update solution for Stress
        P = get_P(mu, beta, F)
        iter1 += 1
        # ++++++++++++++++++++++++++ END OF ALGORITHM +++++++++++++++++++++++++++++++++++++++++++++ #
    return P, F


def cal_average_stress_strain(P, F, hx, hy, ax, bx, ay, by):
    vol = (bx - ax) * (by - ay)
    P_macro = zeros([dim, dim])
    F_macro = zeros([dim, dim])
    for i, j in itertools.product(range(dim), repeat=2):
        P_macro[i, j] = 1.0 / vol * hx * hy * np.sum(P[i, j, :, :])
        F_macro[i, j] = 1.0 / vol * hx * hy * np.sum(F[i, j, :, :])
    return P_macro, F_macro


def cal_tangent_effective_moduli(f_gamma0, mu, beta, F, C0, Nx, Ny, x, y, hx, hy, ax, bx, ay, by, xi1, xi2, P_homogenized, F_homogenized):
    xi = np.array([xi1, xi2])
    alpha = zeros((dim, dim, dim, dim, Nx, Ny))
    C = get_C(mu, beta, F)
    C_delta = C - C0
    C_consistent_tangent = zeros((dim, dim, dim, dim))
    vol = (bx - ax) * (by - ay)
    # ----------------------------------------------------------------------------
    #   Part I: Calculate \frac{\partial \tilde{\F}}{\partial \bar {\F}}
    # ----------------------------------------------------------------------------
    TOL = 1e-6
    maxIter2 = 10
    iter2 = 0
    while iter2 < maxIter2:
        f_alpha = ddot44(f_gamma0, fft.fft2(C_delta + ddot44(C_delta, alpha)))
        # Boundary condition
        f_alpha[:, :, :, :, 0, 0] = 0
        alpha = fft.ifft2(f_alpha).real

        # CHECK CONVERGENCE
        if iter2 > -1:
            # Calculate consistent tangent stiffness
            beta = ddot44(C, (I4 + alpha))
            for i, j, k, l in itertools.product(range(dim), repeat=4):
                C_consistent_tangent[i, j, k, l] = 1.0 / vol * hx * hy * np.sum(beta[i, j, k, l, :, :])
            # S = np.einsum('ijkl,lk->ij', C_consistent_tangent, E_homogenized)
            # error = norm(S - S_homogenized) / norm(S_homogenized)
            # if error.real < TOL:
            #     print("error")
            #     print(error.real)
            #     break

        iter2 += 1

    # ----------------------------------------------------------------------------
    #   Part II: Calculate consistent tangent stiffness based on
    # \frac{\partial \tilde{\F}}{\partial \bar {\F}}
    # ----------------------------------------------------------------------------
    # C_consistent_tangent = zeros((dim, dim, dim, dim))
    # vol = (bx - ax) * (by - ay)
    # beta = ddot44(C, (I4 + alpha))
    # for i, j, k, l in itertools.product(range(dim), repeat=4):
    #     C_consistent_tangent[i, j, k, l] = 1.0 / vol * hx * hy * np.sum(beta[i, j, k, l, :, :])
    return C_consistent_tangent


def solve_micro2D():
    t = time.time()
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # MATERIAL PARAMETERS
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    lamda = np.array([1, 2], dtype=float)
    mu = np.array([1, 2], dtype=float)
    nuy = lamda / (2 * lamda + 2 * mu)
    beta = 2 * nuy / (1 - 2 * nuy)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # CPhase = setupMaterialPhase(lamda, mu)
    hx, hy, ax, bx, ay, by, xv, yv, x, y, kxv, kyv, xi1, xi2 = setupGrid(Lx, Ly, Nx, Ny)

    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Serious bug may appear here
    # Be careful, here please of index X and index Y with the coordinate corresponding
    # The y index will be corresponding to the X coordinate
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Set up constituent materials
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # C = np.zeros([dim, dim, dim, dim, Nx, Ny])
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Set up reference material
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #

    # CRef = setupMaterialPhase((lamda0, lamda0), (mu0, mu0))
    # C0 = np.zeros([dim, dim, dim, dim, Nx, Ny])
    phase = 2 * np.ones([Nx, Ny])
    phase[:, x[1, :] < ax + Lx / 4.0] = 1
    phase[:, x[1, :] > bx - Lx / 4.0] = 1
    beta_phase = zeros([Nx, Ny])
    mu_phase = zeros([Nx, Ny])
    beta_phase[np.where(phase == 1)[0], np.where(phase == 1)[1]] = beta[0]
    beta_phase[np.where(phase == 2)[0], np.where(phase == 2)[1]] = beta[1]
    mu_phase[np.where(phase == 1)[0], np.where(phase == 1)[1]] = mu[0]
    mu_phase[np.where(phase == 2)[0], np.where(phase == 2)[1]] = mu[1]

    mu0 = 100000
    lamda0 = 100000
    lamda0_phase = zeros([Nx, Ny])
    mu0_phase = zeros([Nx, Ny])
    lamda0_phase[:, :] = lamda0
    mu0_phase[:, :] = mu0

    C0 = get_C0(lamda0_phase, mu0_phase)
    # C = get_C(lambda_phase, mu_phase)
    # for i, j, k, l in itertools.product(range(dim), repeat=4):
    #     C[i, j, k, l, np.where(phase == 1)[0], np.where(phase == 1)[1]] = CPhase[0, i, j, k, l]
    #     C[i, j, k, l, np.where(phase == 2)[0], np.where(phase == 2)[1]] = CPhase[1, i, j, k, l]
    #     C0[i, j, k, l, np.where(phase == 1)[0], np.where(phase == 1)[1]] = CRef[0, i, j, k, l]
    #     C0[i, j, k, l, np.where(phase == 2)[0], np.where(phase == 2)[1]] = CRef[1, i, j, k, l]
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Computing GREEN Operator
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    f_gamma0 = computeGreenOperator(C0, xi1, xi2)
    print(time.time() - t)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Prescribed Strains
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    E11_avg = 1.0 / 100
    E22_avg = 2.0 / 100
    E12_avg = 0.0
    F_avg = np.array([[1.2, 0.1], [0.15, 1]])
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Fixed Points Algorithm to solve Lippmann-Schwinger Equ.
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    P, F = executeFixedPointMethod(f_gamma0, mu_phase, beta_phase, Nx, Ny, F_avg, xi1, xi2)
    print(time.time() - t)
    P_homogenized, F_homogenized = cal_average_stress_strain(P, F, hx, hy, ax, bx, ay, by)
    C_homogenized = cal_tangent_effective_moduli(f_gamma0, mu_phase, beta_phase, F, C0, Nx, Ny, xv, yv, hx, hy, ax, bx, ay, by, xi1, xi2, P_homogenized, F_homogenized)
    # C_homogenized_matrix = transform_4thTensor_to_2ndTensor(C_homogenized)
    print(time.time() - t)
    return x, y, P, F, P_homogenized, F_homogenized, C_homogenized


# def transform_4thTensor_to_2ndTensor(fourth):
#     second = np.zeros([3, 3])
#     second[0, 0] = fourth[0, 0, 0, 0]
#     second[0, 1] = fourth[0, 0, 1, 1]
#     second[0, 2] = fourth[0, 0, 0, 1]
#     second[1, 0] = fourth[1, 1, 0, 0]
#     second[1, 1] = fourth[1, 1, 1, 1]
#     second[1, 2] = fourth[1, 1, 0, 1]
#     second[2, 0] = fourth[0, 1, 0, 0]
#     second[2, 1] = fourth[0, 1, 1, 1]
#     second[2, 2] = fourth[0, 1, 0, 1]
#     return second


if __name__ == '__main__':
    x, y, stress_micro, strain_micro, stress_average, strain_average, C_effective_tangent = solve_micro2D()
    # x, y, stress_micro, strain_micro = solve_micro2D()
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Plotting & Validating the results
    # PLOT 3D with mplot3d
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    fig = plt.figure(figsize=plt.figaspect(0.5))
    ax = fig.add_subplot(3, 1, 1, projection='3d')
    ax.plot_surface(x, y, strain_micro[0, 0], rstride=1, cstride=1, cmap=cm.coolwarm)
    ax = fig.add_subplot(3, 1, 2, projection='3d')
    ax.plot_surface(x, y, strain_micro[1, 1], rstride=1, cstride=1, cmap=cm.coolwarm)
    ax = fig.add_subplot(3, 1, 3, projection='3d')
    ax.plot_surface(x, y, strain_micro[0, 1], rstride=1, cstride=1, cmap=cm.coolwarm)
    plt.show()
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # surf = mlab.surf(x, y, strain[0, :, :], warp_scale="auto")
    # mlab.show()
