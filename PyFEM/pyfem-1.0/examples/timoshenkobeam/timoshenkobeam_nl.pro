############################################################################
#  HOMOGENIZATION in 2 Scales
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
#  Usage:       pyfem PatchTest3.pro                                       #
############################################################################

input = "./examples/timoshenkobeam/timoshenkobeam2.dat";

ContElem =
{
  type = "SmallStrainContinuum";

  material =
  {
    type = "PlaneStress";
    E    = 1000000;
    nu   = 0.3;
  };
};

solver =
{
  type = 'NonlinearSolver';

  fixedStep = true;
  maxCycle   = 20;
};

outputModules = ["graph","mesh"];

graph =
{
  type = "GraphWriter";

  onScreen = true;

  columns = [ "disp" , "load" ];

  disp =
  {
    type = "state";
    node = 12;
    dof  = 'u';
    factor = 1.0;
  };

  load =
  {
    type = "fint";
    node = 12;
    dof  = 'u';
  };
};

mesh =
{
  type = "MeshWriter";
};
