from util import FileProcessing as fp
from numpy import dot, exp, ones


def tramnnmx(p, minp, maxp):
    return 2 * (p - minp) / (maxp - minp) - 1


def postmnmx(tn, mint, maxt):
    t = (tn + 1) / 2.0
    return t * (maxt - mint) + (mint * ones((len(t), 1)))


def postmnmx2(tn, mint, maxt):
    return tn * (maxt - mint) / 2.0

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
def derivative_activation(z):
    return 4 * exp(-2 * z) / (1 + exp(-2 * z)) ** 2


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
def cal_material_parameter(eps_macro, type):
    #eps_macro = eps_macro[0]
    if type == '1Dlinear':
        filename='Mechanics1D_1_NNs.dat'
    elif type == '1Dnonlinear':
        filename='Mechanics1D_Nonlinear_1_NNs.dat'
    dimD, dimd, L, N, activation_func_type, min_input, max_input, min_max_output, \
    A, w, c, b, d, d0 = fp.get_NN_parameters(filename)
    eps_macro = tramnnmx(eps_macro, min_input, max_input)
    sigma_macro = 0
    C_effective = 0
    for i in range(0, L):
        y = dot(A[:, :, i], eps_macro) + b[:, :, i]
        for n in range(0, N):
            z = dot(w[n, :, i], y) + d[n, :, i]
            zm = dot(w[n, :, i], y)
            sigma_macro += c[n, :, i] * dot(w[n, :, i], A[:, :, i]) * derivative_activation(z)
            C_effective += c[n, :, i] * dot(dot(w[n, :, i], A[:, :, i]), dot(w[n, :, i], A[:, :, i])) \
                           * 4 * ((-2 * exp(-2*z) / (1 + exp(-2*z)) ** 2) + (4 * exp(-4*z) / (1 + exp(-2*z)) ** 3))
    # return the real scale data
    sigma_macro = postmnmx2(sigma_macro, min_max_output[0], min_max_output[1])
    C_effective = postmnmx2(C_effective, min_max_output[0], min_max_output[1])
    return sigma_macro[0], C_effective[0]

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


def cal_C(eps_macro):
    eps_macro1 = eps_macro[0]
    eps_macro2 = eps_macro[0] + 0.05
    sigma_macro1, C1 = cal_material_parameter(eps_macro1)
    sigma_macro2, C2 = cal_material_parameter(eps_macro2)
    return (sigma_macro2 - sigma_macro1) / (eps_macro2 - eps_macro1)


if __name__ == '__main__':
    strain = [0]
    cal_material_parameter(strain)
