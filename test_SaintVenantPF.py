#!/usr/bin/env python2
from pyfem.io.InputReader import InputReader
from pyfem.io.OutputManager import OutputManager
from pyfem.solvers.Solver import Solver
import sys
import os
import numpy as np
# np.set_printoptions(precision=15)
pathname = os.path.dirname(sys.argv[0])
filename = os.path.basename(__file__)
param1 = pathname + '/' + filename
param2 = pathname + '/examples/hyperelasticityPF/hyperelasticity.pro'
sys.argv = [param1, param2]
properties, global_data = InputReader(sys.argv)
#print(sys.argv)
#exit()
solver = Solver(properties, global_data)
output = OutputManager(properties, global_data)
while global_data.active:
  solver.run(properties, global_data)
  output.run(properties, global_data)
print "PyFem analysis terminated successfully."
