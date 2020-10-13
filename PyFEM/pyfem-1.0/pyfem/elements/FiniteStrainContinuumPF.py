# ---------------------------------------------------------------------------------
# FINITE STRAIN CONTINUUM based on power-conjugate fields: P and F
# We formulate the Galerkin (FEM) discretization of variational based on P and F
# This is a P - F formulation.
# The code is implemented based on the code FiniteStrainContinuum.py developed by
# [1] J.J.C. Remmers, C.V. Verhoosel and R. de Borst.
# The code in [1] is a E - S formulation.
# Author: minh.nguyen@ikm.uni-hannover.de
# Create date: 19/09/2018
# ---------------------------------------------------------------------------------

from .Element import Element
from pyfem.util.shapeFunctions import getElemShapeData
from pyfem.util.kinematics import Kinematics
from numpy import zeros, dot, outer, ones, eye, sqrt
import numpy as np
from scipy.linalg import eigvals
import util.Utility as ut


# ------------------------------------------------------------------------------
#
# ------------------------------------------------------------------------------

class FiniteStrainContinuumPF(Element):
    # dofs per element
    dofTypes = ['u', 'v']

    def __init__(self, elnodes, props):
        Element.__init__(self, elnodes, props)

    def __type__(self):
        return name

    # ------------------------------------------------------------------------------
    #
    # ------------------------------------------------------------------------------
    def getTangentStiffness(self, elemdat):
        try:
            # filename = 'training_data_1D_mechanics_nonlinear.dat'
            filename = './tracking_DeformationGradient.txt'
            f = open(filename, 'a+')
        except IOError as e:
            print("Can't open file :" + e.filename)
        n = self.dofCount()
        sData = getElemShapeData(elemdat.coords)
        elemdat.outlabel.append("stresses")
        elemdat.outdata = zeros(shape=(len(elemdat.nodes), 3))
        f.write("-------------------- \n")
        for iData in sData:
            kin = self.getKinematics(iData.dhdx, elemdat.state)
            firstPiola, K4 = self.mat.getStress(kin)
            firstPiola_vector = ut.transform_matrix_to_vector(firstPiola)
            Bnl = self.getBNLmatrix(iData.dhdx)
            elemdat.stiff += dot(Bnl.transpose(), dot(K4, Bnl)) * iData.weight
            elemdat.fint += dot(Bnl.transpose(), firstPiola_vector) * iData.weight
            secondPiola = dot(np.linalg.inv(kin.F), firstPiola)
            secondPiola_vector = np.array([secondPiola[0, 0], secondPiola[1, 1], secondPiola[0, 1]])
            elemdat.outdata += outer(ones(len(elemdat.nodes)), secondPiola_vector)

            # Store information to track Deformation Gradient F
            f.write("NODE: %d; %d; %d; \n" % (elemdat.nodes[0], elemdat.nodes[1], elemdat.nodes[2]))
            f.write("%0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f; %0.12f\n" %
                    (kin.F[0, 0], kin.F[0, 1], kin.F[1, 0], kin.F[1, 1], firstPiola_vector[0], firstPiola_vector[1], firstPiola_vector[2], firstPiola_vector[3]))
            # f.close()
        f.write("-------------------- \n")
        # elemdat.stiff += dot(B.transpose(), dot(tang, B)) * iData.weight  # nonlinear material: dF : (F . DS) -> (dF.F) : C DE -> (dF.F) : C : (DF.F)
        # T = self.stress2matrix(sigma)
        # Bnl = self.getBNLmatrix(iData.dhdx)
        # elemdat.stiff += dot(Bnl.transpose(), dot(T, Bnl)) * iData.weight  # nonlinear geometry: dF : (DF . S)
        # elemdat.fint += dot(B.transpose(), sigma) * iData.weight  # power conjugate: chuyen tu F:P sang E:S -> 1/2(FT.F + F.FT):S -> FT.F : S (vi S symmetry)
        # elemdat.outdata += outer(ones(len(elemdat.nodes)), sigma)
        elemdat.outdata *= 1.0 / len(sData)

    # ------------------------------------------------------------------------------
    #
    # ------------------------------------------------------------------------------
    def getInternalForce(self, elemdat):
        n = self.dofCount()
        sData = getElemShapeData(elemdat.coords)
        elemdat.outlabel.append("stresses")
        elemdat.outdata = zeros(shape=(len(elemdat.nodes), 3))
        for iData in sData:
            # kin = self.getKinematics(iData.dhdx, elemdat.state)
            # B = self.getBmatrix(iData.dhdx, kin.F)
            # sigma, tang = self.mat.getStress(kin)
            # elemdat.fint += dot(B.transpose(), sigma) * iData.weight
            # elemdat.outdata += outer(ones(len(elemdat.nodes)), sigma)

            kin = self.getKinematics(iData.dhdx, elemdat.state)
            Bnl = self.getBNLmatrix(iData.dhdx)
            firstPiola, K4tang = self.mat.getStress(kin)
            firstPiola_vector = ut.transform_matrix_to_vector(firstPiola)
            secondPiola = dot(np.linalg.inv(kin.F), firstPiola)
            secondPiola_vector = np.array([secondPiola[0, 0], secondPiola[1, 1], secondPiola[0, 1]])
            elemdat.fint += dot(Bnl.transpose(), firstPiola_vector) * iData.weight
            elemdat.outdata += outer(ones(len(elemdat.nodes)), secondPiola_vector)
        elemdat.outdata *= 1.0 / len(sData)

    # ------------------------------------------------------------------------------
    #
    # ------------------------------------------------------------------------------
    def getMassMatrix(self, elemdat):
        pass

    # sData = getElemShapeData(elemdat.coords)
    # rho = elemdat.matprops.rho
    # for iData in sData:
    # 	N = self.getNmatrix(iData.h)
    # 	elemdat.mass += dot(N.transpose(), N) * rho * iData.weight
    # elemdat.lumped = sum(elemdat.mass)

    # ------------------------------------------------------------------------------
    # Create date: 24/09/2018
    # minh.nguyen@ikm.uni-hannover.de
    # Function to return the value of external force when it is considered
    # Tam thoi our programme khong co xet distribution force
    # ------------------------------------------------------------------------------
    def getExternalForce(self, iData, elemdat):
        print("ExternalForce calculating !!!")
        XY = np.dot(iData.h, elemdat.coords)
        return elemdat.func(XY[0], XY[1])

    # ------------------------------------------------------------------------------
    #
    # ------------------------------------------------------------------------------
    def getKinematics(self, dphi, elstate):
        kin = Kinematics(2, 3)
        kin.F = eye(2)
        for i in range(len(dphi)):
            for j in range(2):
                for k in range(2):
                    kin.F[j, k] += dphi[i, k] * elstate[2 * i + j]

        # kin.E = 0.5 * (dot(kin.F.transpose(), kin.F) - eye(2))
        # kin.strain[0] = kin.E[0, 0]
        # kin.strain[1] = kin.E[1, 1]
        # kin.strain[2] = 2.0 * kin.E[0, 1]

        return kin

    # ------------------------------------------------------------------------------
    #
    # ------------------------------------------------------------------------------
    def matrix2vector(self, stress):
        return stress.reshape(-1)

    # ------------------------------------------------------------------------------
    #
    # ------------------------------------------------------------------------------
    def getBNLmatrix(self, dphi):
        Bnl = zeros(shape=(4, 2 * len(dphi)))
        for i, dp in enumerate(dphi):
            Bnl[0, 2 * i] = dp[0]
            Bnl[1, 2 * i] = dp[1]
            Bnl[2, 2 * i + 1] = dp[0]
            Bnl[3, 2 * i + 1] = dp[1]
        return Bnl

    # ------------------------------------------------------------------------------
    #
    # ------------------------------------------------------------------------------
    def getNmatrix(self, h):
        N = zeros(shape=(2, 2 * len(h)))
        for i, a in enumerate(h):
            N[0, 2 * i] = a
            N[1, 2 * i + 1] = a
        return N
