############################################################################
#  This Python file is part of PyFEM-1.0, released on Aug. 29, 2012.       #
#  The PyFEM code accompanies the book:                                    #
#                                                                          #
#    'Non-Linear Finite Element Analysis of Solids and Structures'         #
#    R. de Borst, M.A. Crisfield, J.J.C. Remmers and C.V. Verhoosel        #
#    John Wiley and Sons, 2012, ISBN 978-0470666449                        #
#                                                                          #
#  The code is written by J.J.C. Remmers, C.V. Verhoosel and R. de Borst.  #
#  Comments and suggestions can be sent to:                                #
#     PyFEM-support@tue.nl                                                 #
#                                                                          #
#  The latest version can be downloaded from the web-site:                 #
#     http://www.wiley.com/go/deborst                                      #
#                                                                          #
#  The code is open source and intended for educational and scientific     #
#  purposes only. If you use PyFEM in your research, the developers would  #
#  be grateful if you could cite the book.                                 #
#                                                                          #
#  Disclaimer:                                                             #
#  The authors reserve all rights but do not guarantee that the code is    #
#  free from errors. Furthermore, the authors shall not be liable in any   #
#  event caused by the use of the program.                                 #
############################################################################

# minh.nguyen@ikm.uni-hannover.de create this file for the Saint-Venant material in Plane Stress Problem.
# Create date: 17/09/2018

from pyfem.materials.BaseMaterial import BaseMaterial
from numpy import zeros, dot


class Saint_Venant_PlaneStress(BaseMaterial):

	def __init__(self, props):
		# Call the BaseMaterial constructor
		BaseMaterial.__init__(self, props)

		self.setHistoryParameter('kappa', 0.0)
		self.commitHistory()

		# Create the hookean matrix
		self.H = zeros((3, 3))

		self.H[0, 0] = self.E / (1. - self.nu * self.nu)
		self.H[0, 1] = self.H[0, 0] * self.nu
		self.H[1, 0] = self.H[0, 1]
		self.H[1, 1] = self.H[0, 0]
		self.H[2, 2] = self.E / (2.0 * (1.0 + self.nu))

	def getStress(self, deformation):
		# Need to be focused in and modified in 2 Scales calculation
		sigma = dot(self.H, deformation.strain)

		self.setHistoryParameter('kappa', sigma[0])

		return sigma, self.H

	def getTangent(self):
		return self.H

