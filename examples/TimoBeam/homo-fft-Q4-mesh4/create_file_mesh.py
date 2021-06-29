#!/usr/bin/env python2
import util.FileProcessing as fp
import numpy as np
inputpath  = './Q4-mesh4-nn.inp'
outputpath = './TimoBeam_Q4_mesh4_nn.dat'
fp.create_meshdata_from_abaqusfile(inputpath, outputpath)

# Check input
try:
 inputfile = open(inputpath, 'r')
except IOError as e:
 print("Can't open file :" + e.filename)
 exit()
# Open output file to write
outputfile = open(outputpath, 'a+')
displacementNode = np.array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, \
                             24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43])

tractionNode = np.array([714, 713, 712, 711, 710, 709, 708, 707, 706, 705, 704, 703, 702, 701])

outputfile.write('<NodeConstraints>\r')

for i in displacementNode:
 strg1 = 'u[' + str(i - 1) + '] = 0;\r'
 outputfile.write(strg1)
 strg2 = 'v[' + str(i - 1) + '] = 0;\r'
 outputfile.write(strg2)

outputfile.write('</NodeConstraints>\r')

outputfile.write('<ExternalForces>\r')

for i in tractionNode:
 strg1 = 'u[' + str(i - 1) + '] = 0;\r'
 outputfile.write(strg1)
 strg2 = 'v[' + str(i - 1) + '] = -0.25;\r'
 outputfile.write(strg2)

outputfile.write('</ExternalForces>\r')

