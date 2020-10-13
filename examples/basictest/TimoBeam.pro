############################################################################
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
############################################################################

input = "./examples/basictest/Timoshenkobeam.dat";

ContElem =
{
  type = "SmallStrainContinuum";
  material =
  {
    type = "PlaneStrain";
    E    = 100;
    nu   = 0.4;
  };
};

solver =
{
  type = 'LinearSolver';
};

outputModules = ["mesh"];

mesh =
{
  type = "MeshWriter";
};