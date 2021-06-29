#!/usr/bin/env python2
import util.FileProcessing as fp

input  = './Job-1.inp'
output = './cantileverbeam.dat'
fp.create_meshdata_from_abaqusfile(input, output)
