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

from .Element import Element
from pyfem.util.shapeFunctions  import getElemShapeData
from pyfem.util.kinematics      import Kinematics
from numpy import zeros, dot, outer, ones , eye

class SmallStrainContinuum( Element ):

  #dofs per element
  dofTypes = [ 'u' , 'v' ]
  
  def __init__ ( self, elnodes , props ):
    Element.__init__( self, elnodes , props )

  def __type__ ( self ):
    return name

#------------------------------------------------------------------------

  def getTangentStiffness(self, element_data):
    sData = getElemShapeData(element_data.coords)
    kinematic = Kinematics(2, 3)
    element_data.outlabel.append("stresses")
    element_data.outdata = zeros(shape=(len(element_data.nodes), 3))
    for iData in sData:
      B_matrix = self.getBmatrix(iData.dhdx)
      kinematic.strain = dot(B_matrix, element_data.state)
      kinematic.dstrain = dot(B_matrix, element_data.Dstate)
      sigma, tangent_moduli = self.mat.getStress(kinematic)
      element_data.stiff += dot(B_matrix.transpose(), dot(tangent_moduli, B_matrix)) * iData.weight
      element_data.fint += dot(B_matrix.transpose(), sigma) * iData.weight
      element_data.outdata += outer(ones(len(element_data.nodes)), sigma)
    element_data.outdata *= 1.0 / len(sData)

#-------------------------------------------------------------------------

  def getInternalForce(self, element_data):
    sData = getElemShapeData(element_data.coords)
    element_data.outlabel.append("stresses")
    element_data.outlabel.append("stress_elements")
    element_data.stress_elements = zeros(shape=(len(element_data.nodes), 3), dtype=float)
    element_data.outdata = zeros(shape=(len(element_data.nodes), 3))
    kinematic = Kinematics(2, 3)
    for iData in sData:
      B_matrix = self.getBmatrix(iData.dhdx)
      kinematic.strain  = dot(B_matrix, element_data.state)
      kinematic.dstrain = dot(B_matrix, element_data.Dstate)
      sigma, tangentModuli = self.mat.getStress(kinematic)  #  Original code
      #sigma = self.mat.mat.sigma  # Minh's modification code
      element_data.fint    += dot(B_matrix.transpose(), sigma) * iData.weight
      element_data.outdata += outer(ones(len(self)), sigma)
      element_data.stress_elements += outer(ones(len(self)), sigma)
    element_data.outdata *= 1.0 / len(sData)
    element_data.stress_elements *= 1.0 / len(sData)

#----------------------------------------------------------------------
    
  def getMassMatrix ( self, elemdat ):
      
    sData = getElemShapeData( elemdat.coords )

    rho = self.rho * eye(2)

    for iData in sData:
      N  = self.getNmatrix( iData.h )
      Nt = N.transpose()

      elemdat.mass += dot ( Nt , dot( rho , N ) ) * iData.weight
      
    elemdat.lumped = sum(elemdat.mass)
   
#--------------------------------------------------------------------------

  def getBmatrix( self , dphi ):

    b = zeros( shape=( 3 , self.dofCount() ) )

    for i,dp in enumerate(dphi):
      b[0,i*2  ] = dp[0]
      b[1,i*2+1] = dp[1]
      b[2,i*2  ] = dp[1]
      b[2,i*2+1] = dp[0]
   
    return b

#------------------------------------------------------------------------------

  def getNmatrix( self , h ):

    N = zeros( shape=( 2 , 2*len(h) ) )

    for i,a in enumerate( h ):
      N[0,2*i  ] = a
      N[1,2*i+1] = a
   
    return N
