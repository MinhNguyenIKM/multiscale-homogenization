############################################################################
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
############################################################################

input = "./examples/basictest/timo_Q4/100_inclusions_job-1-Q4.dat";

ContElem1 =
{
  type = "SmallStrainContinuum";

  material =
  {
    type = "PlaneStress";
    E    = 100000;
    nu   = 0.3;
  };
};

ContElem2 =
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