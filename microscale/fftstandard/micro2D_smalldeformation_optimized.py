#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Wed Feb 28 14:48:50 2018

@author: minh.nguyen@ikm.uni-hannover.de
Purpose: FFT to homogenize 2-phase Laminate in 2D
"""
# -------------------------------------------------------------------------------------------
#                       CONVENTIONAL FFT Homogenization for small strain
#                       EVEN NUMBER
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
from util.micro2D_utility import transform_4thTensor_to_2ndTensor

dim = 2
phase_number = 2
Lx, Ly = (2 * pi, 2 * pi)
GRID = (2**8, 2**3)  # number of pixels/voxels (assumed equal for all directions)
Nx, Ny = (GRID[1], GRID[0])

ddot42 = lambda A4, B2: np.einsum('ijklxy,lkxy->ijxy', A4, B2)
ddot44 = lambda A4, B4: np.einsum('ijmnxy,nmklxy->ijklxy', A4, B4)
dyad22 = lambda A2, B2: np.einsum('ijxy,klxy->ijklxy', A2, B2)

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
    C_effective = np.array([[1, 0, 0], [0, 1, 0], [0, 0, 1]])  # Pseduo value for effective
    stress_homogenized = np.array([[0.02, 0.05], [0.05, 0.01]])  # Pseduo value for stress
    return C_effective, stress_homogenized


def setupGrid(Lx, Ly, Nx, Ny):
    ax, bx = (-Lx / 2, Lx / 2)
    ay, by = (-Ly / 2, Ly / 2)
    # scaleX, scaleY = ((bx - ax) / (2 * pi), (by - ay) / (2 * pi))
    scaleX, scaleY = ((2 * pi) / (bx - ax), (2 * pi) / (by - ay))
    hx, hy = ((bx - ax) / Nx, (by - ay) / Ny)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # SET UP GRID
    # SET UP GRID in REAL SPACE
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    xv = np.arange(ax + hx, bx + hx, hx)  # in Matlab --> a+h:h:b
    yv = np.arange(ay + hy, by + hy, hy)
    x, y = np.meshgrid(yv, xv)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # SET UP GRID in FOURIER SPACE
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    kxv1 = np.arange(0, Nx / 2 + 1, 1)  # in Matlab --> 0:Nx/2
    kxv2 = np.arange(-Nx / 2 + 1, -1 + 1, 1)  # in Matlab --> -Nx/2+1:-1
    kxv = scaleX * np.concatenate((kxv1, kxv2))
    kyv1 = np.arange(0, Ny / 2 + 1, 1)  # in Matlab --> 0:Ny/2
    kyv2 = np.arange(-Ny / 2 + 1, -1 + 1, 1)  # in Matlab --> -Ny/2+1:-1
    kyv = scaleY * np.concatenate((kyv1, kyv2))
    k1, k2 = np.meshgrid(kyv, kxv)
    return hx, hy, ax, bx, ay, by, xv, yv, x, y, kxv, kyv, k1, k2


def get_C(lam, mu):
    # ISOTROPIC LINEAR MATERIAL STIFFNESS
    C4 = lam * II + mu * (I4 + I4rt)
    return C4


# ------------------- PROBLEM DEFINITION / CONSTITIVE MODEL -------------------
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
    maxIteration1 = 200
    iter1 = 0
    TOL = 1e-6
    while iter1 < maxIteration1:
        # FFT of Stress
        f_S = fft.fft2(S)
        # Checking Convergence
        if iter1 > -1 and norm([f_S[0, 0, 0, 0], f_S[0, 1, 0, 0]]) != 0:
            error = norm(xi[0] * f_S[0, 0, :, :] + xi[1] * f_S[0, 1, :, :])
            error = error / norm([f_S[0, 0, 0, 0], f_S[0, 1, 0, 0]])

            # error = sqrt(1.0 / (Nx * Ny) * np.sum((f_S[0, 0, :, :] * xi[0] + f_S[0, 1, :, :] * xi[1]) ** 2 + \
            #                                       (f_S[1, 0, :, :] * xi[0] + f_S[1, 1, :, :] * xi[1]) ** 2)) / np.linalg.norm(f_S[:, :, 0, 0])
            if error.real < TOL:
                print('Step ' + str(iter1) + ' - Convergence of fixed-point method : ' + str(error.real))
                break
        f_E = ddot42(f_gamma0, f_S) + fft.fft2(E)
        # Boundary condition
        f_E[:, :, 0, 0] = Nx * Ny * E_avg[:, :]
        # Update solution for Strain
        E = fft.ifft2(f_E).real
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


def cal_tangent_effective_moduli(f_gamma0, C, C0, Nx, Ny, x, y, hx, hy, ax, bx, ay, by, xi1, xi2, S_homogenized, E_homogenized):
    xi = np.array([xi1, xi2])
    alpha = zeros((dim, dim, dim, dim, Nx, Ny))
    C_delta = C - C0
    C_consistent_tangent = zeros((dim, dim, dim, dim))
    vol = (bx - ax) * (by - ay)
    # ----------------------------------------------------------------------------
    #   Part I: Calculate \frac{\partial \tilde{\epsilon}}{\partial \bar {\epsilon}}
    # ----------------------------------------------------------------------------
    TOL = 1e-6
    maxIter2 = 10
    iter2 = 1
    while iter2 < maxIter2:
        f_alpha = ddot44(f_gamma0, fft.fft2(C_delta + ddot44(C_delta, alpha)))
        # Boundary condition
        f_alpha[:, :, :, :, 0, 0] = 0
        alpha = fft.ifft2(f_alpha).real

        # CHECK CONVERGENCE
        if iter2 > 0 and norm(S_homogenized) != 0:
            # Calculate consistent tangent stiffness
            beta = ddot44(C, (I4 + alpha))
            for i, j, k, l in itertools.product(range(dim), repeat=4):
                C_consistent_tangent[i, j, k, l] = 1.0 / vol * hx * hy * np.sum(beta[i, j, k, l, :, :])
            S = np.einsum('ijkl,lk->ij', C_consistent_tangent, E_homogenized)
            error = norm(S - S_homogenized) / norm(S_homogenized)
            if error.real < TOL:
                print('Step ' + str(iter2) + ' - Convergence of tangent moduli : ' + str(error.real))
                break

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


def solve_micro2D(mat, macro_strain):
    # E = np.array([mat.p1.E, mat.p2.E])
    # nu = np.array([mat.p1.nu, mat.p2.nu])
    # lamda = (E * nu) / ((1 + nu) * (1 - 2 * nu))
    # mu = E / (2 * (1 + nu))

    t = time.time()

    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # MATERIAL PARAMETERS
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    lamda = (1, 2)
    mu = (1, 2)
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
    mu0 = mean(mu)
    lamda0 = mean(lamda)
    # CRef = setupMaterialPhase((lamda0, lamda0), (mu0, mu0))
    # C0 = np.zeros([dim, dim, dim, dim, Nx, Ny])
    phase = 2 * np.ones([Nx, Ny])
    phase[:, x[1, :] < ax + Lx / 4.0] = 1
    phase[:, x[1, :] > bx - Lx / 4.0] = 1
    lambda_phase = zeros([Nx, Ny])
    mu_phase = zeros([Nx, Ny])
    lambda_phase[np.where(phase == 1)[0], np.where(phase == 1)[1]] = lamda[0]
    lambda_phase[np.where(phase == 2)[0], np.where(phase == 2)[1]] = lamda[1]
    mu_phase[np.where(phase == 1)[0], np.where(phase == 1)[1]] = mu[0]
    mu_phase[np.where(phase == 2)[0], np.where(phase == 2)[1]] = mu[1]
    lambda0_phase = zeros([Nx, Ny])
    mu0_phase = zeros([Nx, Ny])
    lambda0_phase[:, :] = lamda0
    mu0_phase[:, :] = mu0
    C = get_C(lambda_phase, mu_phase)
    C0 = get_C(lambda0_phase, mu0_phase)
    # C = get_C(lambda_phase, mu_phase)
    # for i, j, k, l in itertools.product(range(dim), repeat=4):
    #     C[i, j, k, l, np.where(phase == 1)[0], np.where(phase == 1)[1]] = CPhase[0, i, j, k, l]
    #     C[i, j, k, l, np.where(phase == 2)[0], np.where(phase == 2)[1]] = CPhase[1, i, j, k, l]
    #     C0[i, j, k, l, np.where(phase == 1)[0], np.where(phase == 1)[1]] = CRef[0, i, j, k, l]
    #     C0[i, j, k, l, np.where(phase == 2)[0], np.where(phase == 2)[1]] = CRef[1, i, j, k, l]
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
    C_homogenized = cal_tangent_effective_moduli(f_gamma0, C, C0, Nx, Ny, xv, yv, hx, hy, ax, bx, ay, by, xi1, xi2, stress_homogenized, strain_homogenized)
    C_homogenized_matrix = transform_4thTensor_to_2ndTensor(C_homogenized)
    print("Completed whole program in : ", (time.time() - t))
    return x, y, stress, strain, stress_homogenized, strain_homogenized, C_homogenized_matrix


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
    macro_strain = [1.0/100, 2.0/100, 0.02]
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
