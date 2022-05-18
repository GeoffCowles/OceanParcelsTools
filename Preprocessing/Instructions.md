# DOWNLOADING + PROCESSING HYCOM Data

## Dependencies

(1) wget (usually available on linux/OS X by default)
(2) nco  (netcdf toolkit).  Available on mac via macbrew and linux (e.g. apt-get install nco)
(3) cdo (another netcdf toolkit that has a routine to easily strip redundant frames).  Available on mac via macbrew and linux (e.g. apt-get install cdo)
(4) a gnu-format date command (default on linux, install gdate on OSX)

## Select HYCOM Experiments
When HYCOM makes small changes to input or forcing or bulk parameterizations, they assign a new experiment number.  Most experiments run a year or two.    See here (https://tds.hycom.org/thredds/catalog.html) for date ranges of GLB hindcasts.

## Download the data from HYCOM
Use the download__hycom.sh script.   Follow instructions in the user-defined area of the script.  You will need to establish paths to wget and to your date command, select the HYCOM experiment data range, and select the variable range.  Optionally you will select horizontal subsetting and vertical layer selection (single layer, range of layers, all layeres)

## Eliminating Duplicate Timeframes
HYCOMs ncss will give you the NEAREST time frame to your request.  There are some missing timeframes in the HYCOM data.  Because ncss gives you the nearest time frame this will result in some duplicated frames which is problematic for OceanParcels which is expected monotonically increasing time in the ocean hindcast forcing fields.   In the download\_hycom.sh bash script the cdo command is used to strip any duplicate frames out of daily files.    However there can remain an issue where a frame at the end of one day is identical to the first frame of the next day.  This has to be resolved manually.   There are two options to this depending on your dataset size.  If your data is small enough that you can ncrcat all your daily files into a single forcing file you can then use cdo to strip out any duplicate frames from the aggregated file.  For example, if you concatenated all dailies into a file HYCOM\_2016.nc you can use:  

```sh
cdo mergetime HYCOM_2016.nc tmp.nc
mv tmp.nc HYCOM_2016.nc
```

If your dataset is large and you maintain it in several files (daily, monthly, etc) you do this individually to the files but it will not guarantee that the end of one monthly file is not duplicated with the beginning of the next.  You must first identify the frames which are duplicated by extracting the time variable from all your files, concatenating them, and then writing that time variable to a NetCDF file. You can do this using the following example script which processes files named HAB1\_mth0.nc, HAB1\_mth1.nc  etc.

```sh
FILES="./HAB1_mth*"
for f in $FILES
do
  echo "Processing $f file..."
  fout="${f%.nc}_time.nc"
  echo $fout
  ncks -v time $f $fout
  # take action on each file. $f store current file name
  #cat "$f"
done
ncrcat *time.nc all_times.nc
```

Once you have the NetCDF file containing the concatenated time variable you can load time into Matlab or python and use diff(time) to determine if there are any duplicate frames and if so, their frame and date numbers.  You can then manually extract them from the hindcast files using ncks. 

## Generating vertically-averaged fields
HYCOM GLB data is not equally spaced in the vertical. To generate vertical averages of the water column (or portions of the water column), a weighted average is needed. The tool ncwa can be used to generated a weighted vertical average.    This is a two step process:

(1) Generate a NetCDF file containing the vertical weights:    generate\_weightfile.py.   This file will read the depth levels from one of your datafiles and compute the weights associated with each level (vert\_weight) and dump variable this to the NetCDF file 'weight_file.nc'.

(2) Append vert\_weight to HYCOM files and then use the ncwa command to average the vertical dimension ('depth') using those weights, e.g.:

```sh
ncks -A weight_file.nc HAB1_mth_2015-08.nc ; ncwa -w vert_weight -a depth HAB1_mth_2015-08.nc HAB1_mth_2015-08_wva.nc;
```

