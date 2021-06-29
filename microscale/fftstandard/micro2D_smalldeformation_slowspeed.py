import numpy as np
from numpy import pi, sqrt, square, mean
import scipy.fftpack as fft
import time
import copy
from matplotlib import pyplot as plt
from matplotlib import cm
from mpl_toolkits.mplot3d import Axes3D
#from mayavi import mlab


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
    kxv2 = np.arange(-Nx/2+1, -1 + 1, 1) # in Matlab --> -Nx/2+1:-1
    kxv = scaleX * np.concatenate((kxv1, kxv2))
    kyv1 = np.arange(0, Ny/2 + 1, 1)  # in Matlab --> 0:Ny/2
    kyv2 = np.arange(-Ny/2+1, -1 + 1, 1)  # in Matlab --> -Ny/2+1:-1
    kyv = scaleY * np.concatenate((kyv1, kyv2))
    k1, k2 = np.meshgrid(kxv, kyv)
    return ax, bx, xv, yv, x, y, kxv, kyv, k1, k2


def computeGreenOperator(Nx, Ny, lamda0, mu0, xi1, xi2):
    normXi = sqrt(xi1*xi1 + xi2*xi2)
    K0 = np.zeros([2, 2, Nx, Ny])
    normXi[0][0] = 1.0 # any value to avoid the singular in matrix N0 when taking into account the inverse of K0
    K0[0, 0, :, :] = (lamda0 + mu0) * square(xi1) + mu0*square(normXi)
    K0[0, 1, :, :] = (lamda0 + mu0) * xi1 * xi2
    K0[1, 0, :, :] = K0[0, 1, :, :]
    K0[1, 1, :, :] = (lamda0 + mu0) * square(xi2) + mu0*square(normXi)
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
    fgamma0_1212 = -1.0 / 4.0 * (N0[0, 0, :, :] * xi2 * xi2 + N0[1, 0, :, :] * xi1 * xi2 + N0[0, 1, :, :] * xi2 * xi1 + N0[1, 1, :, :] * xi1 * xi1)
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

def executeFixedPointMethod(fgamma0, stress, strain, C, Nx, Ny, E_avg):
    E11_avg = E_avg[0]
    E22_avg = E_avg[1]
    E12_avg = E_avg[2]
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Fixed Points Algorithm to solve Lippman-Schwinger Equ.
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    maxIteration = 200
    # ---------- This part of code is NOT CORRECT for 2D ------------------------------
    # 1. FULL FIELD SOLUTION for FFT, so don't have to loop over each element
    # 2. This is kinda Finite Element.
    # ---------------------------------------------------------------------------------
    # for i in range(0, maxIteration, 1):
    #     for idX, valXi1 in enumerate(xi1):
    #         for idY, valXi2 in enumerate(xi2):
    #             fstress = fft.rfft(stress[:, idX, idY])
    #             fstrain = fft.rfft(strain[:, idX, idY])
    #             # Convergence test
    #
    #             if idX == 0 and idY == 0:
    #                 fstrain[0] = E11_avg
    #                 fstrain[1] = E22_avg
    #                 fstrain[2] = 2*E12_avg
    #             else:
    #                 fstrain = fstrain + np.inner(fgamma0[:, :, idX, idY], fstress)
    #             strain[:, idX, idY] = fft.irfft(fstrain)
    #             stress[:, idX, idY] = np.inner(C[:, :, idX, idY], strain[:, idX, idY])

    # ----------- RE-CODE for 2D ------------------------------------------------------
    fstress = np.zeros([3, Nx, Ny], dtype=complex)
    fstrain = np.zeros([3, Nx, Ny], dtype=complex)
    for i in range(0, maxIteration, 1):
        fstress[0, :, :] = fft.fft2(stress[0, :, :])  # Sigma_11
        fstress[1, :, :] = fft.fft2(stress[1, :, :])  # Sigma_22
        fstress[2, :, :] = fft.fft2(stress[2, :, :])  # Sigma_12

        fstrain[0, :, :] = fft.fft2(strain[0, :, :])  # Epsilon_11
        fstrain[1, :, :] = fft.fft2(strain[1, :, :])  # Epsilon_22
        fstrain[2, :, :] = fft.fft2(strain[2, :, :])  # 2*Epsilon_12
        for m in range(0, Ny, 1):
            for n in range(0, Nx, 1):
                if m == 0 and n == 0:
                    fstrain[0, m, n] = (Nx * Ny) * E11_avg  # Epsilon_11
                    fstrain[1, m, n] = (Nx * Ny) * E22_avg  # Epsilon_22
                    fstrain[2, m, n] = (Nx * Ny) * (2 * E12_avg)  # 2*Epsilon_12
                else:
                    fstrain[:, m, n] = fstrain[:, m, n] + np.inner(fgamma0[:, :, m, n], fstress[:, m, n])

        strain[0, :, :] = fft.ifft2(fstrain[0, :, :]).real  # Epsilon_11
        strain[1, :, :] = fft.ifft2(fstrain[1, :, :]).real  # Epsilon_22
        strain[2, :, :] = fft.ifft2(fstrain[2, :, :]).real  # 2*Epsilon_12
        for m in range(0, Ny, 1):
            for n in range(0, Nx, 1):
                stress[:, m, n] = np.inner(C[:, :, m, n], strain[:, m, n]) 
    # ++++++++++++++++++++++++++ END OF ALGORITHM +++++++++++++++++++++++++++++++++++++++++++++ #
    return stress, strain
    

def main():
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
    strainInit = np.ones([3, Nx, Ny])
    stressInit = np.ones([3, Nx, Ny])
    strainInit[0, :, :] = E11_avg  # Epsilon_11
    strainInit[1, :, :] = E22_avg  # Epsilon_22
    strainInit[2, :, :] = 2 * E12_avg  # Epsilon_12 - Engineering strain
    for m in range(0, Ny, 1):
        for n in range(0, Nx, 1):
            stressInit[:, m, n] = np.inner(C[:, :, m, n], strainInit[:, m, n])

    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    # Fixed Points Algorithm to solve Lippman-Schwinger Equ.
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
    stress, strain = executeFixedPointMethod(fgamma0, stressInit, strainInit, C, Nx, Ny, E_avg)

    print(time.time() - t)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Plotting & Validating the results
    # PLOT 3D with mplot3d
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    fig = plt.figure(figsize=plt.figaspect(0.5))
    ax = fig.add_subplot(3, 1, 1, projection='3d')
    ax.plot_surface(x, y, strain[0, :, :], rstride=1, cstride=1, cmap=cm.coolwarm)
    ax = fig.add_subplot(3, 1, 2, projection='3d')
    ax.plot_surface(x, y, strain[1, :, :], rstride=1, cstride=1, cmap=cm.coolwarm)
    ax = fig.add_subplot(3, 1, 3, projection='3d')
    ax.plot_surface(x, y, strain[2, :, :]/2, rstride=1, cstride=1,  cmap=cm.coolwarm)
    plt.show()
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # surf = mlab.surf(x, y, strain[0, :, :], warp_scale="auto")
    # mlab.show()


if __name__ == '__main__':
    main()