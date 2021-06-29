############################################################################
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
############################################################################

input = "./cantileverbeam.dat";

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