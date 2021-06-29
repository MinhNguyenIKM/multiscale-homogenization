#!/usr/bin/env python
import numpy as np

#  lambda1 = 1; lambda2= 2
#  mu1 = 1; mu2 = 2
#
# E_phase1 = np.array([[7.0/450], [1.0/50], [0]]);
# E_phase2 = np.array([[1.0/225], [1.0/50], [0]]);
# C_phase1 = np.array([[3, 1, 0], [1, 3, 0], [0, 0, 1]]);
# C_phase2 = np.array([[6, 2, 0], [2, 6, 0], [0, 0, 0]]);
# S_phase1 = np.dot(C_phase1, E_phase1);
# S_phase2 = np.dot(C_phase2, E_phase2);
# print('End of Test')
# dE = 10e-7
#
#
# E_avg = 0.5 * (E_phase1 + E_phase2)
# S_avg = 0.5 * (S_phase1 + S_phase2)
# S_avg_1 = S_avg[0]
# S_avg_2 = S_avg[1]
# S_avg_3 = S_avg[2]
# E_avg_1 = E_avg[0]
# E_avg_2 = E_avg[1]
# E_avg_3 = E_avg[2]
#
#
# E_phase1 = np.array([[7.0/450 + dE], [1.0/50], [0]]);
# E_phase2 = np.array([[1.0/225 + dE], [1.0/50], [0]]);
# C_phase1 = np.array([[3, 1, 0], [1, 3, 0], [0, 0, 1]]);
# C_phase2 = np.array([[6, 2, 0], [2, 6, 0], [0, 0, 0]]);
# S_phase1 = np.dot(C_phase1, E_phase1);
# S_phase2 = np.dot(C_phase2, E_phase2);
#
# E_avg_plus = 0.5 * (E_phase1 + E_phase2)
# S_avg_plus = 0.5 * (S_phase1 + S_phase2)
# S_avg_1_plus = S_avg_plus[0]
# E_avg_1_plus = E_avg_plus[0]
# C_eff_11 = (S_avg_1_plus - S_avg_1) / (E_avg_1_plus - E_avg_1)
# print('End of Test C_eff_11')
#
#
# E_phase1 = np.array([[7.0/450], [1.0/50 + dE], [0]]);
# E_phase2 = np.array([[1.0/225], [1.0/50 + dE], [0]]);
# C_phase1 = np.array([[3, 1, 0], [1, 3, 0], [0, 0, 1]]);
# C_phase2 = np.array([[6, 2, 0], [2, 6, 0], [0, 0, 0]]);
# S_phase1 = np.dot(C_phase1, E_phase1);
# S_phase2 = np.dot(C_phase2, E_phase2);
#
# E_avg_plus = 0.5 * (E_phase1 + E_phase2)
# S_avg_plus = 0.5 * (S_phase1 + S_phase2)
# S_avg_2_plus = S_avg_plus[1]
# E_avg_2_plus = E_avg_plus[1]
# C_eff_22 = (S_avg_2_plus - S_avg_2) / (E_avg_2_plus - E_avg_2)
# print('End of Test C_eff_22')
#
# E_phase1 = np.array([[7.0/450], [1.0/50], [0 + dE]]);
# E_phase2 = np.array([[1.0/225], [1.0/50], [0 + dE]]);
# C_phase1 = np.array([[3, 1, 0], [1, 3, 0], [0, 0, 1]]);
# C_phase2 = np.array([[6, 2, 0], [2, 6, 0], [0, 0, 0]]);
# S_phase1 = np.dot(C_phase1, E_phase1);
# S_phase2 = np.dot(C_phase2, E_phase2);
#
# E_avg_plus = 0.5 * (E_phase1 + E_phase2)
# S_avg_plus = 0.5 * (S_phase1 + S_phase2)
# S_avg_3_plus = S_avg_plus[2]
# E_avg_3_plus = E_avg_plus[2]
# C_eff_33 = (S_avg_3_plus - S_avg_3) / (E_avg_3_plus - E_avg_3)
# C_eff_12 = (S_avg_1_plus - S_avg_1) / (E_avg_2_plus - E_avg_2)
# C_eff_13 = (S_avg_1_plus - S_avg_1) / (E_avg_3_plus - E_avg_3)
# C_eff_21 = (S_avg_2_plus - S_avg_2) / (E_avg_1_plus - E_avg_1)
# C_eff_23 = (S_avg_2_plus - S_avg_2) / (E_avg_3_plus - E_avg_3)
# C_eff_31 = (S_avg_3_plus - S_avg_3) / (E_avg_1_plus - E_avg_1)
# C_eff_32 = (S_avg_3_plus - S_avg_3) / (E_avg_2_plus - E_avg_2)
# C_eff = np.zeros([3, 3])
# C_eff[0,0] = C_eff_11
# C_eff[0,1] = C_eff_12
# C_eff[0,2] = C_eff_13
# C_eff[1,0] = C_eff_21
# C_eff[1,1] = C_eff_22
# C_eff[1,2] = C_eff_23
# C_eff[2,0] = C_eff_31
# C_eff[2,1] = C_eff_32
# C_eff[2,2] = C_eff_33
#
# print('End of Test C_eff_33')

