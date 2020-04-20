#!/bin/bash

## calculate ANOVA with cdo
## which is a statical method to analysis the variance between model members

## not done yet
## maybe obsoleted

#;DIAG_NORCPM; OUTPUTFILENAME: cache
#;DIAG_NORCPM; MODELN: 1,2,3,4,5

exit

case="CASE"
casedir="CASEDIR"
modeln=$(echo "MODELN" | sed 's/,/ /g')
ybe=$(echo "YEARBE" | sed 's/,/ /g')
months=$(echo "MONTHS" | sed 's/,/ /g')
if [ "${months}" == '0' ]; then
    months=$(seq 1 12)
fi
varname="VARIABLE"
component="COMPONENT"
output="OUTPUTFILENAME.nc"
cdo=`which cdo`

workdir="tmp_anova_${case}_${component}_${varname}"

mkdir -p "${workdir}"

