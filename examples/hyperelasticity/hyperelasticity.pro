############################################################################
#  Hyper-elasticity problem
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
#  Usage:       run file test_hyperelasticity.py in the main folder        #
############################################################################

input = "./examples/hyperelasticity/mesh.dat";

ContElem =
{
  type = "FiniteStrainContinuum";

  material =
  {
    type = "PlaneStrain";
    E    = 0.1;
    nu   = 0.23;
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
