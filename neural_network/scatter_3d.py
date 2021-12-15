#!/usr/bin/env python2

import numpy as np
from mayavi import mlab

x, y, z, value = np.random.random((4, 40))
mlab.points3d(x, y, z, value)

mlab.show() # or
# mlab.savefig("1.png", size=(1000,800))