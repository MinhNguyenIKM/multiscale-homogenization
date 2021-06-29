# ---------------------------------------------------------------------------------
# Solve MICROSCOPIC PROBLEM for 1D linear and nonlinear by FFT method
# minh.nguyen@ikm.uni-hannover.de
# ---------------------------------------------------------------------------------

import numpy as np
import scipy.fftpack as fft
from numpy import *


def cal_effective_stiffness_1d_linear(strain_avg):
    x, k, lamda, strain, stress, \
    strain_macro, stress_macro, Ceffective, energy_macro = solve_micro_1d_linear_fft(strain_avg[0])
    return Ceffective


def cal_effective_stiffness_1d_nonlinear(strain_avg):
    strain_avg = strain_avg[0][0]
    # strain_avg = 0.025
    x, k, lamda, strain, stress, \
    strain_macro, stress_macro, Ceffective, energy_macro = solve_micro_1d_nonlinear_fft(strain_avg)
    return stress_macro, Ceffective


def C(k, x):
    return 3.0 / 2.0 + np.sin(2.0 * np.pi * k * x)


def constitutive_law(C_x, eps):
    return C_x * (np.sqrt(1 + eps) - 1)


def solve_micro_1d_linear_fft(strain_avg):
    omega = 10
    maxIteration = 1000
    TOL = 1e-11
    # setting micro scale properties
    lamda = 1.0 / omega
    #
    a = -lamda/2.0
    b =  lamda/2.0
    vol = b - a
    # Number of grid
    N = 2 ** 8
    # The distance between grid points
    h = (b - a) / N
    # Scale
    scale = (b - a) / (2 * pi)
    # Coordinates of collocation points OR Coordinates of pixel(2D) | voxel(3D)
    x = np.arange(a+h, b+h, h)  # in Matlab --> a+h:h:b
    # The discrete frequencies (wave number)
    # Note: We have to rearrange the sequence as it must be compatible with the sequence in Python's FFT definition
    k1 = np.arange(0, N/2 + 1, 1)  # in MATLAB 0:1:N/2
    k2 = np.arange(-N/2 + 1, -1 + 1, 1)  # in MATLAB -N/2+1:1:-1
    k = np.concatenate((k1, k2)) / scale

    DOF = len(x)
    # Initialization, be careful, DO NOT ASSIGN THE POINTER OF AN ADDRESS. Use slice technique
    strain = strain_avg * np.ones(DOF)
    strainAVG = strain
    C_x = C(omega, x)
    stress = C_x * strain
    stressAVG = stress
    C0 = C_x[0]
    fGamma = -1.0 / C0
    for i in range(0, maxIteration, 1):
        # print ("Iteration %d" % i)
        fstress = fft.fft(stress)
        fstrain = fft.fft(strain)
        # Convergence test
        if np.linalg.norm(fstress[0]) != 0:
            err = N * np.linalg.norm(np.inner(k, fstress)) / np.linalg.norm(fstress[0])
            if err < TOL:
                break
            # print(err)
        fstrain = fstrain + fGamma * fstress
        strainAVG = 1.0 / vol * h * np.sum(strain)
        fstrain[0] = N * strain_avg
        #fstrain[0] = N * strain_avg  # Please, note that we have factor N here in the form of Fourier Transform of strain
        strain = fft.ifft(fstrain).real
        stress = C(omega, x) * strain  # it is not matrix x matrix. It is Each element x Each element

    # Density energy function
    energy = 1.0/2.0 * stress * strain
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # SOLUTION FOR FLUCTUATIVE PART
    # A paper in Stuttgart Group Research has discovered that
    # Another way is that we can use Finite Difference Method
    # No matter what method, legacy method or Stuttgart's method, the solver is not important in this scope
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    alpha = np.zeros(N)
    delta_C = C_x - C0
    maxIter2 = 50
    for iter in range(0, maxIter2, 1):
        # Updated solution in Fourier Space
        fDelta_C = fft.fft(delta_C)
        fDelAlpha = fft.fft(delta_C * alpha)
        fAlpha = np.inner(fGamma, fDelta_C) + np.inner(fGamma, fDelAlpha)
        fAlpha[0] = 0
        # Update solution in physical space
        alpha = fft.ifft(fAlpha).real
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Computation of Effective Stiffness
    beta = C_x * (1 + alpha)
    # Compute macroscale strain and macroscale stress
    stress_macro = 1.0 / vol * (np.trapz(stress, x=x) + h * np.mean([stress[0], stress[DOF-1]]))
    strain_macro = 1.0 / vol * (np.trapz(strain, x=x) + h * np.mean([strain[0], strain[DOF-1]]))
    energy_macro = 1.0 / vol * (np.trapz(energy, x=x) + h * np.mean([energy[0], energy[DOF-1]]))
    Ceffective = 1.0 / vol * (np.trapz(beta, x=x) + h * np.mean([beta[0], beta[DOF-1]]))
    return x, k, lamda, strain, stress, strain_macro, stress_macro, Ceffective, energy_macro


