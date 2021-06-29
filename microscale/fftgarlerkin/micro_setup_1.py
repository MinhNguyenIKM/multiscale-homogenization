ax, bx = (-0.5, 0.5)
ay, by = (-0.5, 0.5)
Nx, Ny = (2 ** 8 + 1, 2 ** 8 + 1)
dim = 2
Lx = bx - ax
Ly = by - ay
NDOF = (dim ** 2) * (Nx * Ny)  # number of degrees-of-freedom
vol = (bx - ax) * (by - ay)