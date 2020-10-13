import numpy as np
from math import pi
from numpy import linalg as la
import pyfem.util.shapeFunctions as sF
from matplotlib import pyplot
from numpy import dot, zeros, array, arange, sin, ix_, sqrt
import time

def c(k, N, x): return 3.0/2.0 + sin(2.0 * pi * k * dot(N, x))


def f(N, x): return dot(N, x)


def solve_1scale(ax, k=10, noElement=1000):
    t = time.time()
    # k = 10
    # noElement = 1000
    # Left-end of the bar
    a = 0
    # Right-end of the bar
    b = 1

    nodeCoordinates = np.linspace(a, b, noElement + 1)

    dof = len(nodeCoordinates)

    elementNodes = [[i, i+1] for i in range(0, dof, 1)]

    # Node is constrain by Neumann boundary
    bDOF = [0]
    U = zeros([dof, 1])
    U[bDOF] = 0
    # The free unknown nodes need to be calculated
    inDOF = np.setdiff1d(arange(0, dof), bDOF)
    TOL = 1e-7

    # Non-linear solver for linear problem
    for step in range(0, 100, 1):
        K_t = zeros([dof, dof])
        F_ext = zeros([dof, 1])
        F_int = zeros([dof, 1])

        print("Nonlinear processing at step number [%d]" % step)

        for e in range(0, noElement, 1):
            elem = elementNodes[e][:]
            elemCoords = nodeCoordinates[elem]
            L = la.norm(elemCoords[1] - elemCoords[0])
            K_t_e = zeros([2, 2])
            F_ext_e = zeros([2, 1])
            F_int_e = zeros([2, 1])
            sData = sF.getElemShapeData(elemCoords, 0, 'Gauss', 'Line2')
            dxidx = 2.0/L

            for iData in sData:
                B = np.transpose(iData.dhdxi) * dxidx
                C = c(k, iData.h, elemCoords)
                print(C)
                # Local tangent stiffness matrix: Derivative of local internal force w.r.t u
                K_t_e = K_t_e + dot(B.transpose(), 1.0/2.0 * B * np.linalg.inv(sqrt(1 + dot(B, U[elem])))) * C * iData.weight
                # Local internal force
                F_int_e = F_int_e + dot(B.transpose(), (sqrt(1 + dot(B, U[elem])) - 1)) * C * iData.weight
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
            print("There is error related to convergence of the algorithm")
            print(e)

    # Plotting & Validating the results
    #pyplot.plot(nodeCoordinates, F_ext)
    print(U[dof-1])
    #print(U[400])
    pyplot.plot(nodeCoordinates, U)
    ax.plot(nodeCoordinates, U, color='blue', label='Full-field solution k = 100')

    #pyplot.xlim(0, 1.0)  # decreasing time
    #pyplot.ylim(0, 0.8)  # decreasing time
    print(time.time() - t)
    #pyplot.show()
    return nodeCoordinates, U, ax


if __name__ == '__main__':
    fig, ax = pyplot.subplots()
    solve_1scale(ax)
    pyplot.show()



