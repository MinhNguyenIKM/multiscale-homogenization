#!/usr/bin/env python2
import util.FileProcessing as fp
import numpy as np
inputpath  = './Job-7.inp'
outputpath = './100_inclusions_job-1-Q4.dat'
# fp.create_meshdata_from_abaqusfile(inputpath, outputpath)
fp.create_meshdata_fullscale_from_abaqusfile(inputpath, outputpath, 1,  400, 401, 3024)
# Check input
try:
 inputfile = open(inputpath, 'r')
except IOError as e:
 print("Can't open file :" + e.filename)
 exit()
# Open output file to write
outputfile = open(outputpath, 'a+')
displacementNode = np.array([101, 102, 805, 806, 807, 808, 809, 810, 811, 812, 813, 814, 815, 816, 817, 818, \
 819, 820, 821, 822, 823, 824, 825, 826, 827, 828])

tractionNode = np.array([103, 104, 928, 929, 930, 931, 932, 933, 934, 935, 936, 937, 938, 939, 940, 941, \
 942, 943, 944, 945, 946, 947, 948, 949, 950, 951])

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

