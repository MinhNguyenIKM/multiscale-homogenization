#!/usr/bin/env python2
import util.FileProcessing as fp
import numpy as np
inputpath  = './T3-finer-homo-Job-1.inp'
outputpath = './TimoBeam_homo_T3.dat'
fp.create_meshdata_from_abaqusfile(inputpath, outputpath)

# Check input
try:
 inputfile = open(inputpath, 'r')
except IOError as e:
 print("Can't open file :" + e.filename)
 exit()
# Open output file to write
outputfile = open(outputpath, 'a+')
displacementNode = np.array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14])

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

