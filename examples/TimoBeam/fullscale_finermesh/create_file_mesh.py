#!/usr/bin/env python2
import util.FileProcessing as fp
import numpy as np
inputpath  = './Job-1.inp'
outputpath = './TimoBeam_fullscale.dat'
# fp.create_meshdata_fullscale_from_abaqusfile(inputpath, outputpath, 1, 4800, 4801, 22900)

# Check input
try:
 inputfile = open(inputpath, 'r')
except IOError as e:
 print("Can't open file :" + e.filename)
 exit()
# Open output file to write
outputfile = open(outputpath, 'a+')
displacementNode = np.array([401,  402, 3205, 3206, 3207, 3208, 3209, 3210, 3211, 3212, 3213, 3214, 3215, 3216, 3217, 3218, \
 3219, 3220, 3221, 3222, 3223, 3224, 3225, 3226, 3227, 3228])

tractionNode = np.array([403,  404, 3328, 3329, 3330, 3331, 3332, 3333, 3334, 3335, 3336, 3337, 3338, 3339, 3340, 3341, \
 3342, 3343, 3344, 3345, 3346, 3347, 3348, 3349, 3350, 3351])

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

