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

### METHOD 2
1. Follow steps 1, 2, 3 in METHOD 1
2. run this command: python install.py

## Guideline how to run homogenization example (two-scale homogenization without the intervention of machine learning)
I am going to write you a tutorial about "How to run the example - Timoshenko-Beam homogenization with the matrix-inclusion RVEs". Basically, this is the beam example without the neural network part in my publication.

Basically, all the examples are put in the directory: <workingdir>/examples

For your requested example, let assume that we use Q4 element, coarse mesh. Please go to the directory: <workingdir>/examples/TimoBeam/homo-fft-Q4-mesh1/

You just simple run the file test_TimoBeam_2scale.py. This file will need the data file (TimoBeam_2scale.dat) and the setting file (TimoBeam.pro). I already created all these files for you.

After the running is done, the program will return some *.vtu files in which you will need Paraview (you can download it here https://www.paraview.org/) for the postprocessing.
   
![image](https://user-images.githubusercontent.com/34099527/146178152-93f19658-ad5d-4c97-949b-02c968423ff7.png)

![image](https://user-images.githubusercontent.com/34099527/146178204-964c7c4c-42ab-4c5d-b6a8-9cf09455fc12.png)

*Important note*: Please check the file MaterialManager.py under directory <workingdir/PyFEM/pyfem-1.0/pyfem/materials/> and comment the code "return self.mat.getStress(kinematic)" (this code is not for homogenization), uncomment the code "return self.mat.getStress(kinematic, iSam)" like this

*\# return self.mat.getStress(kinematic)*
   
*return self.mat.getStress( kinematic, iSam )* # for running homogenization 

That's it. The program will execute the FE-FFT homogenization (the FFT part is this file <workingdir>/microscale/fftgarlerkin/micro2D_largedeformation_elasticity.py)
   
## Guideline how to run neural network - homogenization (the training with machine learning must complete prior to this step)
I am going to guide you on how to run a 2D Timoshenko beam with neural networks (NN) as shown in the last example in my paper.

Firstly, you must run the file test_TimoBeam_2scale.py in folder examples/TimoBeam/homo-nn-Q4-mesh1. Once again, it will go to file PyFEM/pyfem-1.0/pyfem/elements/FiniteStrainContinuumPF.py to calculate the macro Stress and macro Moduli.
If you get any ERROR with file MaterialManager.py, probably you forget to COMMENT the getStress(kinematic, Isam) function and UNCOMMENT the getStress(kinematic) like this

*self.mat.setIter( iSam )*
   
*return self.mat.getStress(kinematic)*
   
\# *return self.mat.getStress( kinematic, iSam )* # for running homogenization

Secondly, the code will go to the getStress(kinematic) method of the class MachineLearningPrediction where you can open the file PyFEM/pyfem-1.0/pyfem/materials/MachineLearningPrediction.py to look at the lines

*from machinelearning.training_results import recover_potential_energy as ml*

and

*P, K4, W = ml.cal_material_parameter2D(F, type)*

Here, you will recognize it will invoke the function cal_material_parameter2D() of module machinelearning/training_results/recover_potential_energy.py
There, if you get any ERROR with file recover_potential_energy.py, probably you forget to edit the dimension settings. Please, edit dim=2 instead of dim=1

*dim = 2*

Thirdly, all the codes in file recover_potential_energy.py are implemented based on the EQUATION (43) in my paper.

Fourthly, after the program finishes without errors, you can open the output files *.vtu in folder examples/TimoBeam/homo-nn-Q4-mesh1 by paraview to play with the contour plots.

Finally, note that here is the example with trained neural networks for the circular-inclusion materials. I already trained my neural networks for this material. If you have another kind of material, you must train the neural network with your material inputs to get the neural network's parameters which are weights and biases (Please, refer to the SECTION 4.2.2 for more specifications).

Happy coding!
   
## Guideline how to generate data and train data
   
I will take 1D as an example for the sake of simplicity. When you are able to generate and train network with 1D case, the 2D case becomes easy to control as the consequence.
   
Step 1. Run file ingest_data_1D.py in folder machinelearning by execute this command
   
*python mic2D.solve_nonlinear_GalerkinFFT*

Then, the output will be stored in file ./dataFiles/training_data_1D_mechanics_nonlinear.dat in which the 1st column denotes the macro strain and the 2nd column refers to the macro energy.

Step 2. Place the output file ./dataFiles/training_data_1D_mechanics_nonlinear.dat in the folder machinelearning/neural_network/ and then create a new matlab file e.g., train_1D_mechanics_nonlinear.m with the content looks like in the following

*d=1*
   
*npoints=[100 450]*
   
*fns=1*
   
*N=5*
   
*neuron='tansig'*
   
*cyclemax=30*
   
*epochsinseq=100*
   
*ifRegularisation=0*
   
*tolerance = 1e-10*
   
*ifRegularisation=0*
   
*ifTestPtsSameFile=1*
   
*CoordTransformNeuron='purelin'*
   
*PartialNNoutputNeuron='purelin'*
   
*ifTest = 0*
   
*a=RS_HDMR_NN('training_data_1D_mechanics_nonlinear.dat', 'training_data_1D_mechanics_nonlinear.dat', 'Mechanics1D_Nonlinear_1d_1com_5N_100M', [tolerance], [N], 200000*[1], npoints, [fns], neuron, cyclemax, epochsinseq, ifRegularisation, ifTestPtsSameFile, CoordTransformNeuron, PartialNNoutputNeuron, ifTest);*
   
The results of the training (neural network's parameters) will be stored in the file Mechanics1D_Nonlinear_1d_1com_5N_100M.
   
The meaning of parameters defined in matlab file is explained in "Manzhos S, Yamashita K, Carrington T. Fitting sparse multidimensional data with low-dimensional terms. Computer Physics Communications 2009; 180(10): 2002 - 2012. doi: https://doi.org/10.1016/j.cpc.2009.05.022"
