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
#               section 13.2 of the book, pages       .                    #
#                                                                          #
#  Usage:       pyfem PeelTest.pro                                         #
############################################################################

input = "./examples/ch13/PeelTest.dat";

ContElem =
{
  type = "SmallStrainContinuum";

  material =
  {
    type = "PlaneStrain";
    E    = 100.0;
    nu   = 0.3;
  };
};

InterfaceElem =
{
  type = "Interface";

  material = 
  {
    type = "PowerLawModeI";

    Tult = 1.0;
    Gc   = 0.1;
  };
};

solver =
{
  type = "DissipatedEnergySolver";

  maxCycle   = 60;
  tol        = 10e-4;
  maxLam     = 20;

  switchEnergy = 1.0e-3; 
  maxdTau    = 0.05;
};

outputModules = ["vtk","graph"];

vtk =
{
  type = "MeshWriter";
  
  elementGroup = "ContElem";
};

graph =
{
  type = "GraphWriter";

  onScreen = true;

  columns = ["disp","load"];

  disp =
  {
    type = "state";
    node = 246;
    dof  = "v";
  };
  
  load =
  {
    type = "fint";
    node = 246;
    dof  = "v";
  };
};
