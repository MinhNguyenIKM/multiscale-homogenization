############################################################################
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
############################################################################

input = "./examples/basictest/timo/TimoBeam_mesh1_Q4.dat";

ContElem =
{
  type = "SmallStrainContinuum";
  material =
  {
    type = "PlaneStress";
    E    = 1000;
    nu   = 0.3;
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