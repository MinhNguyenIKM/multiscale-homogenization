import util.FileProcessing as fp

input  = './hyperelasticity.inp'
output = './mesh.dat'
fp.create_meshdata_from_abaqusfile(input, output)
