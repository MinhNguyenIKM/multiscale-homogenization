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

############################################################################
#  Description: The general PyFEM input file of a hinged frame. The        #
#               Timoshenko beam element is used in this simulation.        #
#                                                                          #
#  Usage:       pyfem FrameTimoshenko.pro                                  #
############################################################################

input = "Frame.dat";

BeamElem =
{
  type = "TimoshenkoBeam";
  E    = 7.2e6;
  A    = 6.0;
  I    = 2.0;
  G    = 5e6;
};

solver =
{
  type = "RiksSolver";
 
  maxLam = 25;
};

outputModules = ['graph'];

graph =
{
  type = "GraphWriter";
  onScreen = true;

  columns = ["disp" , "load" ];

  disp =
  {
    type = "state";
    node = 13;
    dof  = 'v';
    factor = -1.0;
  };

  load =
  {
    type = "fint";
    node = 13;
    dof  = 'v';
    factor = -1.0;
  };
};
