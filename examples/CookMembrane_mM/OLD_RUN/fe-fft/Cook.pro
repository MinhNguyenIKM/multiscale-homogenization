############################################################################
#  Hyper-elasticity CookMembrane problem micro and macro
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
############################################################################

input = "./examples/CookMembrane_mM/Cook-NeoHookean.dat";

ContElem =
{
  type = "FiniteStrainContinuumPF";
  material =
  {
        type = "Homogenization";
        phase = {
            p1 = {
                type = "NeoHookean2PF";
                E    = 100;
                nu   = 0.4;
            };
            p2 = {
                type = "NeoHookean2PF";
                E    = 1000;
                nu   = 0.3;
            };
        };
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
