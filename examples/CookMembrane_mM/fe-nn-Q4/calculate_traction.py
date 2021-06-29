import numpy as np

thickness = 1

nodes = np.array([
	[539,		48.0,		44.0],
	[538,		48.0,		44.9411774],
	[537,		48.0,		45.8823547],
	[536,		48.0,		46.8235283],
	[535,		48.0,		47.7647057],
	[534,		48.0,		48.705883],
	[533,		48.0,		49.6470604],
	[532,		48.0,		50.5882339],
	[531,		48.0,		51.5294113],
	[530,		48.0,		52.4705887],
	[529,		48.0,		53.4117661],
	[528,		48.0,		54.3529396],
	[527,		48.0,		55.294117],
	[526,		48.0,		56.2352943],
	[525,		48.0,		57.1764717],
	[524,		48.0,		58.1176453],
	[523,		48.0,		59.0588226],
	[522,		48.0,		60.0]])

traction = np.array([
	[539, 0, 4.0],
	[538, 0, 4.0],
	[537, 0, 4.0],
	[536, 0, 4.0],
	[535, 0, 4.0],
	[534, 0, 4.0],
	[533, 0, 4.0],
	[532, 0, 4.0],
	[531, 0, 4.0],
	[530, 0, 4.0],
	[529, 0, 4.0],
	[528, 0, 4.0],
	[527, 0, 4.0],
	[526, 0, 4.0],
	[525, 0, 4.0],
	[524, 0, 4.0],
	[523, 0, 4.0],
	[522, 0, 4.0]])  # A sequence of node must be in this list

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