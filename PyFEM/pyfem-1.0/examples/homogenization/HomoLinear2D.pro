############################################################################
#  HOMOGENIZATION in 2 Scales
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
#  Usage:       pyfem PatchTest3.pro                                       #
############################################################################

input = "./examples/homogenization/timoshenkobeam.dat";

ContElem =
{
  type = "SmallStrainContinuum";
  material =
  {
        type = "Homogenization";
        phase = {
            p1 = {
                type = "PlaneStrain";
                E    = 1000000;
                nu   = 0.333333;
            };
            p2 = {
                type = "PlaneStrain";
                E    = 100000000;
                nu   = 0.333333;
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

outputModules = ["vtk","output"];

vtk =
{
  type = "MeshWriter";
};

output =
{
  type = "OutputWriter";

  onScreen = true;
};
