#!/usr/bin/env python2
import util.FileProcessing as fp
import numpy as np
inputpath  = './T3-finer-homo-Job-2.inp'
outputpath = './TimoBeam_homo_T3_finer.dat'
fp.create_meshdata_from_abaqusfile(inputpath, outputpath)

# Check input
try:
 inputfile = open(inputpath, 'r')
except IOError as e:
 print("Can't open file :" + e.filename)
 exit()
# Open output file to write
outputfile = open(outputpath, 'a+')
displacementNode = np.array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26])

tractionNode = np.array([2626, 2625, 2624, 2623, 2622, 2621, 2620, 2619, 2618, 2617, 2616, 2615, 2614, 2613, 2612, 2611, 2610, 2609, 2608, 2607, 2606, 2605, 2604, 2603, 2602, 2601])

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

