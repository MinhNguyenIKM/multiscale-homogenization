############################################################################
#  Hyper-elasticity problem
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
#  Usage:       run file test_hyperelasticity.py in the main folder        #
############################################################################

input = "./examples/hyperelasticityPF/mesh.dat";

ContElem =
{
  type = "FiniteStrainContinuumPF";

  material =
  {
    type = "SaintVenantPF";
    E    = 1000.0;
    nu   = 0.35;
  };
};

solver =
{
  type = 'RiksSolver';

  fixedStep = true;
  maxLam    = 10.0; 
};

outputModules = [ "MeshWriter" , "OutputWriter" , "GraphWriter" ];

GraphWriter =
{
  onScreen = true;

  columns = [ "disp" , "load" ];

  disp =
  {
    type = "state";
    node = 42;
    dof  = 'v';
  };

  load =
  {
    type = "fint";
    node = 42;
    dof  = 'v';
  };
};
