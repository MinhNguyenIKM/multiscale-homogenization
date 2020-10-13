############################################################################
#  Hyper-elasticity CookMembrane problem
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
############################################################################

input = "./examples/CookMembrane/Cook-NeoHookean.dat";

ContElem =
{
  type = "FiniteStrainContinuumPF";

  material =
  {
    type = "NeoHookeanPF";
    E    = 108.571428;
    nu   = 0.134228;
  };
};

solver =
{
  type = 'NonlinearSolver';
  fixedStep = true;
  maxCycle   = 3;
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
