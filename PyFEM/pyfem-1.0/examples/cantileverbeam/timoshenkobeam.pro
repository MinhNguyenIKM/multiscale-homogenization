############################################################################
#  HOMOGENIZATION in 2 Scales
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
#  Usage:       pyfem PatchTest3.pro                                       #
############################################################################

input = "./examples/timoshenkobeam2/timoshenkobeam_minh.dat";

ContElem =
{
  type = "SmallStrainContinuum";

  material =
  {
    type = "PlaneStrain";
    E    = 1;
    nu   = 0.33;
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