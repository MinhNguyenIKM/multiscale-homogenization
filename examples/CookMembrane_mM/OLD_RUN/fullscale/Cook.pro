############################################################################
#  Hyper-elasticity CookMembrane problem for full-scale calculation
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
############################################################################

input = "./examples/CookMembrane_mM/fullscale/Cook_fullscale.dat";

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

outputModules = ["graph","mesh"];

graph =
{
  type = "GraphWriter";

  onScreen = true;

  columns = [ "disp" , "load" ];

  disp =
  {
    type = "state";
    node = 12;
    dof  = 'u';
    factor = 1.0;
  };

  load =
  {
    type = "fint";
    node = 12;
    dof  = 'u';
  };
};

mesh =
{
  type = "MeshWriter";
};