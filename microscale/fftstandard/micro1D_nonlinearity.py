import numpy as np
import scipy.fftpack as fft
import scipy
from numpy import pi, ones, sqrt, square
from matplotlib import pyplot as plt


def cal_effective_stiffness_default(strain_avg):
    strain_avg = strain_avg[0][0]
    strain_avg = 0.025
    avgStrain1, avgStress1 = solve_micro_1d_fft(strain_avg)
    avgStrain2, avgStress2 = solve_micro_1d_fft(strain_avg + 0.02)
    return (avgStress2 - avgStress1) / (avgStrain2 - avgStrain1)


def cal_effective_stiffness(strain_avg):
    strain_avg = strain_avg[0][0]
    # strain_avg = 0.025
    x, k, lamda, strain, stress, strain_macro, stress_macro, Ceffective, energy_macro = solve_micro_1d_nonlinear_fft(strain_avg)
    return stress_macro, Ceffective


def constitutive_law(C_x, eps):
    return C_x * (np.sqrt(1 + eps) - 1)


def C(k, x):
    return 3.0 / 2.0 + np.sin(2.0 * np.pi * k * x)


def solve_micro_1d_fft(strain_avg):
    omega = 10
    maxIteration = 1000
    TOL = 1e-10
    # setting micro scale properties
    lamda = 1.0 / omega
    #
    a = -lamda/2.0
    b = lamda/2.0
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
    k1 = np.arange(0, N/2 + 1, 1)  # in Matlab --> 0:N/2
    k2 = np.arange(-N/2+1, -1 + 1, 1)  # in Matlab --> -N/2+1:-1
    k = np.concatenate((k1, k2)) / scale
    DOF = len(x)
    # Initialization, be careful, DO NOT ASSIGN THE POINTER OF AN ADDRESS. Use slice technique
    strain = strain_avg * ones(DOF)
    C_x = C(omega, x)
    C0 = np.max(C_x) + 1
    fGamma = -1.0 / C0
    stress_star = np.zeros(DOF)
    strain_star = np.zeros(DOF)
    strain_star = sqrt(1 + strain) - 1
    stress_star = C_x * strain_star
    fstress_star = np.zeros(DOF, dtype=complex)
    fstrain_star = np.zeros(DOF, dtype=complex)
    for i in range(0, maxIteration, 1):
        # print ("Iteration %d" % i)
        fstrain_star = scipy.fftpack.rfft(strain_star)
        fstress_star = scipy.fftpack.rfft(stress_star)
        # if np.linalg.norm(fstress_star[0]) != 0:
        #     err = N * np.linalg.norm(np.inner(k, fstress_star)) / np.linalg.norm(fstress_star[0])
        #     if err < TOL:
        #         break
            # print(err)
        fstrain_star = fGamma * fstress_star + fstrain_star
        strain_star_avg = 1.0 / vol * h * np.sum(strain_star)
        fstrain_star[0] = N * strain_star_avg  # Please, note that we have factor N here in the form of Fourier Transform of strain
        strain_star = scipy.fftpack.irfft(fstrain_star)
        stress_star = C_x * strain_star  # it is not matrix x matrix. It is Each element x Each element


    # Compute macroscale strain and macroscale stress
    strain = square(strain_star + 1) - 1
    stress = C_x * (sqrt(1 + strain) - 1)

    # plt.plot(x, strain)
    # plt.show()

    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # SOLUTION FOR FLUCTUATIVE PART
    # A paper in Stuttgart Group Research has discovered that
    # Another way is that we can use Finite Difference Method
    # No matter what method, legacy method or Stuttgart's method, the solver is not important in this scope
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    alpha = np.zeros(DOF)
    delta_C = C_x - C0
    maxIter2 = 1000
    for iter in range(0, maxIter2, 1):
        # Updated solution in Fourier Space
        fDelta_C = scipy.fftpack.fft(delta_C)
        fDelAlpha = scipy.fftpack.fft(delta_C * alpha)
        fAlpha = np.inner(fGamma, fDelta_C) + np.inner(fGamma, fDelAlpha)
        fAlpha[0] = 0
        # Update solution in physical space
        alpha = scipy.fftpack.ifft(fAlpha).real
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # Computation of Effective Stiffness
    meanStress = 1.0 / vol * h * np.sum(stress)
    # Effective stiffness
    beta = C_x * (1.0 + alpha)
    beta2 = 1.0 / vol * (h * 1.0 / 2.0 * np.dot(np.power(1 + strain, -0.5), (1 + alpha)))
    beta1 = 1.0 / vol * (h * np.sum(beta))
    Ceffective = beta1 * beta2
    # Ceffective = 1.0 / vol * h * np.sum(beta)
    print(Ceffective)

    stress_macro = 1.0 / vol * (np.trapz(stress, x=x) + h*np.mean([stress[0], stress[DOF-1]]))
    strain_macro = 1.0 / vol * (np.trapz(strain, x=x) + h*np.mean([strain[0], strain[DOF-1]]))
    # stress_macro = 1.0 / vol * h * np.sum(stress)
    # strain_macro = 1.0 / vol * h * np.sum(strain)
    # return strain_macro, stress_macro
    return Ceffective



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
        fstress = fft.rfft(stress)
        fstrain = fft.rfft(strain)
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
        strain = fft.irfft(fstrain)
        stress = constitutive_law(C(omega, x), strain)  # it is not matrix x matrix. It is Each element x Each element

    # Density energy function
    energy = C(omega, x) * (2.0/3.0 * np.power(1 + strain, 3.0/2.0) - strain)
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # SOLUTION FOR FLUCTUATIVE PART
    # A paper in Stuttgart Group Research has discovered that
    # Another way is that we can use Finite Difference Method
    # No matter what method, legacy method or Stuttgart's method, the solver is not important in this scope
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    alpha = np.zeros(N)
    dSigdEps = C(omega, x) / (2 * np.sqrt(1 + strain))
    delta_C = dSigdEps - C0
    maxIter2 = 500
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
