############################################################################
#  Hyper-elasticity Timoshenko Beam problem for full-scale calculation
# F = -0.5
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
############################################################################

input = "./TimoBeam_fullscale.dat";

ContElem1 =
{
  type = "FiniteStrainContinuumPF";

  material =
  {
    type = "NeoHookeanPF";
    E    = 1000;
    nu   = 0.3;
  };
};

ContElem2 =
{
  type = "FiniteStrainContinuumPF";

  material =
  {
    type = "NeoHookeanPF";
    E    = 100;
    nu   = 0.4;
  };
};

solver =
{
  type = 'NonlinearSolver';
  fixedStep = true;
  maxCycle   = 2;
};

outputModules = ["mesh"];

mesh =
{
  type = "MeshWriter";
};