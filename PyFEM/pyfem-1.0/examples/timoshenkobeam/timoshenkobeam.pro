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
  type = "LinearSolver";
};

outputModules = ["vtk","output"];

vtk =
{
  type = "MeshWriter";
};

output =
{
  type = "OutputWriter";

  onScreen = true;
};