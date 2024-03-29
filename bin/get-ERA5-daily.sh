#!/bin/env bash
#
# monthly script for fetching ERA5 Land reanalysis data from cdsapi, cutting out the Nordic domain
# and setting it up in the smartmet-server
#
# 14.1.2020 Mikko Strahlendorff
eval "$(conda shell.bash hook)"
conda activate xr
if [ $# -ne 0 ]
then
    year=$1
    month=$2
    day=$3
else
    year=$(date -d '6 days ago' +%Y)
    month=$(date -d '6 days ago' +%m)
    day=$(date -d '6 days ago' +%d)
fi
cd /data
echo "fetch ERA5 for y: $year m: $month d: $day"
[ -f ERA5_$year$month${day}T000000_base+soil-sam.grib ] || /home/users/smartmet/bin/cds-era5.py $year $month $day
/home/users/smartmet/anaconda3/envs/xr/bin/cdo --eccodes aexprf,ec-sde.instr ERA5_$year$month${day}T000000_base+soil-sam.grib grib/ERA5_${year}0101T000000_$year$month${day}T0000_base+soil-sam.grib &&\
 rm ERA5_$year$month${day}T000000_base+soil-sam.grib
#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0
