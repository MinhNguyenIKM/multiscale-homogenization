import numpy as np

thickness = 1

nodes = np.array([
	[713,		20.0,		0.0],
	[712,		20.0,		0.384615391],
	[711,		20.0,		0.769230783],
	[710,		20.0,		1.15384614],
	[709,		20.0,		1.53846157],
	[708,		20.0,		1.92307687],
	[707,		20.0,		2.30769229],
	[706,		20.0,		2.69230771],
	[705,		20.0,		3.07692313],
	[704,		20.0,		3.46153855],
	[703,		20.0,		3.84615374],
	[702,		20.0,		4.23076916],
	[701,		20.0,		4.61538458],
	[700,		20.0,		5.0]])

traction = np.array([
	[713,		0.0,		-0.25],
	[712,		0.0,		-0.25],
	[711,		0.0,		-0.25],
	[710,		0.0,		-0.25],
	[709,		0.0,		-0.25],
	[708,		0.0,		-0.25],
	[707,		0.0,		-0.25],
	[706,		0.0,		-0.25],
	[705,		0.0,		-0.25],
	[704,		0.0,		-0.25],
	[703,		0.0,		-0.25],
	[702,		0.0,		-0.25],
	[701,		0.0,		-0.25],
	[700,		0.0,		-0.25]])  # A sequence of node must be in this list

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