import numpy as np
from numpy import linalg as la
import pyfem.util.shapeFunctions as sF
from matplotlib import pyplot
from numpy import dot, zeros, array, arange, sin, ix_, linspace
import time
import nn_1D as nn
import fem1Dlinear as fem1D
from microscale.fftstandard import micro1D as mic

def f(N, x): return dot(N, x)


fig, ax = pyplot.subplots()

def macro_micro_neuralnetwork():
    t = time.time()

    noElement = 50
    # Left-end of the bar
    a = 0
    # Right-end of the bar
    b = 1

    nodeCoordinates = linspace(a, b, noElement + 1)

    dof = len(nodeCoordinates)

    elementNodes = [[i, i+1] for i in range(0, dof, 1)]

    # Node is constrain by Neumann boundary
    bDOF = [0]
    U = zeros([dof, 1])
    U[bDOF] = 0
    # The free unknown nodes need to be calculated
    inDOF = np.setdiff1d(arange(0, dof), bDOF)
    TOL = 1e-7

    # Non-linear solver (Newton-Raphson method) for linear problem
    for step in range(0, 50, 1):
        K_t = zeros([dof, dof])
        F_ext = zeros([dof, 1])
        F_int = zeros([dof, 1])

        print("Nonlinear processing at step number [%d]" % step)

        for e in range(0, noElement, 1):
            # print("Element ----------------------------------- %d" % e)
            elem = elementNodes[e][:]
            elemCoords = nodeCoordinates[elem]
            L = la.norm(elemCoords[1]-elemCoords[0])
            K_t_e = zeros([2, 2])
            F_ext_e = zeros([2, 1])
            F_int_e = zeros([2, 1])
            sData = sF.getElemShapeData(elemCoords, 0, 'Gauss', 'Line2')
            dxidx = 2.0 / L

            for iData in sData:
                B = np.transpose(iData.dhdxi) * dxidx
                strain_macro = dot(B, U[elem])
                print(strain_macro)
                # Calculate the effective stiffness
                stress, C = nn.cal_material_parameter(strain_macro, '1Dlinear')
                #f = open(filename, 'w+')
                #f.write("%0.12f\t%0.12f\n" % (C)
                #C = nn.cal_C(strain_macro)
                #C = mic.cal_effective_stiffness(strain_macro)
                print(C)
                # Local tangent stiffness matrix: Derivative of local internal force w.r.t u
                K_t_e = K_t_e + (dot(B.transpose(), B) * C * iData.weight)
                # Local internal force
                F_int_e = F_int_e + (dot(B.transpose(), dot(B, U[elem])) * C * iData.weight)
                # Local external force, We apply F = 0 at the end of the beam - Neumann B.C --> F(L) = 0
                F_ext_e = F_ext_e + (iData.h.reshape(2, 1) * f(iData.h, elemCoords) * iData.weight)

            # Assembly local stiffness matrix to global stiffness matrix
            K_t[ix_(elem, elem)] = K_t[ix_(elem, elem)] + K_t_e
            # Assembly local internal force to the global internal force
            F_int[elem] = F_int[elem] + F_int_e
            # Assembly local external force to the global external force
            F_ext[elem] = F_ext[elem] + F_ext_e

        dU = la.solve(K_t[ix_(inDOF, inDOF)], F_ext[inDOF] - F_int[inDOF])
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

    # Plotting & Validating the results
    # pyplot.plot(nodeCoordinates, F_ext)

    ax.plot(nodeCoordinates, U, 'ro', label='Neural Network')
    print(time.time() - t)
    #pyplot.show()


def macro_micro_femfft():
    t = time.time()

    noElement = 50
    # Left-end of the bar
    a = 0
    # Right-end of the bar
    b = 1

    nodeCoordinates = linspace(a, b, noElement + 1)

    dof = len(nodeCoordinates)

    elementNodes = [[i, i+1] for i in range(0, dof, 1)]

    # Node is constrain by Neumann boundary
    bDOF = [0]
    U = zeros([dof, 1])
    U[bDOF] = 0
    # The free unknown nodes need to be calculated
    inDOF = np.setdiff1d(arange(0, dof), bDOF)
    TOL = 1e-7

    # Non-linear solver (Newton-Raphson method) for linear problem
    for step in range(0, 50, 1):
        K_t = zeros([dof, dof])
        F_ext = zeros([dof, 1])
        F_int = zeros([dof, 1])

        print("Nonlinear processing at step number [%d]" % step)

        for e in range(0, noElement, 1):
            # print("Element ----------------------------------- %d" % e)
            elem = elementNodes[e][:]
            elemCoords = nodeCoordinates[elem]
            L = la.norm(elemCoords[1]-elemCoords[0])
            K_t_e = zeros([2, 2])
            F_ext_e = zeros([2, 1])
            F_int_e = zeros([2, 1])
            sData = sF.getElemShapeData(elemCoords, 0, 'Gauss', 'Line2')
            dxidx = 2.0 / L

            for iData in sData:
                B = np.transpose(iData.dhdxi) * dxidx
                strain_macro = dot(B, U[elem])
                print(strain_macro)
                # Calculate the effective stiffness
                #stress, C = nn.cal_material_parameter(strain_macro)
                #f = open(filename, 'w+')
                #f.write("%0.12f\t%0.12f\n" % (C)

                #C = nn.cal_C(strain_macro)
                C = mic.cal_effective_stiffness_1d_linear(strain_macro)
                print(C)
                # Local tangent stiffness matrix: Derivative of local internal force w.r.t u
                K_t_e = K_t_e + (dot(B.transpose(), B) * C * iData.weight)
                # Local internal force
                F_int_e = F_int_e + (dot(B.transpose(), dot(B, U[elem])) * C * iData.weight)
                # Local external force, We apply F = 0 at the end of the beam - Neumann B.C --> F(L) = 0
                F_ext_e = F_ext_e + (iData.h.reshape(2, 1) * f(iData.h, elemCoords) * iData.weight)

            # Assembly local stiffness matrix to global stiffness matrix
            K_t[ix_(elem, elem)] = K_t[ix_(elem, elem)] + K_t_e
            # Assembly local internal force to the global internal force
            F_int[elem] = F_int[elem] + F_int_e
            # Assembly local external force to the global external force
            F_ext[elem] = F_ext[elem] + F_ext_e

        dU = la.solve(K_t[ix_(inDOF, inDOF)], F_ext[inDOF] - F_int[inDOF])
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

    # Plotting & Validating the results
    # pyplot.plot(nodeCoordinates, F_ext)
    ax.plot(nodeCoordinates, U, color='black', linestyle='dashdot', label='FE-FFT')
    print(time.time() - t)



if __name__ == '__main__':
    macro_micro_neuralnetwork()
    macro_micro_femfft()
    fem1D.solve_1scale(ax, 10)
    legend = ax.legend(loc='upper left', shadow=True, fontsize='x-small')
    pyplot.xlabel('x')
    pyplot.ylabel('u(x)')
    pyplot.grid(True)
    # Put a nicer background color on the legend.
    legend.get_frame().set_facecolor('#FFFFFF')
    pyplot.show()


