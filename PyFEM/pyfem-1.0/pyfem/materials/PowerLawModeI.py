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

from pyfem.materials.BaseMaterial import BaseMaterial
from numpy import zeros
from math  import exp 

class PowerLawModeI( BaseMaterial ):

  def __init__ ( self, props ):

    #Call the BaseMaterial constructor
    BaseMaterial.__init__( self, props )

    self.deltan  = self.Gc / ( exp(1.0) * self.Tult )
    self.deltan2 = self.deltan *self.deltan
    self.deltan3 = self.deltan2*self.deltan

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------

  def getStress( self, deformation ):
 
   stress = zeros( 2 )
   tang   = zeros( (2,2) )

   jump = deformation.strain[0]

   stress[0] = self.Gc/self.deltan2*exp(-jump/self.deltan)*jump
   tang[0,0] = self.Gc/self.deltan2*exp(-jump/self.deltan)*(1.0-jump/self.deltan)

   return stress,tang
