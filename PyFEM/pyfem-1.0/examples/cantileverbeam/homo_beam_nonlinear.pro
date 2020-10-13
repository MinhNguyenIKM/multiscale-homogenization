############################################################################
#  HOMOGENIZATION in 2 Scales
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
#  Usage:       pyfem PatchTest3.pro                                       #
############################################################################

input = "./examples/cantileverbeam/timoshenkobeam.dat";

ContElem =
{
  type = "FiniteStrainContinuum";
  material =
  {
        type = "Homogenization";
        phase = {
            p1 = {
                type = "PlaneStrain";
                E    = 1;
                nu   = 0.333333;
            };
            p2 = {
                type = "PlaneStrain";
                E    = 2;
                nu   = 0.333333;
            };
        };
    };
};

solver =
{
  type = 'NonlinearSolver';
  maxCycle = 1;
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

