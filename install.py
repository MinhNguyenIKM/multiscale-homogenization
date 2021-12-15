import os
print("--------- Installation starting -----------")
currentpath = os.getcwd()
pyfempath = currentpath + "/" + "PyFEM/pyfem-1.0"
string = "export PYTHONPATH=" + "\"" + currentpath + ":" + pyfempath + "\" \n"
print(string)
home = os.path.expanduser("~")
if os.path.isfile(home + "/.bashrc"):
	try:
		filename = home + "/.bashrc"
		f = open(filename, 'a+')
		print("Opening file:" + filename)
	except IOError as e:
		print("ERROR: Can't open file :" + e.filename)
	f.write(string)
	f.close()
	os.system("source " + home + "/.bashrc")
	exit(1)
elif os.path.isfile(home + "/.bash_profile"):
	try:
		filename = home + "/.bash_profile"
		f = open(filename, 'a+')
		print("Opening file:" + filename)
	except IOError as e:
		print("ERROR: Can't open file :" + e.filename)
	f.write(string)
	f.close()
	os.system("source " + home + "/.bash_profile")
	exit(1)
else:
	print("ERROR: Neither ~/.bashrc nor ~/.bash_profile exists")
print("--------- Installation ending -----------")
