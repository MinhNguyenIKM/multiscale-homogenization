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

from numpy import outer, ones, zeros
from pyfem.materials.MaterialManager import MaterialManager
#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------

class Element ( list ):
    dofTypes = []
#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
    def __init__ ( self, elnodes , props ):
        list.__init__( self, elnodes )
        self.history = {}
        self.current = {}
        for name,val in props:
            if name is "material":
                self.matProps = val
                self.mat = MaterialManager( self.matProps )
            else:
                setattr(self, name, val)
#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
    def dofCount ( self ):
        return len( self ) * len( self.dofTypes )
#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
    def getNodes ( self ):
        return self
#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
    def getType ( self ):
        return self.elemType
#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
    def appendNodalOutput(self, outputName, global_data, outmat, outw=None):
        if outw == None:
            outw = ones(outmat.shape[0])
        if not hasattr(global_data, outputName):
            # minh.nguyen@ikm.uni-hannover.de added comments here
            # This code add new attribute 'stresses' or 'strains' for an instant of object globaldat
            global_data.outputNames.append(outputName)
            setattr(global_data, outputName, zeros( ( len(global_data.nodes), outmat.shape[1])))
            setattr(global_data, outputName + 'Weights', zeros(len(global_data.nodes)))
        outMat     = getattr(global_data, outputName)
        outWeights = getattr(global_data, outputName + 'Weights')
        if outmat.shape[1] != outMat.shape[1] or outmat.shape[0] != len(self):
            raise RuntimeError("Appended output vector has incorrect size.")
        indi = global_data.nodes.getIndices(self)
        outMat[indi]     += outer(outw, ones(outmat.shape[1])) * outmat
        outWeights[indi] += outw
#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
    # minh.nguyen@ikm.uni-hannover.de added this function
    def appendCellOutput(self, outputName, global_data, outmat, elemID):
        if not hasattr(global_data, outputName):
            setattr(global_data, outputName, zeros((len(global_data.elements), outmat.shape[1])))
        outMat = getattr(global_data, outputName)
        if outmat.shape[1] != outMat.shape[1] or outmat.shape[0] != len(self):
            raise RuntimeError("Appended output vector has incorrect size.")
        outMat[elemID] = outmat[0, :]
# ------------------------------------------------------------------------------
#
# ------------------------------------------------------------------------------
    def setHistoryParameter(self, name, val):
        self.current[name] = val
#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
    def getHistoryParameter(self, name):
        return self.history[name]
#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------
    def commitHistory(self):
        self.history = self.current.copy()
        self.current = {}
        if hasattr(self, "mat"):
            self.mat.commitHistory()
