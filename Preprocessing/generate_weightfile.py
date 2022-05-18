# generate weights to be used for a weighted vertical average
# weights are fraction (decimal) of the water column represented by a given layer
#
# requires a sample hycom dataset with the same "depth" variable as the hycom datasets
# you will be working with
#
# G. Cowles , UMass Dartmouth (March, 2022)
#
import numpy as np
import netCDF4 as nc


fn = "sample_dataset.nc"

ds = nc.Dataset(fn,'r')
print("reading from file: ",fn)
depth = ds.variables["depth"][:].squeeze()
ndepth = len(depth)
print("there are: ",ndepth," layers")

ds.close()

print("depths are:")
print(depth)
dd = np.diff(depth)
print(dd)
weight = np.copy(depth)
weight[1:-1] = .5*(  dd[1:]+dd[0:-1])
weight[0] = weight[1]
weight[-1] = weight[-2]
tweight = 1./np.sum(weight)
weight = tweight*weight
print("weights are: ")
print(weight)
print("sum of weights: ",np.sum(weight))



# write to a file
print('dumping to weight_file')
ds = nc.Dataset("weight_file.nc",mode='w',format='NETCDF4')
depth_dim = ds.createDimension('depth', ndepth)
vert_weight = ds.createVariable('vert_weight', 'f4', ('depth',))
vert_weight[:] = weight
ds.close()
print('complete')
