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

from numpy import zeros, ones, ix_
from pyfem.util.dataStructures import Properties
from pyfem.util.dataStructures import elementData


#######################################
# General array assembly routine for: # 
# * assembleInternalForce             #
# * assembleTangentStiffness          #
#######################################

def assembleArray ( props, globalData, rank, action ):

  #Initialize the global array A with rank 2

  A = zeros( len(globalData.dofs) * ones(2,dtype=int) )
  B = zeros( len(globalData.dofs) * ones(1,dtype=int) )

  globalData.resetNodalOutput()

  #Loop over the element groups
  for elementGroup in globalData.elements.iterGroupNames():

    #Get the properties corresponding to the elementGroup
    el_props = getattr( props, elementGroup )

    #Loop over the elements in the elementGroup
    for (elmID, element) in enumerate(globalData.elements.iterElementGroup(elementGroup)):

      #Get the element nodes
      el_nodes = element.getNodes()

      #Get the element coordinates
      el_coords = globalData.nodes.getNodeCoords( el_nodes )

      #Get the element degrees of freedom
      el_dofs = globalData.dofs.get( el_nodes )

      #Get the element state
      el_a  = globalData.state [el_dofs]
      el_Da = globalData.Dstate[el_dofs]

      #Create the an element state to pass through to the element
      #el_state = Properties( { 'state' : el_a, 'Dstate' : el_Da } )
      elmData = elementData( el_a , el_Da )

      elmData.coords   = el_coords
      elmData.nodes    = el_nodes
      elmData.props    = el_props

      if hasattr( element , "matProps" ):
        elmData.matprops = element.matProps

      if hasattr( element , "mat" ):
        element.mat.reset()

      # Get the element contribution by calling the specified action
      getattr(element, action)(elmData)

      for label in elmData.outlabel:
        element.appendNodalOutput(label, globalData, elmData.outdata)

      # if action is "getInternalForce":
      #   for label in elmData.outlabel:
      #     if label is "stresses":
      #       element.appendNodalOutput(label, globalData, elmData.outdata)
      #     if label is "stress_elements":
      #       element.appendCellOutput('stress_elements', globalData, elmData.stress_elements, elmID)

      #Assemble in the global array
      if rank == 1:
        B[el_dofs] += elmData.fint
      elif rank == 2 and action is "getTangentStiffness":
        A[ix_(el_dofs,el_dofs)] += elmData.stiff
        B[el_dofs] += elmData.fint
      elif rank == 2 and action is "getMassMatrix":  
        A[ix_(el_dofs,el_dofs)] += elmData.mass
        B[el_dofs] += elmData.lumped
      else:
        raise NotImplementedError('assemleArray is only implemented for vectors and matrices.')

  if rank == 1:
    return B
  elif rank == 2:
    return A, B


##########################################
# Internal force vector assembly routine # 
##########################################

def assembleInternalForce ( props, globalData ):
  return assembleArray( props, globalData, rank = 1, action = 'getInternalForce' )


#############################################
# Tangent stiffness matrix assembly routine # 
#############################################

def assembleTangentStiffness ( props, globalData ):
  return assembleArray( props, globalData, rank = 2, action = 'getTangentStiffness' )

#############################################
# Mass matrix assembly routine              # 
#############################################

def assembleMassMatrix ( props, globalData ):
  return assembleArray( props, globalData, rank = 2, action = 'getMassMatrix' )
