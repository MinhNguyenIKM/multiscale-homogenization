import re

fread = '/home/minh/Dropbox/HOMOGENIZATION/PyFEM/pyfem-1.0/examples/timoshenkobeam/timoshenkobeam.dat'
fwrite = '/home/minh/Dropbox/HOMOGENIZATION/PyFEM/pyfem-1.0/examples/timoshenkobeam/timoshenkobeam2.dat'


def readFromFile(fread, fwrite):
    fin = open(fread)
    fileWrite = open(fwrite, 'w')
    while True:
        line = fin.readline()
        fileWrite.write(line)
        if line.startswith('<Nodes>') == True:
            while True:
                line = fin.readline()
                if line.startswith('</Nodes>') == True:
                    fileWrite.write(line)
                    line = fin.readline()
                    if line.startswith('<Elements>') == True:
                        while True:
                            line = fin.readline()
                            if line.startswith('</Elements>') == True:
                                fileWrite.write(line)
                                return
                            line = re.sub('\s{2,}', ' ', line)
                            a = line.split(';')
                            for a0 in a[:-1]:
                                b = a0.strip().split(' ')
                                if b[0].startswith("//") or b[0].startswith("#"):
                                    break
                                if len(b) > 1 and type(eval(b[0])) == int:
                                    b2 = int(b[2]) - 1
                                    b3 = int(b[3]) - 1
                                    b4 = int(b[4]) - 1
                                    b5 = int(b[5]) - 1
                                    strrep = str(b[0]) + ' \t' + str(b[1]) + ' \t' + str(b2) + ' \t' + str(b3) + ' \t' +\
                                             str(b4) + ' \t' + str(b5) + ' \t;\r\n'
                                    fileWrite.write(strrep)
                line = re.sub('\s{2,}', ' ', line)
                a = line.split(';')
                for a in a[:-1]:
                    b = a.strip().split(' ')
                    if b[0].startswith("//") or b[0].startswith("#"):
                        break
                    if len(b) > 1 and type(eval(b[0])) == int:
                        b0 = int(b[0])-1
                        strrep = str(b0) + '\t\t\t' + str(b[1]) + '\t\t\t' + str(b[2]) + '\t;\r\n'
                        fileWrite.write(strrep)


readFromFile(fread, fwrite)


