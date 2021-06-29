#!/usr/bin/env python2
import util.FileProcessing as fp
import numpy as np
inputpath  = './Job-1.inp'
outputpath = './TimoBeam_2scale.dat'
# fp.create_meshdata_from_abaqusfile(inputpath, outputpath)

# Check input
try:
 inputfile = open(inputpath, 'r')
except IOError as e:
 print("Can't open file :" + e.filename)
 exit()
# Open output file to write
outputfile = open(outputpath, 'a+')
displacementNode = np.array([1, 2, 3, 4, 5, 6])

tractionNode = np.array([121, 122, 123, 124, 125, 126])

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
 strg2 = 'v[' + str(i - 1) + '] = -0.5;\r'
 outputfile.write(strg2)

outputfile.write('</ExternalForces>\r')

