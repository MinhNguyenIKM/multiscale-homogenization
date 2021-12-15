import numpy as np
import scipy.fftpack as fft
import pyfem.util.shapeFunctions as sF
from numpy import linalg as la
from numpy import pi


def cal_effective_stiffness(strain_avg):
    strain_macro, stress_macro, Ceffective = solve_micro_1d_fft(strain_avg[0])
    return Ceffective


def cal_effective_C(strain_avg):
    strain_macro1, stress_macro1 = solve_macro_1d_fem(strain_avg[0] + 1)
    strain_macro2, stress_macro2 = solve_macro_1d_fem(strain_avg[0] + 1.2)
    return (stress_macro2 - stress_macro1) / (strain_macro2 - strain_macro1)


def C(k, x):
    return 3.0 / 2.0 + np.sin(2.0 * np.pi * k * x)


def solve_micro_1d_fft(strain_avg):
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
    stress = C_x * strain
    stressAVG = stress
    C0 = C_x[0]
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
        strainAVG = 1.0 / vol * h * np.sum(strain)
        fstrain[0] = N * strain_avg
        #fstrain[0] = N * strain_avg  # Please, note that we have factor N here in the form of Fourier Transform of strain
        strain = fft.irfft(fstrain)
        stress = C(omega, x) * strain  # it is not matrix x matrix. It is Each element x Each element

    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # SOLUTION FOR FLUCTUATIVE PART
    # A paper in Stuttgart Group Research has discovered that
    # Another way is that we can use Finite Difference Method
    # No matter what method, legacy method or Stuttgart's method, the solver is not important in this scope
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    alpha = np.zeros(N)
    delta_C = C_x - C0
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
    beta = C_x * (1 + alpha)
    # Compute macroscale strain and macroscale stress
    stress_macro = 1.0 / vol * (np.trapz(stress, x=x) + h * np.mean([stress[0], stress[DOF-1]]))
    strain_macro = 1.0 / vol * (np.trapz(strain, x=x) + h * np.mean([strain[0], strain[DOF - 1]]))
    Ceffective = 1.0 / vol * (np.trapz(beta, x=x) + h * np.mean([beta[0], beta[DOF-1]]))
    return strain_macro, stress_macro, Ceffective


# This version is similar to solve_micro_1d_fft but this is gonna be returning more variales
def solve_micro_1d_fft_v2(strain_avg):
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
    stress = C_x * strain
    stressAVG = stress
    C0 = C_x[0]
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
        strainAVG = 1.0 / vol * h * np.sum(strain)
        fstrain[0] = N * strain_avg
        #fstrain[0] = N * strain_avg  # Please, note that we have factor N here in the form of Fourier Transform of strain
        strain = fft.irfft(fstrain)
        stress = C(omega, x) * strain  # it is not matrix x matrix. It is Each element x Each element

    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # SOLUTION FOR FLUCTUATIVE PART
    # A paper in Stuttgart Group Research has discovered that
    # Another way is that we can use Finite Difference Method
    # No matter what method, legacy method or Stuttgart's method, the solver is not important in this scope
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    alpha = np.zeros(N)
    delta_C = C_x - C0
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
    beta = C_x * (1 + alpha)
    # Compute macroscale strain and macroscale stress
    stress_macro = 1.0 / vol * (np.trapz(stress, x=x) + h * np.mean([stress[0], stress[DOF-1]]))
    strain_macro = 1.0 / vol * (np.trapz(strain, x=x) + h * np.mean([strain[0], strain[DOF - 1]]))
    Ceffective = 1.0 / vol * (np.trapz(beta, x=x) + h * np.mean([beta[0], beta[DOF-1]]))
    return x, k, lamda, strain, stress, Ceffective


def exe_post_processing(U, omega, nodeCoordinates, elementNodes):
    dof = len(nodeCoordinates)
    strain_bar = 0
    stress_bar = 0
    for e in range(0, dof-1, 1):
        elem = elementNodes[e][:]
        elemCoords = nodeCoordinates[elem]
        L = la.norm(elemCoords[1] - elemCoords[0])
        sData = sF.getElemShapeData(elemCoords, 0, 'Gauss', 'Line2')
        dxidx = 2.0 / L
        strain_e = 0
        stress_e = 0
        for iData in sData:
            B = np.transpose(iData.dhdxi) * dxidx
            x = np.dot(iData.h, elemCoords)
            strain_e += np.dot(B, U[elem]) * iData.weight
            stress_e += C(omega, x) * np.dot(B, U[elem]) * iData.weight
    strain_bar += strain_e
    stress_bar += stress_e
    return strain_bar, stress_bar


