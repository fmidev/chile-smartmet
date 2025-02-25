#!/usr/bin/env bash
# script to download and process ensemble forecast data (15-days) for Nordic domain
# SWI2 prediction with XGBoost model

eval "$(conda shell.bash hook)"

if [ $# -ne 0 ]
then
    year=$1
    month=$2
    day=$3
    if [ $4 == 'era5' ] 
        then bsf='B2SF'; era='era5'; 
        else bsf='BSF'; era='era5l'; 
    fi
else
    year=$(date +%Y)
    month=$(date +%m)
    day=$(date +%d)
    bsf='BSF'; era='era5l';
fi

cd /home/users/smartmet/data

eyear=$(date -d "$year${month}${day} 15 days" +%Y)
emonth=$(date -d "$year${month}${day} 15 days" +%m)
eday=$(date -d "$year${month}${day} 15 days" +%d)
echo "$bsf $era y: $year m: $month d: $day ending $eyear-$emonth-$eday"

# domain
abr='nd'
area=72/3/52/33

# Fetch data from the ECMWF MARS 
[ -f ec-sf-$year$month-all-24h-sam.grib ] && echo "SF Data file already downloaded" || /home/users/smartmet/bin/cds-sf-all-24h.py $year $month
[ -f ec-sf-$year$month-pl-12h-sam.grib ] && echo "SF pressurelevel Data file already downloaded" || /home/users/smartmet/bin/cds-sf-pl-12h.py $year $month

# ensure new eccodes and cdo
conda activate xr
[ -f ens/ec-sf_$year${month}_all-24h-sam-50.grib ] && echo "Ensemble member files ready" || grib_copy ec-sf-$year$month-all-24h-sam.grib ens/ec-sf_$year${month}_all-24h-sam-[number].grib
## Make bias-adjustement for single level parameters
### adjust unbound variables
[ -f ens/ec-sf_$year${month}_all-24h-sam-50.grib ] && ! [ -f ens/ec-${bsf}_$year${month}_unbound-24h-sam-50.grib ] && \
 seq 0 50 | parallel cdo -s -b P8 -O --eccodes ymonadd \
    -remap,$era-sam-grid,ec-sf-$era-sam-weights.nc -selname,2d,2t,stl1,swvl1,swvl2 ens/ec-sf_$year${month}_all-24h-sam-{}.grib \
    -selname,2d,2t,stl1,swvl1,swvl2 $era/$era-ecsf_2000-2020_unbound_bias_sam.grib \
    ens/ec-${bsf}_$year${month}_unbound-24h-sam-{}.grib || echo "NOT adj unbound - seasonal forecast input missing or already produced"
### adjust snow variables
[ -f ens/ec-sf_$year${month}_all-24h-sam-50.grib ] && ! [ -f ens/ec-${bsf}_$year${month}_snow-24h-sam-50.grib ] && \
 seq 0 50 | parallel cdo -s -O -b P12 --eccodes setmisstoc,0.0 -aexprf,ec-sde.instr -ymonadd \
    -remap,$era-sam-grid,ec-sf-$era-sam-weights.nc -selname,rsn,sd ens/ec-sf_$year${month}_all-24h-sam-{}.grib \
    -selname,rsn,sd $era/$era-ecsf_2000-2020_unbound_bias_sam.grib \
    ens/ec-${bsf}_$year${month}_snow-24h-sam-{}.grib || echo "NOT adj snow - seasonal forecast input missing or already produced"
### adjust wind
[ -f ens/ec-sf_$year${month}_all-24h-sam-50.grib ] && ! [ -f ens/ec-${bsf}_$year${month}_bound-24h-sam-50.grib ] && \
 seq 0 50 | parallel -q cdo -s -b P8 -O --eccodes ymonmul \
    -remap,$era-sam-grid,ec-sf-$era-sam-weights.nc -aexpr,'ws=sqrt(10u^2+10v^2);' -selname,10u,10v ens/ec-sf_$year${month}_all-24h-sam-{}.grib \
    -aexpr,'10u=ws;10v=ws;' -selname,ws $era/$era-ecsf_2000-2020_bound_bias_sam.grib \
    ens/ec-${bsf}_$year${month}_bound-24h-sam-{}.grib || echo "NOT adj wind - seasonal forecast input missing or already produced"
### adjust evaporation and total precip or other accumulating variables
### due to a clearly too strong variance term in tp adjustment is only done with bias for now
[ -f ens/ec-sf_$year${month}_all-24h-sam-50.grib ] && ! [ -f ens/ec-${bsf}_$year${month}_acc-24h-sam-50.grib ] && \
 seq 0 50 | parallel "cdo -s --eccodes -O mergetime -seltimestep,1 -selname,e,tp ens/ec-sf_$year${month}_all-24h-sam-{}.grib \
     -deltat -selname,e,tp ens/ec-sf_$year${month}_all-24h-sam-{}.grib disacc-tmp-{}.grib && \
    cdo -s --eccodes ymonmul -remap,$era-sam-grid,ec-sf-$era-sam-weights.nc disacc-tmp-{}.grib \
     -selname,e,tp $era/$era-ecsf_2000-2020_bound_bias_sam.grib \
     ens/ec-${bsf}_$year${month}_disacc-24h-sam-{}.grib && \
    cdo -s --eccodes -b P8 timcumsum ens/ec-${bsf}_$year${month}_disacc-24h-sam-{}.grib ens/ec-${bsf}_$year${month}_acc-24h-sam-{}.grib" \
    && rm disacc-tmp-*.grib || echo "NOT adj acc - seasonal forecast input missing or already produced"

## Make stl2,3,4 from stl1
#[ -f ens/ec-sf_$year${month}_all-24h-sam-50.grib ] && ! [ -f ens/ec-${bsf}_$year${month}_stl-24h-sam-50.grib ] && \
# seq 0 50 |parallel -q cdo -s --eccodes -O -b P8 ymonadd -aexpr,'stl2=stl1;stl3=stl1;stl4=stl1;' -remap,$era-sam-grid,ec-sf-$era-sam-weights.nc -selname,stl1 ens/ec-sf_$year${month}_all-24h-sam-{}.grib \
#    -selname,stl1,stl2,stl3,stl4 $era/$era-stls-diff+bias-climate-sam.grib ens/ec-${bsf}_$year${month}_stl-24h-sam-{}.grib \
#    || echo "NOT making stl levels 2,3,4 - seasonal forecast input missing or already produced"
# cdo -s correcting levels for stl2,3,4 segfaults with the below operator:
# changemulti,\'$'(170;*;7|170;*;28);(183;*;7|183;*;100);(236;*;7|236;*;289);'\'

## fix grib attributes
[ -f ens/ec-${bsf}_$year${month}_unbound-24h-sam-50.grib ] && [ ! -f ens/ec-${bsf}_$year${month}_unbound-24h-sam-50-fixed.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_unbound-24h-sam-{}.grib \
    ens/ec-${bsf}_$year${month}_unbound-24h-sam-{}-fixed.grib || echo "NOT fixing unbound gribs attributes - no input or already produced"
[ -f ens/ec-${bsf}_$year${month}_snow-24h-sam-50.grib ] && [ ! -f ens/ec-${bsf}_$year${month}_snow-24h-sam-50-fixed.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_snow-24h-sam-{}.grib \
    ens/ec-${bsf}_$year${month}_snow-24h-sam-{}-fixed.grib || echo "NOT fixing snow gribs attributes - no input or already produced"
[ -f ens/ec-${bsf}_$year${month}_bound-24h-sam-50.grib ] && [ ! -f ens/ec-${bsf}_$year${month}_bound-24h-sam-50-fixed.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_bound-24h-sam-{}.grib \
    ens/ec-${bsf}_$year${month}_bound-24h-sam-{}-fixed.grib || echo "NOT fixing bound gribs attributes - no input or already produced"
[ -f ens/ec-${bsf}_$year${month}_acc-24h-sam-50.grib ] && [ ! -f ens/ec-${bsf}_$year${month}_acc-24h-sam-50-fixed.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_acc-24h-sam-{}.grib \
    ens/ec-${bsf}_$year${month}_acc-24h-sam-{}-fixed.grib || echo "NOT fixing acc gribs attributes - no input or already produced"
[ -f ens/ec-${bsf}_$year${month}_stl-24h-sam-50.grib ] && [ ! -f ens/ec-${bsf}_$year${month}_stl-24h-sam-50-fixed.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-${bsf}_$year${month}_stl-24h-sam-{}.grib \
    ens/ec-${bsf}_$year${month}_stl-24h-sam-{}-fixed.grib || echo "NOT fixing stl gribs attributes - no input or already produced"

## join ensemble members and move to grib folder
[ -f ens/ec-${bsf}_$year${month}_unbound-24h-sam-50-fixed.grib ] && [ ! -f grib/EC${bsf}_$year${month}01T000000_unbound-24h-sam.grib ] &&\
 grib_copy ens/ec-${bsf}_$year${month}_unbound-24h-sam-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_unbound-24h-sam.grib &
[ -f ens/ec-${bsf}_$year${month}_snow-24h-sam-50-fixed.grib ] && [ ! -f grib/EC${bsf}_$year${month}01T000000_snow-24h-sam.grib ] &&\
 grib_copy ens/ec-${bsf}_$year${month}_snow-24h-sam-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_snow-24h-sam.grib &
[ -f ens/ec-${bsf}_$year${month}_bound-24h-sam-50-fixed.grib ] && [ ! -f grib/EC${bsf}_$year${month}01T000000_bound-24h-sam.grib ] &&\
 grib_copy ens/ec-${bsf}_$year${month}_bound-24h-sam-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_bound-24h-sam.grib &
[ -f ens/ec-${bsf}_$year${month}_acc-24h-sam-50-fixed.grib ] && [ ! -f grib/EC${bsf}_$year${month}01T000000_acc-24h-sam.grib ] &&\
 grib_copy ens/ec-${bsf}_$year${month}_acc-24h-sam-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_acc-24h-sam.grib &
[ -f ens/ec-${bsf}_$year${month}_stl-24h-sam-50-fixed.grib ] && [ ! -f grib/EC${bsf}_$year${month}01T000000_stl-24h-sam.grib ] &&\
 grib_copy ens/ec-${bsf}_$year${month}_stl-24h-sam-*-fixed.grib grib/EC${bsf}_$year${month}01T000000_stl-24h-sam.grib &
wait
rm ens/ec-${bsf}_$year${month}_*-24h-sam-*.grib

# add snow depth to ECSF
[ -f ens/ec-sf_$year${month}_all-24h-sam-50.grib ] && [ ! -f ens/ec-sf_$year${month}_all+sde-24h-sam-50.grib ] &&\
 seq 0 50 | parallel cdo -s --eccodes -O aexprf,ec-sde.instr ens/ec-sf_$year${month}_all-24h-sam-{}.grib ens/ec-sf_$year${month}_all+sde-24h-sam-{}.grib ||\
 echo "NOT adding ECSF snow - no input or already produced"
# fix grib attributes for ECSF
[ -f ens/ec-sf_$year${month}_all+sde-24h-sam-50.grib ] && [ ! -f ens/ECSF_$year${month}01T000000_all-24h-sam-50.grib ] && \
 seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-sf_$year${month}_all+sde-24h-sam-{}.grib \
    ens/ECSF_$year${month}01T000000_all-24h-sam-{}.grib || echo "NOT fixing sde gribs attributes - no input or already produced"
# join ensemble members and move to grib folder 
[ -f ens/ECSF_$year${month}01T000000_all-24h-sam-50.grib ] && [ ! -f grib/ECSF_$year${month}01T000000_all-24h-sam.grib ] &&\
grib_copy ens/ECSF_$year${month}01T000000_all-24h-sam-*.grib grib/ECSF_$year${month}01T000000_all-24h-sam.grib || echo "NOT joining ensemble members with sde - no input or already produced"

## Post-process pressure level data

## Split pl to ensemble members 
[ -f ens/ec-sf_$year${month}_pl-12h-sam-50.grib ] && echo "Ensemble member pl files ready" || grib_copy ec-sf-$year${month}-pl-12h-sam.grib ens/ec-sf_$year${month}_pl-12h-sam-[number].grib

## Calculate variables vapour pressures, dew point temps, k-index and add them to the data set
[ -f ens/ec-sf_$year${month}_pl-12h-sam-50.grib ] && ! [ -f ens/ec-sf_$year${month}_pl-pp-12h-sam-50.grib ] && \
seq 0 50 | parallel -q cdo --eccodes -O -b P12 \
        aexpr,'kx=sellevel(t,85000)-sellevel(t,50000)+sellevel(dpt,85000)-(sellevel(t,70000)-sellevel(dpt,70000));' \
        -aexpr,'dpt=log(vp/6.112)*243.5/(17.67-log(vp/6.112));' -aexpr,'ws=sqrt(u^2+v^2);' \
    -aexpr,'wdir=180+180/3.14159265*2*atan(v/(sqr(u^2+v^2)+u));' \
        -aexpr,'vp=clev(q)*q/(0.622+0.378*q);' ens/ec-sf_$year${month}_pl-12h-sam-{}.grib ens/ec-sf_$year${month}_pl-pp-12h-sam-{}.grib || \
 echo "NOT adding kx to ECSF pressure level - no input or already produced"

## fix grib attributes
[ -f ens/ec-sf_$year${month}_pl-pp-12h-sam-50.grib ] && ! [ -f ens/ec-sf_$year${month}_pl-pp-12h-sam-50-fixed.grib ] && \
seq 0 50 | parallel grib_set -r -s centre=98,setLocalDefinition=1,localDefinitionNumber=15,totalNumber=51,number={} ens/ec-sf_$year${month}_pl-pp-12h-sam-{}.grib \
ens/ec-sf_$year${month}_pl-pp-12h-sam-{}-fixed.grib || echo "NOT fixing pl-pp grib attributes - no input or already produced"

## join pl-pp ensemble members and move to grib folder
[ -f ens/ec-sf_$year${month}_pl-pp-12h-sam-50-fixed.grib ] && ! [ -f grib/ECSF_$year${month}01T000000_pl-pp-12h-sam.grib ] && \
grib_copy ens/ec-sf_$year${month}_pl-pp-12h-sam-*-fixed.grib grib/ECSF_$year${month}01T000000_pl-pp-12h-sam.grib || echo "NOT joining pl-pp ensemble members - no input or already produced"
wait 

# produce forcing file for HOPS
# mod. M.Kosmale 18.03.2021: called now independently from cron (v3)
#/home/smartmet/harvesterseasons-hops2smartmet/get-seasonal_hops.sh $year $month

#sudo docker exec smartmet-server /bin/fmi/filesys2smartmet /home/smartmet/config/libraries/tools-grid/filesys-to-smartmet.cfg 0