# ----------------------------------------------------------------------------------------------------
# Solving equilibrium equation (BVP) in micro scale problem
# ----------------------------------------------------------------------------------------------------
def solve_micro_1d_nonlinear_fft(strain_avg):
    omega = 10
    maxIteration = 1000
    TOL = 1e-11
    # setting micro scale properties
    lamda = 1.0 / omega
    #
    a = -lamda/2.0
    b =  lamda/2.0
    vol = b - a
    # Number of grid
    N = 2 ** 8
    # The distance between grid points
    h = (b - a) / N
    # Scale
    scale = (b - a) / (2 * pi)
    # Coordinates of collocation points OR Coordinates of pixel(2D) | voxel(3D)
    x = np.arange(a+h, b+h, h)  # in Matlab --> a+h:h:b
    # The discrete frequencies (wave number)
    # Note: We have to rearrange the sequence as it must be compatible with the sequence in Python's FFT definition
    k1 = np.arange(0, N/2 + 1, 1)  # in MATLAB 0:1:N/2
    k2 = np.arange(-N/2 + 1, -1 + 1, 1)  # in MATLAB -N/2+1:1:-1
    k = np.concatenate((k1, k2)) * scale

    DOF = len(x)
    # Initialization, be careful, DO NOT ASSIGN THE POINTER OF AN ADDRESS. Use slice technique
    strain = strain_avg * np.ones(DOF)
    strainAVG = strain
    C_x = C(omega, x)
    stress = constitutive_law(C_x, strain)
    C0 = np.max(C_x) + 1
    fGamma = -1.0 / C0
    for i in range(0, maxIteration, 1):
        # print ("Iteration %d" % i)
        fstress = fft.fft(stress)
        fstrain = fft.fft(strain)
        # Convergence test
        if np.linalg.norm(fstress[0]) != 0:
            err = N * np.linalg.norm(np.inner(k, fstress)) / np.linalg.norm(fstress[0])
            if err < TOL:
                break
            # print(err)
        fstrain = fstrain + fGamma * fstress
        #strainAVG = 1.0 / vol * h * np.sum(strain)
        fstrain[0] = N * strain_avg
        #fstrain[0] = N * strain_avg  # Please, note that we have factor N here in the form of Fourier Transform of strain
        strain = fft.ifft(fstrain).real
        stress = constitutive_law(C(omega, x), strain)  # it is not matrix x matrix. It is Each element x Each element

    # Density energy function
    energy = C(omega, x) * (2.0/3.0 * np.power(1 + strain, 3.0/2.0) - strain)
    C_tangent = C(omega, x) * 1.0 / (2 * np.sqrt(1 + strain))
    C_tangent_homo = 1.0 / vol * (np.trapz(C_tangent, x=x) + h * np.mean([C_tangent[0], C_tangent[DOF - 1]]))
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # SOLUTION FOR FLUCTUATIVE PART
    # A paper in Stuttgart Group Research has discovered that
    # Another way is that we can use Finite Difference Method
    # No matter what method, legacy method or Stuttgart's method, the solver is not important in this scope
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    alpha = np.zeros(N)
    dSigdEps = C(omega, x) / (2 * np.sqrt(1 + strain))
    delta_C = dSigdEps - C0
    maxIter2 = 50
    for iter in range(0, maxIter2, 1):
        # Updated solution in Fourier Space
        fDelta_C = fft.fft(delta_C)
        fDelAlpha = fft.fft(delta_C * alpha)
        fAlpha = np.inner(fGamma, fDelta_C) + np.inner(fGamma, fDelAlpha)
        fAlpha[0] = 0
        # Update solution in physical space
        alpha = fft.ifft(fAlpha).real
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Computation of Effective Stiffness
    beta = dSigdEps * (1 + alpha)
    # Compute macroscale strain and macroscale stress
    stress_macro = 1.0 / vol * (np.trapz(stress, x=x) + h * np.mean([stress[0], stress[DOF-1]]))
    strain_macro = 1.0 / vol * (np.trapz(strain, x=x) + h * np.mean([strain[0], strain[DOF-1]]))
    energy_macro = 1.0 / vol * (np.trapz(energy, x=x) + h * np.mean([energy[0], energy[DOF-1]]))
    Ceffective = 1.0 / vol * (np.trapz(beta, x=x) + h * np.mean([beta[0], beta[DOF-1]]))
    return x, k, lamda, strain, stress, strain_macro, stress_macro, Ceffective, energy_macro


if __name__ == '__main__':
    strain_macro = [[0.0]]
    print(cal_effective_stiffness_1d_nonlinear(strain_macro))