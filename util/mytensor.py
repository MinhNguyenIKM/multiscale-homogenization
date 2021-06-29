# ---------------------------------------------------------------------------------
# My self-defined tensor utilities
# Create date: 07/09/2018
# Author: minh.nguyen@ikm.uni-hannover.de
# ---------------------------------------------------------------------------------
import numpy as np


#  -----------------------------------------------------------------------------
#         Double dot product of a 4th-order tensor and 2nd-order tensor - ver 1
#  -----------------------------------------------------------------------------
def ddot42_v1(A4, B2): return np.einsum('ijklxy,klxy->ijxy', A4, B2)
def simple_ddot42_v1(A4, B2): return np.einsum('ijkl,kl->ij', A4, B2)


#  -----------------------------------------------------------------------------
#         Double dot product of a 4th-order tensor and 2nd-order tensor - ver 2
#  -----------------------------------------------------------------------------
def ddot42_v2(A4, B2): return np.einsum('ijklxy,ijxy->klxy', A4, B2)
def simple_ddot42_v2(A4, B2): return np.einsum('ijkl,ij->kl', A4, B2)


#  -----------------------------------------------------------------------------
#                 Transpose of a 2nd-order tensor
#  -----------------------------------------------------------------------------
def trans2(A2):	return np.einsum('ijxy->jixy', A2)
def simple_trans2(A2):	return np.einsum('ij->ji', A2)


#  -----------------------------------------------------------------------------
#           Double dot product of a 2nd-order tensor and 2nd-order tensor
#  -----------------------------------------------------------------------------
def ddot22(A2, B2):	return np.einsum('ijxy,jixy->xy', A2, B2)
def simple_ddot22(A2, B2):	return np.einsum('ij,ji->', A2, B2)*1


#  -----------------------------------------------------------------------------
#                 DYADIC product of 2 second-order tensors
#  -----------------------------------------------------------------------------
def dyad22(A2, B2):	return np.einsum('ijxy,klxy->ijklxy', A2, B2)
def simple_dyad22(A2, B2):	return np.einsum('ij,kl->ijkl', A2, B2)


#  -----------------------------------------------------------------------------
#
#  -----------------------------------------------------------------------------
def delta(i, j): return np.float(i == j)


#  -----------------------------------------------------------------------------
#
#  -----------------------------------------------------------------------------
def ddot42(A4, B2):	return np.einsum('ijklxy,lkxy->ijxy', A4, B2)
def simple_ddot42(A4, B2):	return np.einsum('ijkl,lk->ij', A4, B2)


#  -----------------------------------------------------------------------------
#
#  -----------------------------------------------------------------------------
def dot22(A2, B2): return np.einsum('ijxy,jkxy->ikxy', A2, B2)
def simple_dot22(A2, B2): return np.einsum('ij,jk->ik', A2, B2)


#  -----------------------------------------------------------------------------
#
#  -----------------------------------------------------------------------------
def dot24(A2, B4): return np.einsum('ijxy,jkmnxy->ikmnxy', A2, B4)
def simple_dot24(A2, B4): return np.einsum('ij,jkmn->ikmn', A2, B4)


#  -----------------------------------------------------------------------------
#   Double dot product of a 4th-order tensor and 4nd-order tensor - ver 0 (original in Zeman paper)
#  -----------------------------------------------------------------------------
def ddot44(A4, B4): return np.einsum('ijklxy,lkmnxy->ijmnxy', A4, B4)
def simple_ddot44(A4, B4): return np.einsum('ijkl,lkmn->ijmn', A4, B4)


#  -----------------------------------------------------------------------------
#   Double dot product of a 4th-order tensor and 4nd-order tensor - ver 1
#  -----------------------------------------------------------------------------
def ddot44_v1(A4, B4): return np.einsum('ijklxy,klmnxy->ijmnxy', A4, B4)
def simple_ddot44_v1(A4, B4): return np.einsum('ijkl,klmn->ijmn', A4, B4)


#  -----------------------------------------------------------------------------
#
#  -----------------------------------------------------------------------------
def dot42(A4, B2): return np.einsum('ijklxy, lmxy->ijkmxy', A4, B2)
def simple_dot42(A4, B2): return np.einsum('ijkl, lm->ijkm', A4, B2)


#  -----------------------------------------------------------------------------
#   Double dot product of a 2th-order tensor and 4nd-order tensor - ver 1
#  -----------------------------------------------------------------------------
def ddot24_v1(B2, A4): return np.einsum('ijxy, ijklxy->klxy', B2, A4)
def simple_ddot24_v1(B2, A4): return np.einsum('ij, ijkl->kl', B2, A4)


#  -----------------------------------------------------------------------------
# 	Trace of a 2nd-order tensor
#  -----------------------------------------------------------------------------
def trace2(A2): return np.einsum('iixy', A2)

dot11  = lambda A1,B1: np.einsum('ixy   ,ixy   ->xy    ',A1,B1)
dyad11 = lambda A1,B1: np.einsum('ixy   ,jxy   ->ijxy  ',A1,B1)


