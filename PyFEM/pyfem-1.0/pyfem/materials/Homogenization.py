############################################################################
# HOMOGENIZED MATERIALS
# minh.nguyen@ikm.uni-hannover.de
############################################################################

from pyfem.materials.BaseMaterial import BaseMaterial
from numpy import *
import numpy as np
from microscale.fftgarlerkin import micro2D_largedeformation_elasticity as micro2D


class Homogenization(BaseMaterial):
    #  4 Gausspoints
    def __init__(self, props):
        # Call the BaseMaterial constructor
        BaseMaterial.__init__(self, props)
        self.gaussNo = 4
        # Create the hookean matrix
        # self.effectiveModuli = zeros((3, 3))
        #
        # self.effectiveModuli[0, 0] = 0
        # self.effectiveModuli[0, 1] = 0
        # self.effectiveModuli[1, 0] = 0
        # self.effectiveModuli[1, 1] = 0
        # self.effectiveModuli[2, 2] = 0

        # For small strain
        # self.effectiveModuli = np.zeros([self.gaussNo, 3, 3])  # 4: number of Gauss points, 3 x 3: moduli matrix
        # self.sigma = np.zeros([self.gaussNo, 3], dtype=float)  # 4: number of Gauss points, 3: components of stress
        # For large strain
        self.effectiveModuli = np.zeros([self.gaussNo, 4, 4])
        self.sigma = np.zeros([self.gaussNo, 2, 2])
        self.phase = props.phase
        self.isHomogenized = np.zeros([self.gaussNo])  # number of Gauss points.
        self.gaussID = 0
        self.maxGaussID = self.gaussNo - 1
        # self.sigma = [0, 0, 0]

    def reset(self):
        self.effectiveModuli = np.zeros([self.gaussNo, 4, 4])  # 4: number of Gauss points, 3 x 3: moduli matrix
        self.sigma = np.zeros([self.gaussNo, 2, 2])  # 4: number of Gauss points, 3: components of stress
        self.isHomogenized = np.zeros([self.gaussNo])  # number of Gauss points.


    def getStress(self, deformation, gaussIter):
        if gaussIter == 0:
            self.reset()
        #sigma = dot(self.H, deformation.strain)
        #return sigma, self.H
        if self.isHomogenized[gaussIter] == 0:  # Not yet done homogenization for this material point
            print("Homogenization step. We are in the Assemble Tangent Stiffness Matrix.")
            # import micro2D2 as mic2D
            # from microscale.fftstandard import micro2D_smalldeformation_elasticity as mic2D
            # _, _, _, _, sigma, _, C_eff = mic2D.solve_micro2D(self.phase, deformation.strain)
            # C_eff, sigma = mic2D.homogenize_microstructure(deformation.strain)
            # F = solve_nonlinear_GalerkinFFT(domain='inclusion', kind='neo-hookean', mode='stiffness')
            average_energy, P_homogenized, C_homogenized2D = micro2D.solve_nonlinear_GalerkinFFT(F_macro=deformation.F, domain='inclusion', kind='neo-hookean2', mode='everything') # Neo-Hookean2
            # average_energy, P_homogenized, C_homogenized2D = micro2D.solve_nonlinear_GalerkinFFT(F_macro=deformation.F, domain='inclusion', kind='mooney-rivlin', mode='everything')
            print("Effective tangent moduli: ", C_homogenized2D)
            self.effectiveModuli[gaussIter, :, :] = C_homogenized2D
            self.sigma[gaussIter, :, :] = P_homogenized
            self.isHomogenized[gaussIter] = 1
        elif self.isHomogenized[gaussIter] == 1:
            print("Homogenization already. We are in the Assemble Internal Force.")
        return self.sigma[gaussIter, :], self.effectiveModuli[gaussIter, :, :]


    def getTangent(self):
        #return self.H
        print("We are getting Tangent for you")
        return self.effectiveModuli

