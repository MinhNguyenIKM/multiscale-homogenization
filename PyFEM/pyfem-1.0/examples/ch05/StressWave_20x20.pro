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
#  Description: The general PyFEM input file of the example presented in   #
#               section 5.3 of the book, pages 149--152. The mesh consists #
#               of 20x20 4 noded continuum elements.                       #
#                                                                          #
#  Usage:       pyfem StressWave_20x20.pro                                 #
############################################################################

input = "StressWave_20x20.dat";

ContElem = 
{
  type = "FiniteStrainContinuum";

  material =
  {
    type = "PlaneStrain";

    E    = 3.24e9;
    nu   = 0.35;
    rho  = 1190.0;
  };
};

solver =
{
  type = 'ExplicitSolver';

  dtime    = 1.0e-8;
  lam      = "1.0e8*(t<1.0e-7)";

  maxCycle = 400;
};

outputModules = [ 'mesh' ];

mesh =
{
  type = "MeshWriter";
  interval = 10;
};
