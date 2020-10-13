############################################################################
#  Hyper-elasticity Timoshenko Beam
# Neo-Hookean model in Yvonnet paper
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
############################################################################

input = "./mesh.dat";

ContElem =
{
  type = "FiniteStrainContinuumPF";
  material =
  {
    type = "NeoHookeanPF";
    E    = 1000;
    nu   = 0.3;
  };
};

solver =
{
  type = 'NonlinearSolver';
  fixedStep = true;
  maxCycle   = 1;
};

outputModules = ["mesh"];

mesh =
{
  type = "MeshWriter";
};
