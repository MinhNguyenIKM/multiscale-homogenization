#!/usr/bin/env python2
import util.FileProcessing as fp

input  = './Cook.inp'
output = './Cook.dat'
fp.create_meshdata_from_abaqusfile(input, output)
