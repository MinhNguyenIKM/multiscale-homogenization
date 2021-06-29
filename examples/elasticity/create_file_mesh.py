import util.FileProcessing as fp

input  = './elastic.inp'
output = './mesh.dat'
fp.create_meshdata_from_abaqusfile(input, output)
