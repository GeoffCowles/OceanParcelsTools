#!/bin/bash
  

# script to download HYCOM data and merge into daily files
# based on a script provided on the HYCOM forum
#
# Dependencies
#   wget (usually on system by default)
#   cdo  (apt-get install or macbrew)
#   nco  (apt-get install or macbrew)
#   date (gnu version, default mac will not work, install gdate on mac via macbrew)
#
# History
# G. Cowles - added options to subset horizontally  (April, 2022)
# G. Cowles - added options to select specific variables (April, 2022)
# G. Cowles - added options to select single vertical layer, range of vertical layers, all vertical layers (April, 2022)
#
# ToDo 
#   Hour range is currently hardcoded (every 3 hours, every six hours, etc), should be in user-definition area
#    
#

export SKIP_SAME_TIME=1

#path to wget
WGET='/usr/bin/wget'

# path date command (need the gnu version) 
DATECOMM='/opt/homebrew/bin/gdate'

# dateset runs from Year/Month/Day + StartSeq to Year/Month/Day + EndSeq
YEAR='2016'
MONTH='06'
DAY='01'
StartSeq='0'
EndSeq='4'     

# HYCOM dataset location and experiment number
NCSS='http://ncss.hycom.org/thredds/ncss'
MODEL='GLBv0.08'
# EXPT 56.3 runs July1, 2014 to Sep 30, 2016  [we will use through May 31, 2016]  700 days
# EXPT 57.2 runs May 1, 2016 to Feb 1, 2017   [we will start from June 1, 2016]   153 days
#EXPT='expt_56.3'
EXPT='expt_57.2'

# naming convention for resulting dataset
DSET='HAB4'

# variables to download
VARS="var=water_temp,salinity,water_u,water_v"
Subset='spatial=bb'

# subsetting (turn on with subset=1, off with subset=0)
# increments take every loninc points longitude, every latinc points in latitude
# loninc/latinc should be postive integers
subset=0
loninc=2
latinc=2

# vertical layers 
# 3 options:
#  (1) all layers:  
#       => set specify_layers=0 
#  (2) a single layer (NetCDF subset can handle this):  
#       => set specify_layers=1 
#       => set laybeg and layend to desired layer (e.g. = 1 for the surface)  
#  (3) a range of layers (HYCOM NetCDF subset cannot handle this, all layers are downloaded and then ncks will extract the layers you wanted)
#       example, extracting layers 1,3,5 (not layinc selecs increment)
#       => set specify_layers=1
#       => set laybeg=1
#       => set layend=5
#       => set layinc=2


specify_layers=1
laybeg=1
layend=1
layinc=1

singlelayer=0
singlelayernum=0
if [ $specify_layers -eq 1 ]; then
if [ $laybeg -eq $layend ]; then
  specify_layers=0
  singlelayer=1
  singlelayernum=$laybeg
fi
fi


# define bounding box of subset
# note - older HYCOM sets (2017ish and prior) used -180 to 180 for longitude making 
# a box that crossed the prime meridian easy to establish
# newer HYCOM uses 0-360 longitude making that challenging
NORTH='north=44'
SOUTH='south=41'
EAST='east=-68'
WEST='west=-71'


# note - layer extraction still hardcoded - move to user defined option

for PlusDay in `seq $StartSeq $EndSeq`; do

  rm hour*.nc
#  for Hours in `seq 0 3 21`; do
  for Hours in `seq 0 6 18`; do

    Tstring=`$DATECOMM -d "$YEAR-$MONTH-$DAY +$PlusDay days +$Hours hours " +%Y-%m-%dT%H:%M:%SZ`
    Time="time=$Tstring"
    echo $Time

    if [ $singlelayer -eq 0 ]; then
      URL="$NCSS/$MODEL/$EXPT?$VARS&$NORTH&$SOUTH&$EAST&$WEST&$Time&addLatLon=True"
    else
      LayString="vertCoord=$singlelayernum"
      URL="$NCSS/$MODEL/$EXPT?$VARS&$NORTH&$SOUTH&$EAST&$WEST&$Time&$LayString&addLatLon=True"
    fi


    rm tmp*.nc
    wget -O tmp.nc  "$URL"


    if [ $Hours -lt 10 ]; then
      hourfile="hour0"$Hours".nc"
      hourfilewithtime="hour0"$Hours"wtime.nc"
    else
      hourfile="hour"$Hours".nc"
      hourfilewithtime="hour"$Hours"wtime.nc"
    fi


 
    # optional - extract a range of layers 
    if [ $specify_layers -eq 1 ]; then
      ncks -F -d depth,$laybeg,$layend,$layinc tmp.nc $hourfile
    else
      mv tmp.nc $hourfile
    fi

    # option to coarsen lon,lat
    if [ $subset -eq 1 ]; then
      ncks -d lon,1,,$loninc -d lat,1,,$latinc $hourfile jnk.nc
      mv jnk.nc $hourfile
      rm jnk.nc
    fi


    # make time the record dimension 
    ncks --mk_rec_dmn time  $hourfile $hourfilewithtime 

  done

   # cat the hours together into one day
   OutFile=$DSET"_`echo $Tstring | cut -d 'T' -f 1`T00Z.nc"
   echo $OutFile
#   ncrcat hour??wtime.nc $OutFile 
   cdo mergetime hour??wtime.nc $OutFile 
   rm tmp*.nc
   rm hour*.nc

done
