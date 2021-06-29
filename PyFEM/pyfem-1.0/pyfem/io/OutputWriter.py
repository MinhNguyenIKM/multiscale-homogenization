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

from numpy import ndarray,zeros

class OutputWriter( BaseModule ):

  def __init__ ( self, props , globdat ):

    self.prefix    = globdat.prefix
    self.extension = ".out"
    self.onScreen  = False

    BaseModule.__init__( self , props )

    if not hasattr( self , "filename" ):
      self.filename  = self.prefix + self.extension
    
    self.outfile = open( self.filename ,'w' )

#------------------------------------------------------------------------------
#
#------------------------------------------------------------------------------

  def run( self , props , globdat ):

    globdat.printNodes()

#    self.outfile.write(globdat.printNodes())

#    if not globdat.active:
#      self.outfile.close
