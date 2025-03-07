#!/bin/bash
#
# script for fetching daily ERA5-Land reanalysis data and daily statistics from cdsapi
# and setting it up in the smartmet-server
# Nordic domain [72, 3, 52, 33]

#eval "$(conda shell.bash hook)"

eval "$(/home/ubuntu/mambaforge/bin/conda shell.bash hook)"
if [ $# -ne 0 ]
then
    year=$1
    month=$2
    day=$3
    ymond=$year$month$day
    ymond1=$(date -d $ymond '+%Y%m%d')
    ymond2="$(date -d "$ymond1 - 1 days" +%Y%m%d)"
    yday=$(date -d $ymond2 '+%d')
    ymonth=$(date -d $ymond2 '+%m')
    yyear=$(date -d $ymond2 '+%Y')
    echo $yday
else
    year=$(date -d '6 days ago' +%Y)
    month=$(date -d '6 days ago' +%m)
    day=$(date -d '6 days ago' +%d)
    yyear=$(date -d '7 days ago' +%Y)
    ymonth=$(date -d '7 days ago' +%m)
    yday=$(date -d '7 days ago' +%d)
    ymond1=$year$month$day
    ymond2=$yyear$ymonth$yday
fi

echo "ERA5-Land year: $year month: $month day: $day"

cd /home/smartmet/data

conda activate xr

# Fetch ERA5-Land data
echo "fetch ERA5-L for y: $year m: $month d: $day"
[ -f grib/ERA5L_20000101T000000_$year$month${day}T000000_base+soil.grib ] || python /home/users/smartmet/chile-smartmet/bin/cds-era5l-nd.py $year $month $day && \
  || echo "Error: ERA5-Land data not fetched"


## accumulated at 00UTC
#cdo -b P8 -O --eccodes shifttime,-1day -selhour,0 -selname,e,tp,slhf,sshf,ro,str,strd,ssr,ssrd,sf ERA5L_${ymond1}T000000_sfc-1h.grib ERA5LD_20000101T000000_${ymond2}T000000_accumulated.grib
## daily means for instantaneous ERA5L_20000101T000000_
#cdo -b P8 -O --eccodes daymean -selname,10u,10v,2d,2t,lai_hv,lai_lv,src,skt,asn,rsn,sd,stl1,stl2,stl3,stl4,sp,tsn,swvl1,swvl2,swvl3,swvl4 ERA5L_${ymond1}T000000_sfc-1h.grib ERA5LD_20000101T000000_${ymond1}T000000_dailymeans.grib

## append to monthly files - with parallel run use -j1
#if [ $yday -eq 01 ]
#then
#    mv ERA5LD_20000101T000000_${ymond2}T000000_accumulated.grib grib/ERA5LD_20000101T000000_${ymond2}T000000_accumulated.grib
#    mv ERA5LD_20000101T000000_${ymond1}T000000_dailymeans.grib grib/ERA5LD_20000101T000000_${ymond2}T000000_dailymeans.grib
#else
#    export SKIP_SAME_TIME=1
#    cdo -b P8 -O --eccodes mergetime grib/ERA5LD_20000101T000000_${yyear}${ymonth}01T000000_accumulated.grib ERA5LD_20000101T000000_${ymond2}T000000_accumulated.grib out1-$ymond1.grib && \
#    mv out1-$ymond1.grib grib/ERA5LD_20000101T000000_${yyear}${ymonth}01T000000_accumulated.grib &&\
#    rm ERA5LD_20000101T000000_${ymond2}T000000_accumulated.grib
#    cdo -b P8 -O --eccodes mergetime grib/ERA5LD_20000101T000000_${yyear}${ymonth}01T000000_dailymeans.grib ERA5LD_20000101T000000_${ymond1}T000000_dailymeans.grib out2-$ymond1.grib && \
#    mv out2-$ymond1.grib grib/ERA5LD_20000101T000000_${yyear}${ymonth}01T000000_dailymeans.grib &&\
#    rm ERA5LD_20000101T000000_${ymond1}T000000_dailymeans.grib
#fi

## daily hourly data
#mv ERA5L_${ymond1}T000000_sfc-1h.grib grib/ERA5L_20000101T000000_$year$month${day}T000000_base+soil.grib
#cdo -f grb2 --eccodes setparam,11.1.0 -selname,sde -aexprf,ec-sde.instr grib/ERA5L_20000101T000000_$year$month${day}T000000_base+soil.grib grib/ERA5L_20000101T000000_$year$month${day}T000000_sde.grib
##sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0

## Check if any of the generated files are 0KB
#for file in grib/ERA5L_20000101T000000_$year$month${day}T000000_base+soil.grib \
#           grib/ERA5LD_20000101T000000_${ymond2}T000000_accumulated.grib \
#           grib/ERA5LD_20000101T000000_${ymond1}T000000_dailymeans.grib \
#           grib/ERA5L_20000101T000000_$year$month${day}T000000_sde.grib
#do
#    # check if file is empty
#    if [ -f "$file" ] && [ ! -s "$file" ] 
#    then
#        # print file that is empty
#        echo "Error: $file is 0KB"
#	echo "Removing $file"
#	rm "$file"
#        exit 1
#    else
#        # print file that is not empty
#        echo "$file is not 0KB"
#        
#    fi
#done

echo "Done"
