import FileProcessing as fp
import numpy as np
from numpy import dot, exp
from matplotlib import pyplot

def tansig(n):
    return (2.0 / (1 + exp(-2 * n)) - 1)


def tramnnmx(p, minp, maxp):
    return 2 * (p - minp) / (maxp - minp) - 1;


def postmnmx(tn, mint, maxt):
    t = (tn + 1) / 2.0
    return t * (maxt - mint) + (mint * np.ones((len(t), 1)))


dimD, dimd, L, N, activation_func_type, min_input, max_input, min_max_output, A, w, c, b, d, d0 = \
    fp.get_NN_parameters(filename='Xsquaretest_3_NNs.dat')

X1 = np.arange(-3.5, 3.5+0.1, 0.1)
X2 = X1
X3 = X1
X4 = X1
X5 = X1
X6 = X1
X = np.vstack((X1, X2, X3, X4, X5, X6)).T
fNN_predict = np.zeros((len(X), 1))
f_exact = np.zeros((len(X), 1))
for idx in range(0, len(X)):
    x = X[idx, 0:dimD].reshape(dimD, 1)
    x = tramnnmx(x, -1, 1)
    f_exact[idx, 0] = x[0]**2 + x[1]**2 + x[2]**2 + x[3]**2 + x[4]**2 + x[5]**2
    for i in range(0, L):
        y = dot(A[:, :, i], x) + b[:, :, i]
        for n in range(0, N):
            fNN_predict[idx, 0] += c[n, 0, i] * tansig(dot(w[n, :, i], y) + d[n, 0, i])
        fNN_predict[idx, 0] += d0[0, 0, i]

fNN_predict[:, :] = postmnmx(fNN_predict, min_max_output[0], min_max_output[1])


pyplot.plot(X1, fNN_predict, 'ro')
pyplot.plot(X1, f_exact, 'b')
pyplot.show()

print(fNN_predict)