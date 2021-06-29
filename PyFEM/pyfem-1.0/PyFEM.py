############################################################################
#  This Python file is part of PyFEM-1.0, released on Aug. 29, 2012.       #
#  The PyFEM code accompanies the book:                                    #
#                                                                          #
#    'Non-Linear Finite Element Analysis of Solids and Structures'         #
#    R. de Borst, M.A. Crisfield, J.J.C. Remmers and C.V. Verhoosel        #
#    John Wiley and Sons, 2012, ISBN 978-0470666449                        #
#                                                                          #
#  The code is written by J.J.C. Remmers, C.V. Verhoosel and R. de Borst.  #
#  Comments and suggestions can be sent to:                                #
#     PyFEM-support@tue.nl                                                 #
#                                                                          #
#  The latest version can be downloaded from the web-site:                 #                                                                          
#     http://www.wiley.com/go/deborst                                      #
#                                                                          #
#  The code is open source and intended for educational and scientific     #
#  purposes only. If you use PyFEM in your research, the developers would  #
#  be grateful if you could cite the book.                                 #  
#                                                                          #
#  Disclaimer:                                                             #
#  The authors reserve all rights but do not guarantee that the code is    #
#  free from errors. Furthermore, the authors shall not be liable in any   #
#  event caused by the use of the program.                                 #
############################################################################


from pyfem.io.InputReader   import InputReader
from pyfem.io.OutputManager import OutputManager

from pyfem.solvers.Solver   import Solver

import sys

#sys.argv[0] = '/home/minh/Dropbox/HOMOGENIZATION/PyFEM/pyfem-1.0/PyFEM.py'
#sys.argv[0] = '/home/minh/Dropbox/HOMOGENIZATION/PyFEM/pyfem-1.0/examples/ch03/cantilever8.pro'
#sys.argv[0] = './examples/ch03/cantilever8.pro'
# sys.argv = ['/home/minh/Dropbox/HOMOGENIZATION/PyFEM/pyfem-1.0/PyFEM.py', './examples/ch02/PatchTest3.pro']
# sys.argv = ['/home/minh/Dropbox/HOMOGENIZATION/PyFEM/pyfem-1.0/PyFEM.py', './examples/timoshenkobeam/timoshenkobeam.pro']
# sys.argv = ['/home/minh/Dropbox/HOMOGENIZATION/PyFEM/pyfem-1.0/PyFEM.py', './examples/homogenization/HomoLinear2D.pro']
# sys.argv = ['/home/minh/Dropbox/HOMOGENIZATION/PyFEM/pyfem-1.0/PyFEM.py', './examples/ch06/ContDamExample.pro']
# sys.argv = ['/home/minh/Dropbox/HOMOGENIZATION/PyFEM/pyfem-1.0/PyFEM.py', './examples/timoshenkobeam/timoshenkobeam_nl.pro']
# sys.argv = ['/home/minh/Dropbox/HOMOGENIZATION/PyFEM/pyfem-1.0/PyFEM.py', './examples/cantileverbeam/homogenization_beam.pro']
# sys.argv = ['/home/minh/Dropbox/HOMOGENIZATION/PyFEM/pyfem-1.0/PyFEM.py', './examples/cantileverbeam/homo_beam_nonlinear.pro']
sys.argv = ['/home/minh/Dropbox/HOMOGENIZATION/PyFEM/pyfem-1.0/PyFEM.py', '/home/minh/Dropbox/HOMOGENIZATION/PyFEM/pyfem-1.0/examples/ch03/cantilever8.pro']
properties, global_data = InputReader( sys.argv )
#print(sys.argv)
#exit()
solver = Solver(properties, global_data)
output = OutputManager(properties, global_data)

while global_data.active:
  solver.run(properties, global_data)
  output.run(properties, global_data)


print "PyFem analysis terminated successfully."



