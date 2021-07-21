import numpy as np
import sys
import matplotlib.pyplot as plt
import os
import my_pylib as mp
# import matplotlib.colors as mcolors

#---------------------------------------------------------------------------#
# path to 3d-fields
path  = str(os.path.dirname(__file__) + '/../test_parallel/' ) # name = 'flow.20.1' # file = str(path+name)
index = 0

#---------------------------------------------------------------------------#
# read grid and flow fields
grid = mp.DnsGrid(path+'grid')

# orignial field
flow = mp.Field(path,var='flow',index=index)
flow.read_3d_field()

# u_mod field 
f = open(path +'u_mod.1','rb')
f.seek(52,0)
u_mod = np.fromfile(f, np.dtype('<f8'), grid.nx*grid.ny*grid.nz)
u_mod = u_mod.reshape((grid.nx,grid.ny,grid.nz),order='F')
f.close()

# read eps field
f = open(path +'eps0.1','rb')
f.seek(52,0)
eps = np.fromfile(f, np.dtype('<f8'), grid.nx*grid.ny*grid.nz)
eps = eps.reshape((grid.nx,grid.ny,grid.nz),order='F')
f.close()

# sys.exit()


#---------------------------------------------------------------------------#
# plot settings 
plt.rcParams['figure.dpi'] = 250 
size    = (8,6)
shading = 'nearest'#'gouraud'
figs    = 'figs' 
plt.close('all')
#---------------------------------------------------------------------------#
#---------------------------------------------------------------------------#
# 2d plot - yz
plt.figure(figsize=size)
plt.title('2d-plot -- yz-plane -- velocity u_mod')
plt.xlabel("z")
plt.ylabel("y")
#
plt.pcolormesh(grid.z,grid.y,u_mod[0,:,:], shading=shading ,cmap='RdBu_r')#, norm=midnorm)
plt.colorbar()
plt.show()
#---------------------------------------------------------------------------#
# 2d plot - xy
plt.figure(figsize=size)
plt.title('2d-plot -- xy-plane -- velocity u_mod')
plt.xlabel("x")
plt.ylabel("y")
#
plt.pcolormesh(grid.x,grid.y,u_mod[:,:,grid.nz//3].T, shading=shading, cmap='RdBu_r') #shading='gouraud',
plt.colorbar()
plt.show()
#---------------------------------------------------------------------------#
# 2d plot - xz
plt.figure(figsize=size)
plt.title('2d-plot -- xz-plane -- velocity u_mod')
plt.xlabel("x")
plt.ylabel("z")
#
plt.pcolormesh(grid.x,grid.z,u_mod[:,1,:].T, shading=shading, cmap='RdBu_r')
plt.colorbar()
plt.show()
#---------------------------------------------------------------------------#

# u_mod = u_mod * eps

plt.figure(figsize=size)
plt.xlabel("z")
plt.ylabel("w-velocity")
for i in range(0,10):
    plt.plot(grid.z,u_mod[0,i,:], marker='.',label='y-node='+str(i))
plt.legend(loc=1)
plt.show()


w     = flow.w * (1. - eps)
w_mod = u_mod  * (1. - eps)
res   = w - w_mod
print(str(res.sum()))

sys.exit()





#---------------------------------------------------------------------------#
# 2d plot - yz
plt.figure(figsize=size)
plt.title('2d-plot -- yz-plane -- velocity u')
plt.xlabel("z")
plt.ylabel("y")
#
plt.pcolormesh(grid.z,grid.y,flow.w[0,:,:], shading=shading ,cmap='RdBu_r')#, norm=midnorm)
plt.colorbar()
plt.show()
#---------------------------------------------------------------------------#
# 2d plot - xy
plt.figure(figsize=size)
plt.title('2d-plot -- xy-plane -- velocity u')
plt.xlabel("x")
plt.ylabel("y")
#
plt.pcolormesh(grid.x,grid.y,flow.w[:,:,grid.nz//3].T, shading=shading, cmap='RdBu_r') #shading='gouraud',
plt.colorbar()
plt.show()
#---------------------------------------------------------------------------#
# 2d plot - xz
plt.figure(figsize=size)
plt.title('2d-plot -- xz-plane -- velocity u')
plt.xlabel("x")
plt.ylabel("z")
#
plt.pcolormesh(grid.x,grid.z,flow.w[:,1,:], shading=shading, cmap='RdBu_r')
plt.colorbar()
plt.show()














sys.exit()



plt.figure(figsize=size)
for i in range(0,10):
    plt.plot(grid.z,u_mod[0,i,:], marker='x')
plt.show()















#---------------------------------------------------------------------------#
# 2d plot - xy
plt.figure(figsize=size)
plt.title('2d-plot -- xy-plane -- velocity u')
plt.xlabel("x")
plt.ylabel("y")
#
plt.pcolormesh(grid.x,grid.y,flow.u[:,:,grid.nz//3].T, shading=shading, cmap='RdBu_r') #shading='gouraud',
plt.colorbar()
plt.show()
#---------------------------------------------------------------------------#
# 2d plot - xz
plt.figure(figsize=size)
plt.title('2d-plot -- xz-plane -- velocity u')
plt.xlabel("x")
plt.ylabel("z")
#
plt.pcolormesh(grid.x,grid.z,flow.u[:,1,:], shading=shading, cmap='RdBu_r')
plt.colorbar()
plt.show()




#-----------------------------------------------------------------------------#
# plot lines
#-----------------------------------------------------------------------------#

# plt.figure(figsize=size)
# for i in range(0,10):
#     plt.plot(grid.z,field_3d[:,i,0])
# plt.show()


# plt.figure(figsize=size)
# for i in range(60,70):
#     plt.plot(grid.y,field_3d[0,:,i])
# plt.show()


#-----------------------------------------------------------------------------#
# plot with axis
#-----------------------------------------------------------------------------#

# plt.close("all")




# f = open(path +'epsi','rb')
# f.seek(0,0)
# rec = np.fromfile(f, np.dtype('<f8'), 128**2*96)
# rec = rec.reshape((128,96,128),order='F')
# f.close()