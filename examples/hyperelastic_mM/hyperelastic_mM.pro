############################################################################
#  HOMOGENIZATION in 2 Scales
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
#  Usage:       pyfem PatchTest3.pro                                       #
############################################################################

input = "./examples/hyperelastic_mM/mesh.dat";

ContElem =
{
  type = "SmallStrainContinuum";

  material =
  {
    type = "PlaneStress";
    E    = 100000;
    nu   = 0.25;
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