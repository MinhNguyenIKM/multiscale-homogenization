# ---------------------------------------------------------------------------------
# SAINT-VENANT model for plane strain problem
# Author: minh.nguyen@ikm.uni-hannover.de
# Create date: 19/09/2018
# ---------------------------------------------------------------------------------
from pyfem.materials.BaseMaterial import BaseMaterial
from numpy import zeros, dot
import numpy as np
from util.mytensor import *
from machinelearning.training_results import recover_potential_energy as ml

class MachineLearningPrediction(BaseMaterial):
	def __init__(self, props):
		BaseMaterial.__init__(self, props)
		# Create the hookean matrix
		self.H = zeros((3, 3))

	def getStress(self, deformation):
		try:
			filename = './tracking_DeformationGradient_Inclusion_NeoHooke2_NN.txt'
			f = open(filename, 'a+')
		except IOError as e:
			print("Can't open file :" + e.filename)

		F = deformation.F
		# type = 'SaintVenant'
		# type = 'NeoHookean'
		type = 'Inclusion-NeoHookean2'
		P, K4, W = ml.cal_material_parameter2D(F, type)
		f.write("%0.12f;\t%0.12f;\t%0.12f;\t%0.12f;\t%0.12f\n" % (F[0, 0], F[0, 1], F[1, 0], F[1, 1], W))
		return P, K4
