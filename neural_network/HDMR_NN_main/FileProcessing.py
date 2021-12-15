import re
import numpy as np


def get_values(text):
    # Reference: # link: https://stackoverflow.com/questions/1185524/how-do-i-trim-whitespace
    # strip space, tab, end of row/file in both sides
    # line = line.strip(' \t\n\r')
    res = [re.sub('[( \n\r)+]', '', string).split('\t') for string in text]
    return np.array(res).astype(np.float)


def get_NN_parameters(filename):
    filename = 'H2Otest_2_NNs.dat'
    try:
        with open(filename) as f:
            content = np.array(f.readlines())
    except IOError as e:
        print("An error occurred trying to read the file: " + e.filename)
        exit()
        # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    idx = 0
    while idx < 4:
        line = content[idx]
        print(line)
        segments = get_values([line]).flatten()
        if segments.size == 0:
            continue
        if idx == 0:  # Processing the 1st line
            dimD = int(segments[0])  # dimensionality data
            dimd = int(segments[1])  # dimensionality reduction
            L = int(segments[2])  # Number of Network
            N = int(segments[3])  # Number of Neuron in each Network
            activation_func_type = int(segments[4])  # 1: tansig, 2: exponential
        elif idx == 1 or idx == 2:  # min and max values of coordinates
            if idx == 1:
                min_input = segments
            else:
                max_input = segments
        elif idx == 3:  # min and max values of data
            min_max_output = segments
        idx += 1
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    first_lines = idx
    k = first_lines
    group_line = first_lines + dimd + N + N + dimd + N + 1
    eof = len(content)
    i = 0
    while k < eof:
        # Transformation matrix A
        start = k
        stop = start + dimd
        if 'A' not in locals():
            A = np.empty((dimd, dimD, L))
        A[:, :, i] = get_values(content[start:stop])
        # Weight matrix w
        start = stop
        stop = start + N
        if 'w' not in locals():
            w = np.empty((N, dimd, L))
        w[:, :, i] = get_values(content[start:stop])
        # NN output weights cn
        start = stop
        stop = start + N
        if 'c' not in locals():
            c = np.empty((N, 1, L))
        c[:, :, i] = get_values(content[start:stop])
        # biases of the coordinate transformation b
        start = stop
        stop = start + dimd
        if 'b' not in locals():
            b = np.empty((dimd, 1, L))
        b[:, :, i] = get_values(content[start:stop])
        # neuron biases dn
        start = stop
        stop = start + N
        if 'd' not in locals():
            d = np.empty((N, 1, L))
        d[:, :, i] = get_values(content[start:stop])
        # output bias d0
        start = stop
        stop = start + 1
        if 'd0' not in locals():
            d0 = np.empty((1, 1, L))
        d0[:, :, i] = get_values(content[start:stop])
        # next component function
        k = k + (group_line - first_lines)
        i += 1
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    return dimD, dimd, L, N, activation_func_type, min_input, max_input, min_max_output, A, w, c, b, d, d0


if __name__ == '__main__':
    get_NN_parameters('H2Otest_2_NNs.dat')