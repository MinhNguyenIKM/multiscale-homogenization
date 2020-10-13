import numpy as np
from microscale.fftgarlerkin.micro_setup_1 import *


#  -----------------------------------------------------------------------------
#               SAINT-VENANT model (Like HOOKS model in small strain)
#  -----------------------------------------------------------------------------
# identity tensor (single tensor)
identity = np.eye(2)
# identity tensors (grid)
I = np.einsum('ij,xy', identity, np.ones([Nx, Ny]))
I4 = np.einsum('ijkl,xy->ijklxy', np.einsum('il,jk', identity, identity), np.ones([Nx, Ny]))
I4rt = np.einsum('ijkl,xy->ijklxy', np.einsum('ik,jl', identity, identity), np.ones([Nx, Ny]))
I4s = (I4 + I4rt) / 2.
II = dyad22(I, I)
II4 = np.einsum('klmn,xy->klmnxy', np.einsum('km,ln', identity, identity), np.ones([Nx, Ny]))


# --------------------------------------------------------------------------


def constitutive_Saint_Venant(F, mu, kappa):
	C4 = (kappa * II) + 2.0 * mu * (I4s - 1.0 / 3.0 * II)
	S = ddot42(C4, 0.5 * (dot22(trans2(F), F) - I))
	P = dot22(F, S)
	K4 = dot24(S, I4) + ddot44(ddot44(I4rt, dot42(dot24(F, C4), trans2(F))), I4rt)
	return P, K4