def solve_macro_1d_fem(strain_avg):
    omega = 10
    # setting micro scale properties
    lamda = 1.0 / omega
    # Left-end of a RVE
    a = -lamda / 2.0
    # Right-end of a RVE
    b = lamda / 2.0
    # Number of grid
    N = 2 ** 2
    # The distance between grid points
    h = (b - a) / N
    # Coordinates of collocation points OR Coordinates of pixel(2D) | voxel(3D)
    nodeCoordinates = np.arange(a+h, b+h, h)  # in Matlab --> a+h:h:b
    dof = len(nodeCoordinates)
    elementNodes = [[i, i+1] for i in range(0, dof-1, 1)]
    # Node is constrain by Neumann boundary
    bDOF = []
    U = np.zeros([dof, 1])
    # The free unknown nodes need to be calculated
    inDOF = np.setdiff1d(np.arange(0, dof), bDOF)
    TOL = 1e-7
    C_x = C(omega, nodeCoordinates)
    # Non-linear solver (Newton-Raphson method) for linear problem
    for step in range(0, 50, 1):
        K_t = np.zeros([dof, dof])
        F_ext = np.zeros([dof, 1])
        F_int = np.zeros([dof, 1])

        print("Nonlinear processing in Micro at step number [%d]" % step)

        for e in range(0, len(elementNodes), 1):
            # print("Element ----------------------------------- %d" % e)
            elem = elementNodes[e][:]
            elemCoords = nodeCoordinates[elem]
            L = la.norm(elemCoords[1]-elemCoords[0])
            K_t_e = np.zeros([2, 2])
            F_ext_e = np.zeros([2, 1])
            F_int_e = np.zeros([2, 1])
            sData = sF.getElemShapeData(elemCoords, 0, 'Gauss', 'Line2')
            dxidx = 2.0 / L
            bodyforce = 0
            for iData in sData:
                B = np.transpose(iData.dhdxi) * dxidx
                # Local tangent stiffness matrix in MICRO: Derivative of local internal force w.r.t u
                x = np.dot(iData.h, elemCoords)
                K_t_e = K_t_e + (np.dot(B.transpose(), B) * C(omega, x) * iData.weight)
                # Local internal force in MICRO
                F_int_e = F_int_e + (np.dot(B.transpose(), np.dot(B, U[elem])) * C(omega, x) * iData.weight)
                # Local external force, We apply F = 0 at the end of the beam - Neumann B.C --> F(L) = 0
                F_ext_e = F_ext_e + (iData.h.reshape(2, 1) * bodyforce * iData.weight)

            # Assembly local stiffness matrix to global stiffness matrix
            K_t[np.ix_(elem, elem)] = K_t[np.ix_(elem, elem)] + K_t_e
            # Assembly local internal force to the global internal force
            F_int[elem] = F_int[elem] + F_int_e
            # Assembly local external force to the global external force
            F_ext[elem] = F_ext[elem] + F_ext_e

        F_ext[0][0] = C_x[0] * strain_avg
        F_ext[dof - 1][0] = C_x[dof - 1] * strain_avg
        dU = la.solve(K_t[np.ix_(inDOF, inDOF)], F_ext[inDOF] - F_int[inDOF])
        U[inDOF] = U[inDOF] + dU
        try:
            con = la.norm(dU)/la.norm(U[inDOF])
            print("Convergence --> %f" % con)
            if con < TOL:
                print("The algorithm is convergent at step: %d" % step)
                break
        except Exception as e:
            print("There is error related to convergence of the  algorithm")
            print(e)
    return exe_post_processing(U, omega, nodeCoordinates, elementNodes)


def solve_micro_1d_fft_v3(strain_avg):
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
    stress = C_x * strain
    stressAVG = stress
    C0 = C_x[0]
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
        strainAVG = 1.0 / vol * h * np.sum(strain)
        fstrain[0] = N * strain_avg
        #fstrain[0] = N * strain_avg  # Please, note that we have factor N here in the form of Fourier Transform of strain
        strain = fft.irfft(fstrain)
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
    beta = C_x * (1 + alpha)
    # Compute macroscale strain and macroscale stress
    stress_macro = 1.0 / vol * (np.trapz(stress, x=x) + h * np.mean([stress[0], stress[DOF-1]]))
    strain_macro = 1.0 / vol * (np.trapz(strain, x=x) + h * np.mean([strain[0], strain[DOF-1]]))
    energy_macro = 1.0 / vol * (np.trapz(energy, x=x) + h * np.mean([energy[0], energy[DOF-1]]))
    Ceffective = 1.0 / vol * (np.trapz(beta, x=x) + h * np.mean([beta[0], beta[DOF-1]]))
    return x, k, lamda, strain, stress, strain_macro, stress_macro, Ceffective, energy_macro


def dftmtx(N):
    return fft.fft(np.eye(N))


def solve_1d_pod():
    itermax = 1000
    xi = 0

    for i in range(0, itermax, 1):
        pass



