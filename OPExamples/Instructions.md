# Installing OceanParcels

## Installation:

- Follow installation at the [OceanParcles Site](https://oceanparcels.org/) .    Make sure you get the examples and run the example case they suggest.

- Optionally - add ipympl for interactive plotting in jupyter notebooks 

```sh
conda install -c conda-forge ipympl
jupyter nbextension enable --py widgetsnbextension
```

## Running OceanParcels
activate the conda environment: 
```sh
conda activate py3_parcels
```

## Running Example 1 (two particles in the Gulf of Maine)

```sh
conda activate py3_parcels
jupyter notebook ex1.ipynb
```

Choose Run=> all cells at the top of the notebook.  Note that this is using the hindcast forcing ex1\_hycom.nc included in the folder.  This data was downloaded using the ex1\_download\_hycom.sh script.  If it runs correctly it will output the file ex1\_tracks.nc which contains lon/lat/salinity data at each position of the two particles.  The last cell in the example notebook will read in this track data and plot it against Gebco bathymetry.


