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
    E    = 70000000000;
    nu   = 0.33;
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