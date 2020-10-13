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

from pyfem.util.BaseModule import BaseModule

from numpy import zeros, array
from pyfem.fem.Assembly import assembleInternalForce, assembleTangentStiffness
import numpy as np
import sys

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------

class NonlinearSolver( BaseModule ):

  def __init__( self , props , globdat ):

    self.tol      = 1.0e-3
    self.iterMax  = 10 

    self.maxCycle = sys.maxint
    self.maxLam   = 1.0e20

    BaseModule.__init__( self , props )

    globdat.lam = 0.0

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------

  def run( self , props , globdat ):
    globdat.cycle += 1
    globdat.lam = 1.0 * globdat.cycle
    dofCount = len(globdat.dofs)

    a_0   = np.copy(globdat.state)  # minh
    a     = globdat.state
    Da    = globdat.Dstate
    fhat  = globdat.fhat

    Da[:] = zeros( dofCount )
    fint  = zeros( dofCount ) 
    fext  = globdat.lam * fhat

    print '================================='
    print ' Load step %i' % globdat.cycle
    print '================================='
    print '  NR iter : L2-norm residual'
     
    globdat.iiter = 0
    K, fint = assembleTangentStiffness( props, globdat )
    error = 1.

    while error > self.tol:
      globdat.iiter += 1
      da = globdat.dofs.solve(K, fext - fint)
      Da[:] += da[:]
      a [:] += da[:]
      K, fint = assembleTangentStiffness( props, globdat )
      # note that the code is different from the one presented in the book, which
      # is slightly shorter for the sake of clarity.
      # In the case of a prescribed displacement, the external force is zero
      # and hence its norm is zero. In that case, the norm of the residue is not
      # divided by the norm of the external force.

      # norm = globdat.dofs.norm(fext)  # minh commented
      Du_norm_tuso = np.linalg.norm(da)  # minh
      Du_norm_mauso = np.linalg.norm(a - a_0)  # minh
      error = Du_norm_tuso / Du_norm_mauso  # minh

      # minh commented this block of code
      # if norm < 1.0e-16:
      #   error = globdat.dofs.norm(fext - fint)
      # else:
      #   error = globdat.dofs.norm(fext - fint) / norm

      print '  Iter', globdat.iiter, ':', error
      if globdat.iiter == self.iterMax:
        raise RuntimeError('Newton-Raphson iterations did not converge!')
    # Converged
    globdat.elements.commitHistory()
    # print("------------- DU ---------------")
    # print(Da)
    Da[:]  = zeros( len(globdat.dofs) )
    globdat.fint = fint
    if globdat.cycle == self.maxCycle or globdat.lam > self.maxLam:
      globdat.active = False 
      
