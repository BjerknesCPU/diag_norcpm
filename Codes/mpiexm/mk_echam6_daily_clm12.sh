#!/bin/bash

## make monthly cache file from echam6 daily data
## not done yet

#;DIAG_NORCPM; VARIABLE: none

case='CASE'
datapath="DATAPATH"
component="COMPONENT"
yb="YEARBEGIN"
ye="YEAREND"
variable="VARIABLE"

## file list
filelist=''
for i in {YEARBEGIN..YEAREND}; do
    filelist="${filelist} ${datapath}/outdata/${component}/${case}_echam6_/"
done


cdo -f nc -t echam6 -copy -select,name=tsurf '/tos-project4/NS9207K/earnest/mpiexm_exp/f05_1AGCM/outdata/echam6/f05_1AGCM_echam6_echam_2000??.grb' out.nc