lambda1 = 1
lambda2 = 2
mu1 = 1
mu2 = 2
A = np.array([[lambda1 + 2*mu1, lambda1, 0, -(lambda2 + 2*mu2), -lambda2, 0], \
            [0, 0, 2*mu1, 0, 0 , -2*mu2], \
            [0, 1, 0, 0, -1, 0], \
            [0.5, 0, 0, 0.5, 0, 0], \
            [0, 0.5, 0, 0, 0.5, 0], \
            [0, 0, 0.5, 0, 0, 0.5]])

eps_avg_11 = 1.0/100
eps_avg_22 = 2.0/100
eps_avg_12 = 2*0
b = np.array([[0],[0],[0],[eps_avg_11],[eps_avg_22],[eps_avg_12]])
x = np.linalg.solve(A, b)
print("-----------------------------------------------")
print(x)
E_phase1 = x[0:3, 0]
E_phase2 = x[3:6, 0]
C_phase1 = np.array([[3, 1, 0], [1, 3, 0], [0, 0, 1]]);
C_phase2 = np.array([[6, 2, 0], [2, 6, 0], [0, 0, 0]]);
S_phase1 = np.dot(C_phase1, E_phase1);
S_phase2 = np.dot(C_phase2, E_phase2);
E_avg = 0.5 * (E_phase1 + E_phase2)
S_avg = 0.5 * (S_phase1 + S_phase2)


dE = 10e-6

eps_avg_11 = 1.0/100 + dE
eps_avg_22 = 2.0/100
eps_avg_12 = 2*0
b = np.array([[0],[0],[0],[eps_avg_11],[eps_avg_22],[eps_avg_12]])
x = np.linalg.solve(A, b)
print("-----------------------------------------------")
print(x)
E_phase1 = x[0:3, 0]
E_phase2 = x[3:6, 0]
C_phase1 = np.array([[3, 1, 0], [1, 3, 0], [0, 0, 1]]);
C_phase2 = np.array([[6, 2, 0], [2, 6, 0], [0, 0, 0]]);
S_phase1 = np.dot(C_phase1, E_phase1);
S_phase2 = np.dot(C_phase2, E_phase2);
E_avg_plus1 = 0.5 * (E_phase1 + E_phase2)
S_avg_plus1 = 0.5 * (S_phase1 + S_phase2)

eps_avg_11 = 1.0/100 - dE
eps_avg_22 = 2.0/100
eps_avg_12 = 2*0
b = np.array([[0],[0],[0],[eps_avg_11],[eps_avg_22],[eps_avg_12]])
x = np.linalg.solve(A, b)
print("-----------------------------------------------")
print(x)
E_phase1 = x[0:3, 0]
E_phase2 = x[3:6, 0]
C_phase1 = np.array([[3, 1, 0], [1, 3, 0], [0, 0, 1]]);
C_phase2 = np.array([[6, 2, 0], [2, 6, 0], [0, 0, 0]]);
S_phase1 = np.dot(C_phase1, E_phase1);
S_phase2 = np.dot(C_phase2, E_phase2);
E_avg_minus1 = 0.5 * (E_phase1 + E_phase2)
S_avg_minus1 = 0.5 * (S_phase1 + S_phase2)

eps_avg_11 = 1.0/100
eps_avg_22 = 2.0/100 + dE
eps_avg_12 = 2*0
b = np.array([[0],[0],[0],[eps_avg_11],[eps_avg_22],[eps_avg_12]])
x = np.linalg.solve(A, b)
print("-----------------------------------------------")
print(x)
E_phase1 = x[0:3, 0]
E_phase2 = x[3:6, 0]
C_phase1 = np.array([[3, 1, 0], [1, 3, 0], [0, 0, 1]]);
C_phase2 = np.array([[6, 2, 0], [2, 6, 0], [0, 0, 0]]);
S_phase1 = np.dot(C_phase1, E_phase1);
S_phase2 = np.dot(C_phase2, E_phase2);
E_avg_plus2 = 0.5 * (E_phase1 + E_phase2)
S_avg_plus2 = 0.5 * (S_phase1 + S_phase2)


eps_avg_11 = 1.0/100
eps_avg_22 = 2.0/100 - dE
eps_avg_12 = 2*0
b = np.array([[0],[0],[0],[eps_avg_11],[eps_avg_22],[eps_avg_12]])
x = np.linalg.solve(A, b)
print("-----------------------------------------------")
print(x)
E_phase1 = x[0:3, 0]
E_phase2 = x[3:6, 0]
C_phase1 = np.array([[3, 1, 0], [1, 3, 0], [0, 0, 1]]);
C_phase2 = np.array([[6, 2, 0], [2, 6, 0], [0, 0, 0]]);
S_phase1 = np.dot(C_phase1, E_phase1);
S_phase2 = np.dot(C_phase2, E_phase2);
E_avg_minus2 = 0.5 * (E_phase1 + E_phase2)
S_avg_minus2 = 0.5 * (S_phase1 + S_phase2)

