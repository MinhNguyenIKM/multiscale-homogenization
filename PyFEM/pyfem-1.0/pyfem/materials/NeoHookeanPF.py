# ---------------------------------------------------------------------------------
# NEO-HOOKEAN model for plane strain problem
# Energy function: W = mu/2 * (Tr[cauchyStrain] - ndim) + mu/beta * (Det[deformGrad]^{-beta} - 1)
# Author: minh.nguyen@ikm.uni-hannover.de
# Create date: 08/10/2019
# ---------------------------------------------------------------------------------
from pyfem.materials.BaseMaterial import BaseMaterial
from numpy import zeros, dot
import numpy as np
from util.mytensor import *
import util.Utility as ut
import itertools

class NeoHookeanPF(BaseMaterial):
	def __init__(self, props):
		BaseMaterial.__init__(self, props)
		self.H = zeros((3, 3))

	def getStress(self, deformation):
		# try:
		# 	filename = './tracking_DeformationGradient_NeoHooke2_FE-FFT.txt'
		# 	f = open(filename, 'a+')
		# except IOError as e:
		# 	print("Can't open file :" + e.filename)
		F = deformation.F
		dim = np.shape(F)[0]
		# print('Material E = %d and nu = %.2f' % (self.E, self.nu))
		mu = self.E / (2 * (1 + self.nu))
		lam = (self.E * self.nu) / ((1 + self.nu) * (1 - 2 * self.nu))
		beta = (2 * self.nu)/(1 - 2 * self.nu)
		# Using Neo-Hookean model
		# P, K4tensor = self.constitutive_Neo_Hookean(F, mu, beta)  # Neo-Hookean Felix Gukuzum
		P, K4tensor = self.constitutive_Neo_Hookean2(F, mu, lam)  # Neo-Hookean Yvonnet
		# P, K4tensor = self.constitutive_Neo_Hookean2(F, self.E, self.nu)  # Neo-Hookean Abaqus
		K4 = ut.transform_4thTensor_to_2ndTensor_inlargestrain(K4tensor)
		# W = self.get_energy_Neo_Hookean(F, mu, beta)
		# f.write("%0.12f;\t%0.12f;\t%0.12f;\t%0.12f;\t%0.12f\n" % (F[0, 0], F[0, 1], F[1, 0], F[1, 1], W))
		return P, K4

	#  -----------------------------------------------------------------------------
	#       	NEO-HOOKEAN model in Yvonnet paper (2013 reduced database model)
	#  -----------------------------------------------------------------------------
	def constitutive_Neo_Hookean2(self, F, mu, lam):
		# First derivate of W:Neo-Hookean free energy w.r.t F
		dim = F.shape[0]
		detF = np.linalg.det(F)
		if np.any(detF < 0):  # That means the calculation will return wrong values
			print('detF < 0')
			exit()
			return -1, -1
		# pass
		invF = np.linalg.inv(F)
		P = np.zeros([dim, dim])
		for i, j in itertools.product(range(dim), repeat=2):
			P[i, j] = (lam * np.log(detF) - mu) * invF[j, i] + mu * F[i, j]
		# Second derivate of W:Neo-Hookean free energy w.r.t F
		K4 = np.zeros([dim, dim, dim, dim])
		for i, j, k, l in itertools.product(range(dim), repeat=4):
			K4[i, j, k, l] = lam * invF[j, i] * invF[l, k] - (lam * np.log(detF) - mu) * \
								   (invF[j, k] * invF[l, i]) + mu * delta(i, k) * delta(j, l)
		return P, K4

		#  -----------------------------------------------------------------------------
		#       	NEO-HOOKEAN model in Abaqus
		#  -----------------------------------------------------------------------------
	def constitutive_Neo_Hookean3(self, F, c, c1):
			# First derivate of W:Neo-Hookean free energy w.r.t F
			dim = F.shape[0]
			detF = np.linalg.det(F)
			if np.any(detF < 0):  # That means the calculation will return wrong values
				print('detF < 0')
				exit()
				return -1, -1
			# pass
			invF = np.linalg.inv(F)
			P = np.zeros([dim, dim])
			for i, j in itertools.product(range(dim), repeat=2):
				P[i, j] = 2 * c * (detF - 1) * detF * invF[j, i] + 2 * c1 * F[i, j]

			# Second derivate of W:Neo-Hookean free energy w.r.t F
			K4 = np.zeros([dim, dim, dim, dim])
			for i, j, k, l in itertools.product(range(dim), repeat=4):
				K4[i, j, k, l] = (4 * c * detF - 2 * c) * detF * invF[j, i] * invF[l, k] + 2 * c * (detF - 1) * detF \
					* (-invF[j, k] * invF[l, i]) + 2 * c1 * delta(i, k) * delta(j, l)
			return P, K4

	#  -----------------------------------------------------------------------------
	#                       NEO-HOOK model from F. GOEKUEZUEM and KEIP (2017)
	#  -----------------------------------------------------------------------------
	def constitutive_Neo_Hookean(self, F, mu, beta):
		# First derivate of W:Neo-Hookean free energy w.r.t F
		dim = F.shape[0]
		detF = np.linalg.det(F)
		invF = np.linalg.inv(F)
		# Gradient of energy W w.r.t F gives us First Piola Kirchhoff stress
		P = mu * F - mu * np.power(detF, -beta) * np.transpose(invF)
		# Second derivate (Hessian) of W:Neo-Hookean free energy w.r.t F gives us the tangent stiffness moduli
		K4 = np.zeros([dim, dim, dim, dim])
		for i, j, k, l in itertools.product(range(dim), repeat=4):
			K4[i, j, k, l] = mu * delta(i, k) * delta(j, l) + mu * np.power(detF, -beta) \
								   * (beta * invF[j, i] * invF[l, k] + invF[l, i] * invF[j, k])
		return P, K4

	def get_energy_Neo_Hookean(self, F, mu, beta):
		dim = F.shape[0]
		C = np.dot(np.transpose(F), F)
		trC = np.trace(C)
		detF = np.linalg.det(F)
		energy = mu / 2 * (trC - dim) + mu / beta * (np.power(detF, -beta) - 1)
		return energy

	# --------------------------------------------------------------------------
	def constitutive_Saint_Venant(self, F, mu, lam):
		#  -----------------------------------------------------------------------------
		#               SAINT-VENANT model (Like HOOKS model in small strain)
		#  -----------------------------------------------------------------------------
		def dyad(A2, B2): return np.einsum('ij,kl->ijkl', A2, B2)
		# identity tensor (single tensor)
		identity = np.eye(2)
		# identity tensors (grid)
		I = np.einsum('ij', identity)
		I4 = np.einsum('il,jk', identity, identity)
		I4rt = np.einsum('ik,jl', identity, identity)
		I4s = (I4 + I4rt) / 2.
		II = dyad(I, I)
		C4 = lam * II + 2 * mu * I4s
		# C4 = (lam * II) + 2.0 * mu * (I4s - 1.0 / 3.0 * II)
		S = simple_ddot42_v1(C4, 0.5 * (simple_dot22(simple_trans2(F), F) - I))
		P = simple_dot22(F, S)
		# K4 = simple_dot24(S, I4) + simple_ddot44_v1(simple_ddot44_v1(I4rt, simple_dot42(simple_dot24(F, C4), simple_trans2(F))), I4rt)
		K4 = simple_dot42(I4rt, S) + simple_dot24(F, simple_ddot44_v1(C4, simple_dot24(simple_trans2(F),I4rt)))
		return P, K4
