############################################################################
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
############################################################################

input = "./TimoBeam_mesh3_T3.dat";

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
  type = 'LinearSolver';
};

outputModules = ["mesh"];

mesh =
{
  type = "MeshWriter";
};