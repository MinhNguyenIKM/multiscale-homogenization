# multiscale-homogenization
Computational Homogenization calculation in macroscopic and microscopic structurures.
The microscopic BVPs are solved by FFT method. 
The macroscopic BVPs are solved by FEM method (we use PyFEM framework based on the book Nonlinear Finite Element Analysis of Solids and Structures of Rene' de Borst et. al.)


This is my part of code from the work "<b>A surrogate model for computational homogenization of elastostatics at finite strain using high‐dimensional model representation‐based neural network</b>"
Authors: 
Vien Minh Nguyen‐Thanh,
Lu Trong Khiem Nguyen,
Timon Rabczuk,
Xiaoying Zhuang,

Developement: ntvminh286@gmail.com (institute email: minh.nguyen@iop.uni-hannover.de)

DOI: https://doi.org/10.1002/nme.6493

<b>Abstract</b>:
We propose a surrogate model for two‐scale computational homogenization of elastostatics at finite strains. 
The macroscopic constitutive law is made numerically available via an explicit formulation of the associated macroenergy density. 
This energy density is constructed by using a neural network architecture that mimics a high‐dimensional model representation. 
The database for training this network is assembled through solving a set of microscopic boundary value problems with the prescribed 
macroscopic deformation gradients (input data) and subsequently retrieving the corresponding averaged energies (output data). 
Therefore, the two‐scale computational procedure for nonlinear elasticity can be broken down into two solvers for microscopic and 
macroscopic equilibrium equations that work separately in two stages, called the offline and online stages. The finite element method 
is employed to solve the equilibrium equation at the macroscale. As for microscopic problems, an FFT‐based collocation method is applied 
in tandem with the Newton‐Raphson iteration and the conjugate‐gradient method. Particularly, we solve the microscopic equilibrium equation 
in the Lippmann‐Schwinger form without resorting to the reference medium. In this manner, the fixed‐point iteration that might require quite 
strict numerical stability conditions in the nonlinear regime is avoided. In addition, we derive the projection operator used in the FFT‐based 
method for homogenization of elasticity at finite strain.

## Guideline to setup the working environment:
Setup:
### METHOD 1
1. I assume that you have already downloaded the folder "multiscale-homogenization" and named it as "multiscale-homogenization".
   - Go to the folder "multiscale-homogenization" which you just downloaded (you can do it by cd command).
   - Type this command in your terminal: pwd
   - The shown message is your working directory denoted by \<workingdir\>

2. Setup environment with conda: conda create -n homo python=2

3. Switch to homo environment to start working with this project: source activate homo

4. Install some first necessary libraries: pip install numpy scipy matplotlib

5. Go to the folder PyFEM\/pyfem-1.0 and install PyFEM by executing this command: python install.py. Afterwards, you just follow the appearing message.

6. Setup PYTHONPATH environment for the "multiscale-homogenization" by doing either a.(temporary use) or b.(permanent use):

a. export PYTHONPATH="$PYTHONPATH:\<workingdir\>"

b. add the above line to the end of file ~/.bashrc and execute "source ~/.bashrc"
