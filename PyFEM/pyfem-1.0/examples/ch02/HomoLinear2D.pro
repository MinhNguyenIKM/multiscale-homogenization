############################################################################
#  HOMOGENIZATION in 2 Scales
# minh.nguyen@ikm.uni-hannover.de
############################################################################

############################################################################
#                                                                          #
#  Usage:       pyfem PatchTest3.pro                                       #
############################################################################

input = "./examples/ch02/PatchTest3.dat";

ContElem =
{
  type = "SmallStrainContinuum";
  material =
  {
        type = "Homogenization";
        phase = {
            '1' = {
                type = "PlaneStrain";
                E    = 1;
                nu   = 0.25;
            };
            '2' = {
                type = "PlaneStrain";
                E    = 2;
                nu   = 0.25;
            };
        };
    };
};

solver =
{
  type = "LinearSolver";
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