eps_avg_11 = 1.0/100
eps_avg_22 = 2.0/100
eps_avg_12 = 2*(0 + dE)
b = np.array([[0],[0],[0],[eps_avg_11],[eps_avg_22],[eps_avg_12]])
x = np.linalg.solve(A, b)
print("-----------------------------------------------")
print(x)
E_phase1 = x[0:3, 0]
E_phase2 = x[3:6, 0]
C_phase1 = np.array([[3, 1, 0], [1, 3, 0], [0, 0, 1]]);
C_phase2 = np.array([[6, 2, 0], [2, 6, 0], [0, 0, 0]]);
S_phase1 = np.dot(C_phase1, E_phase1);
S_phase2 = np.dot(C_phase2, E_phase2);
E_avg_plus3 = 0.5 * (E_phase1 + E_phase2)
S_avg_plus3 = 0.5 * (S_phase1 + S_phase2)


eps_avg_11 = 1.0/100
eps_avg_22 = 2.0/100
eps_avg_12 = 2*(0 - dE)
b = np.array([[0],[0],[0],[eps_avg_11],[eps_avg_22],[eps_avg_12]])
x = np.linalg.solve(A, b)
print("-----------------------------------------------")
print(x)
E_phase1 = x[0:3, 0]
E_phase2 = x[3:6, 0]
C_phase1 = np.array([[3, 1, 0], [1, 3, 0], [0, 0, 1]]);
C_phase2 = np.array([[6, 2, 0], [2, 6, 0], [0, 0, 0]]);
S_phase1 = np.dot(C_phase1, E_phase1);
S_phase2 = np.dot(C_phase2, E_phase2);
E_avg_minus3 = 0.5 * (E_phase1 + E_phase2)
S_avg_minus3 = 0.5 * (S_phase1 + S_phase2)

C_eff = np.zeros([3, 3])
C_eff[0, 0] = (S_avg_plus1[0] - S_avg_minus1[0]) / (E_avg_plus1[0] - E_avg_minus1[0])
C_eff[0, 1] = (S_avg_plus2[0] - S_avg_minus2[0]) / (E_avg_plus2[1] - E_avg_minus2[1])
C_eff[0, 2] = (S_avg_plus3[0] - S_avg_minus3[0]) / (E_avg_plus3[2] - E_avg_minus3[2]) * 2
C_eff[1, 0] = (S_avg_plus1[1] - S_avg_minus1[1]) / (E_avg_plus1[0] - E_avg_minus1[0])
C_eff[1, 1] = (S_avg_plus2[1] - S_avg_minus2[1]) / (E_avg_plus2[1] - E_avg_minus2[1])
C_eff[1, 2] = (S_avg_plus3[1] - S_avg_minus3[1]) / (E_avg_plus3[2] - E_avg_minus3[2]) * 2
C_eff[2, 0] = (S_avg_plus1[2] - S_avg_minus1[2]) / (E_avg_plus1[0] - E_avg_minus1[0])
C_eff[2, 1] = (S_avg_plus2[2] - S_avg_minus2[2]) / (E_avg_plus2[1] - E_avg_minus2[1])
C_eff[2, 2] = (S_avg_plus3[2] - S_avg_minus3[2]) / (E_avg_plus3[2] - E_avg_minus3[2]) * 2
print("-----------------------------------------------")
print(C_eff)

C_eff2 = np.zeros([3, 3])
C_eff2[0, 0] = (S_avg_plus1[0] - S_avg_minus1[0]) / (2*dE)
C_eff2[0, 1] = (S_avg_plus2[0] - S_avg_minus2[0]) / (2*dE)
C_eff2[0, 2] = (S_avg_plus3[0] - S_avg_minus3[0]) / (2*dE)
C_eff2[1, 0] = (S_avg_plus1[1] - S_avg_minus1[1]) / (2*dE)
C_eff2[1, 1] = (S_avg_plus2[1] - S_avg_minus2[1]) / (2*dE)
C_eff2[1, 2] = (S_avg_plus3[1] - S_avg_minus3[1]) / (2*dE)
C_eff2[2, 0] = (S_avg_plus1[2] - S_avg_minus1[2]) / (2*dE)
C_eff2[2, 1] = (S_avg_plus2[2] - S_avg_minus2[2]) / (2*dE)
C_eff2[2, 2] = (S_avg_plus3[2] - S_avg_minus3[2]) / (2*dE)
print("-----------------------------------------------")
print(C_eff2)