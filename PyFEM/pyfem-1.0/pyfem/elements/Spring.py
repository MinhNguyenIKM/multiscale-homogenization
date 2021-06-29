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
from pyfem.util.transformations import toElementCoordinates, toGlobalCoordinates

from numpy import zeros, eye, array

class Spring ( Element ):

  #Number of dofs per element
  dofTypes = ['u','v']

  def __init__ ( self, elnodes , props ):
    Element.__init__( self, elnodes , props )


  def __type__ ( self ):
    return name


  def getTangentStiffness ( self, elemdat ):
    
    #Compute the current state vector

    a  = toElementCoordinates( elemdat.state  , elemdat.coords )
    Da = toElementCoordinates( elemdat.Dstate , elemdat.coords )

    #Compute the elongation of the spring
    elong = a[2]-a[0] 

    #Compute the force in the spring
    Fs = elong * elemdat.props.k

    #Compute the element internal force vector in the element coordinate system
    elFint = array([-Fs,0.,Fs,0])

    #Determine the element tangent stiffness in the element coordinate system
    elKbar = zeros( (4,4) )

    elKbar[:2,:2] =  elemdat.props.k*eye(2)
    elKbar[:2,2:] = -elemdat.props.k*eye(2)

    elKbar[2:,:2] = elKbar[:2,2:]
    elKbar[2:,2:] = elKbar[:2,:2]

    #Rotate element tangent stiffness to the global coordinate system
    elemdat.stiff = toGlobalCoordinates( elKbar, elemdat.coords )
    elemdat.fint = toGlobalCoordinates( elFint, elemdat.coords )
  
#------------------------------------------------------------------

  def getInternalForce ( self, elemdat ):

    #Compute the current state vector

    a  = toElementCoordinates( elemdat.state  , elemdat.coords )
    Da = toElementCoordinates( elemdat.Dstate , elemdat.coords )

    #Compute the elongation of the spring
    elong = a[2]-a[0] 

    #Compute the force in the spring
    Fs = elong * elemdat.props.k

    #Compute the element internal force vector in the element coordinate system
    elFint = array([-Fs,0.,Fs,0])

    #Rotate element fint to the global coordinate system
    elemdat.fint = toGlobalCoordinates( elFint, elemdat.coords )
