import numpy as np

thickness = 1

nodes = np.array([
	[125,		20.0,		0.0],
	[124,		20.0,		1.0],
	[123,		20.0,		2.0],
	[122,		20.0,		3.0],
	[121,		20.0,		4.0],
	[120,		20.0,		5.0]])

traction = np.array([
	[125, 0.0, -0.25],
	[124, 0.0, -0.25],
	[123, 0.0, -0.25],
	[122, 0.0, -0.25],
	[121, 0.0, -0.25],
	[120, 0.0, -0.25]])  # A sequence of node must be in this list

rows, columns = np.shape(traction)

loading = np.zeros([rows, columns-1])

for i in range(rows-1):
	node1 = nodes[i, 1:]
	node2 = nodes[i+1, 1:]
	L = np.sqrt((node2[0] - node1[0])**2 + (node2[1] - node1[1])**2)
	T1 = L/2.0 * thickness * traction[i, 1:]
	T2 = L/2.0 * thickness * traction[i+1, 1:]
	loading[i, :] += T1
	loading[i+1, :] += T2

# Check input
outputpath = './traction.dat'
# Open output file to write
outputfile = open(outputpath, 'a+')
outputfile.write('<ExternalForces>\r')
for i in range(rows):
	strg1 = 'u[' + str(int(traction[i, 0])) + '] = ' + str(loading[i, 0]) + ';\r'
	outputfile.write(strg1)
	strg2 = 'v[' + str(int(traction[i, 0])) + '] = ' + str(loading[i, 1]) + ';\r'
	outputfile.write(strg2)
outputfile.write('</ExternalForces>\r')