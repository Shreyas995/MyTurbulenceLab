#!/usr/bin/python3

import numpy as np
import struct
import sys
import matplotlib.pyplot as plt

sizeofdata = 4 # in bytes
# sizeofdata = 1 # for gate files

# etype = ">" # big-endian
etype = "<" # little-endian

dtype = "f" # floating number
# dtype = 'B' # unsigned character, for gate files

nx = 0 # number of points in Ox; if 0, then search tlab.ini
ny = 0 # number of points in Oy; if 0, then search tlab.ini
nz = 0 # number of points in Oz; if 0, then search tlab.ini

# do not edit below this line

# getting grid size from tlab.ini, if necessary
if ( nx == 0 ):
    for line in open('tlab.ini'):
        if line.lower().replace(" ","").startswith("imax="):
            nx = int(line.split("=",1)[1])
            break

if ( ny == 0 ):
    for line in open('tlab.ini'):
        if line.lower().replace(" ","").startswith("jmax="):
            ny = int(line.split("=",1)[1])
            break

if ( nz == 0 ):
    for line in open('tlab.ini'):
        if line.lower().replace(" ","").startswith("kmax="):
            nz = int(line.split("=",1)[1])
            break

print("Grid size is {}x{}x{}.".format(nx,ny,nz))

# getting data from stdin
if ( len(sys.argv) <= 1 ):
    print("Usage: python $0 [xy,xz] list-of-files.")
    quit()

planetype  = sys.argv[1]
setoffiles = sorted(sys.argv[2:])

# processing data
fin = open('grid.'+planetype, 'rb')
if   ( planetype == 'xy' ):
    raw = fin.read(nx*4)
    x1 = np.array(struct.unpack(etype+'{}f'.format(nx), raw))
    nx1= nx
    raw = fin.read(ny*4)
    x2 = np.array(struct.unpack(etype+'{}f'.format(ny), raw))
    nx2= ny
elif ( planetype == 'xz' ):
    raw = fin.read(nx*4)
    x1 = np.array(struct.unpack(etype+'{}f'.format(nx), raw))
    nx1= nx
    raw = fin.read(nz*4)
    x2 = np.array(struct.unpack(etype+'{}f'.format(nz), raw))
    nx2= nz
elif ( planetype == 'yz' ):
    raw = fin.read(ny*4)
    x1 = np.array(struct.unpack(etype+'{}f'.format(ny), raw))
    nx1= ny
    raw = fin.read(nz*4)
    x2 = np.array(struct.unpack(etype+'{}f'.format(nz), raw))
    nx2= nz
fin.close()

for file in setoffiles:
    print("Processing file %s ..." % file)
    fin = open(file, 'rb')
    raw = fin.read()
    a = np.array(struct.unpack((etype+'{}'+dtype).format(int(fin.tell()/sizeofdata)), raw))
    a = a.reshape((nx2,nx1))
    fin.close()

    mean, std = np.mean( a ), np.std( a )
    plt.figure( figsize=(10,8) )
    plt.pcolormesh(x1,x2,a,shading='auto',vmin=mean-std,vmax=mean+std)
    # plt.contourf(x1,x2,a)
    plt.axis('equal')
    # plt.gca().set_xlim([x1[0],x1[-1]])
    # plt.gca().set_ylim([x2[0],x2[-1]])
    # plt.axis([ x1[0], x1[-1], x2[0], x2[-1]])
    plt.colorbar()
    plt.tight_layout(pad=2)
    plt.title(file)
    # plt.savefig("{}.jpg".format(file),dpi=150,bbox_inches='tight')
    plt.show()
    plt.close()
