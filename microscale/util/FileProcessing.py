import re
import numpy as np
from microscale.fftstandard import micro1D

def get_values(text):
    # Reference: # link: https://stackoverflow.com/questions/1185524/how-do-i-trim-whitespace
    # strip space, tab, end of row/file in both sides
    # line = line.strip(' \t\n\r')
    res = [re.sub('[( \n\r)+]', '', string).split('\t') for string in text]
    return np.array(res).astype(np.float)


# ---------------------------------------------------------------------------------
#           Get values with split input
#       Create date: 17/09/2018
# ---------------------------------------------------------------------------------
def get_values_wsplit(text, splitter):
    # Reference: # link: https://stackoverflow.com/questions/1185524/how-do-i-trim-whitespace
    # strip space, tab, end of row/file in both sides
    # line = line.strip(' \t\n\r')
    res = re.sub('[( \t\n\r)+]', '', text).split(splitter)
    return np.array(res).astype(np.float)


def get_values_wsplit2(text, splitter):
    # Reference: # link: https://stackoverflow.com/questions/1185524/how-do-i-trim-whitespace
    # strip space, tab, end of row/file in both sides
    # line = line.strip(' \t\n\r')
    res = re.sub('[( \t\n\r)+]', '', text).split(splitter)
    return np.array(res)


def get_NN_parameters(filename):
    # filename = 'H2Otest_2_NN2s.dat'
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
        #print(line)
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


# -------------------------------------------------------------------------------
#       store data information in the  ingest-data step
# -------------------------------------------------------------------------------
def store_information(eps_macro, Energymacro, fileinput):
	try:
		# filename = 'training_data_1D_mechanics_nonlinear.dat'
		filename = fileinput
		f = open(filename, 'w+')
	except IOError as e:
		print("Can't open file :" + e.filename)
	for idx, eps_mac in enumerate(eps_macro):
		print(idx)
		x, k, diameter, eps_mic, sig_mic, strain_macro, stress_macro, C, energy_macro = micro1D.solve_micro_1d_nonlinear_fft(
			eps_mac)
		f.write("%0.12f\t%0.12f\n" % (eps_mac, energy_macro))
	f.close()


# --------------------------------------------------------------------------------
#       Read ABAQUS file and create input file for our programme
#   minh.nguyen@ikm.uni-hannover.de
#   Create date: 17/09/2019
# --------------------------------------------------------------------------------
def create_meshdata_from_abaqusfile(inputpath, outputpath):
	# Check input
	try:
		inputfile = open(inputpath, 'r')
	except IOError as e:
		print("Can't open file :" + e.filename)
		exit()
	# Open output file to write
	outputfile = open(outputpath, 'w+')
	while True:
		line = inputfile.readline()
		if line.startswith('*Node'):
			outputfile.write('<Nodes>\n')
			while True:
				line = inputfile.readline()
				if line.startswith('*Element'):
					outputfile.write('</Nodes>\n')
					outputfile.write('\n')
					outputfile.write('<Elements>\n')
					while True:
						line = inputfile.readline()
						if line.startswith('*'):
							outputfile.write('</Elements>\n')
							return
						resElm = get_values_wsplit(line, ',')
						resElm = resElm.astype(int) - 1
						elemID = resElm[0] + 1
						strrep = str(elemID) + '\t\t' + '\"ContElem\"' + '\t\t' + str(resElm[1]) + '\t\t' + str(resElm[2]) + \
									'\t\t' + str(resElm[3]) + '\t\t' + str(resElm[4]) + ';\r\n'
						outputfile.write(strrep)
				resNode = get_values_wsplit(line, ',')
				nodeID = int(resNode[0] - 1)
				strrep = str(nodeID) + '\t\t' + str(resNode[1]) + '\t\t' + str(resNode[2]) + ';\r\n'
				outputfile.write(strrep)
	inputfile.close()
	outputfile.close()


# --------------------------------------------------------------------------------
#       Read ABAQUS file and create input file for our programme
#   for full-scale calculation
#   minh.nguyen@ikm.uni-hannover.de
#   Create date: 29/10/2019
# --------------------------------------------------------------------------------
def create_meshdata_fullscale_from_abaqusfile(inputpath, outputpath, startElm1, endElm1, startElm2, endElm2):
	# Check input
	try:
		inputfile = open(inputpath, 'r')
	except IOError as e:
		print("Can't open file :" + e.filename)
		exit()
	# Open output file to write
	outputfile = open(outputpath, 'w+')
	while True:
		line = inputfile.readline()
		if line.startswith('*Node'):
			outputfile.write('<Nodes>\n')
			while True:
				line = inputfile.readline()
				if line.startswith('*Element'):
					outputfile.write('</Nodes>\n')
					outputfile.write('\n')
					outputfile.write('<Elements>\n')
					while True:
						line = inputfile.readline()
						if line.startswith('*'):
							outputfile.write('</Elements>\n')
							return
						resElm = get_values_wsplit(line, ',')
						resElm = resElm.astype(int) - 1
						if resElm[0] >= startElm1-1 and resElm[0] <= endElm1-1:
							elemID = resElm[0] + 1
							strrep = str(elemID) + '\t\t' + '\"ContElem1\"' + '\t\t' + str(resElm[1]) + '\t\t' + str(resElm[2]) + \
									'\t\t'  + str(resElm[3]) + ';\r\n'
							outputfile.write(strrep)
						elif resElm[0] >= startElm2-1 and resElm[0] <= endElm2-1:
							elemID = resElm[0] + 1
							strrep = str(elemID) + '\t\t' + '\"ContElem2\"' + '\t\t' + str(resElm[1]) + '\t\t' + str(
								resElm[2]) + '\t\t' + str(resElm[3]) + ';\r\n'
							outputfile.write(strrep)
				resNode = get_values_wsplit(line, ',')
				nodeID = int(resNode[0] - 1)
				strrep = str(nodeID) + '\t\t' + str(resNode[1]) + '\t\t' + str(resNode[2]) + ';\r\n'
				outputfile.write(strrep)
	inputfile.close()
	outputfile.close()


# --------------------------------------------------------------------------------
#       Create a perfect format as a data training file
#   minh.nguyen@ikm.uni-hannover.de
#   Create date: 28/09/2018
# --------------------------------------------------------------------------------
def create_data_training_file(infile, outfile):
	try:
		with open(infile) as f:
			content = np.array(f.readlines())
	except IOError as e:
		print("An error occurred trying to read the file: " + e.filename)
		exit()
	# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	eof = len(content)
	i = -1
	# Open output file to write
	outputfile = open(outfile, 'w+')
	while i < eof-1:
		i += 1
		line = content[i]
		# print(line)
		if re.search('#*[a-zA-Z]+', line):
			continue
		else:
			segments = get_values_wsplit2(line,';')
			if segments.size == 0:
				continue
			else:
				if segments[5].astype(float) > 1000:
					continue
				else:
					data = segments[1] + '\t' + segments[2] + '\t' + segments[3] + '\t' + segments[4] + '\t' + segments[5] + '\n'
					outputfile.write(data)
	outputfile.close()



