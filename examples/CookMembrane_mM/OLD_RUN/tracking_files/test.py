#!/usr/bin/env python2
from util import FileProcessing as fp
from numpy import dot, exp, ones
import numpy as np
from matplotlib import pyplot as plt
from matplotlib import cm as color
from mpl_toolkits.mplot3d import Axes3D
import itertools
import re

E = 108.571428;
nu = 0.134228;
beta = (2 * nu)/(1 - 2 * nu)

def get_energy_Neo_Hookean(F, mu, beta):
	dim = F.shape[0]
	C = np.dot(np.transpose(F), F)
	trC = np.trace(C)
	detF = np.linalg.det(F)
	energy = mu / 2 * (trC - dim) + mu / beta * (np.power(detF, -beta) - 1)
	return energy

