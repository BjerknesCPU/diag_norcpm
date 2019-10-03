#!/bin/bash

# Copy a global recipe and modifiy it to NAtl
#   by overwrite RG 
#   and insert mk_ln_data.sh section

in_recipes=$*
target='RG'
dst='NAtl'
dstsection='
RG: | # replaced by cpRecipeNAtl.sh
    res@mpLimitMode = "LatLon"
    res@mpMinLatF = 20.
    res@mpMaxLatF = 70.
    res@mpMinLonF = -80.
    res@mpMaxLonF =  10.
    res@mpCenterLatF = 50.
    res@mpCenterLonF =  -35.
    res@mpProjection = "LambertConformal"
    res@mpGridAndLimbOn = True
    res@gsnMaskLambertConformal = True
    res@gsnRightString = "~F34~0~F~C"
'

for i in $in_recipes ; do
    in_recipe="${i}"
    depRecipe="mpiexm/${i}"
    out_recipe=$(echo $i | sed "s/^\([^_]*\)_\(.*\)/\1${dst}_\2/")
    echo "$in_recipe >>-- set ${target} to ${dst} --> $out_recipe"
    # overwrite section
    RGstart=$(grep -n "^${target}" $in_recipe | cut -f1 -d:)
    if [ -z "$RGstart" ] ;then
        echo "        ${target} not found, skip."
        continue
    fi
    ATTS=$(grep -n '^ ' $in_recipe | cut -f1 -d:)
    RGend=$RGstart
    for j in $ATTS ; do
        if [ $j -eq $(expr $RGend + 1) ] ; then
            RGend=$j
        fi
    done

    # output 
    sed -n -e"1,$(expr ${RGstart} - 1)p" $in_recipe     >  $out_recipe
    echo "$dstsection"                                  >> $out_recipe
    sed -n -e"$(expr ${RGend} + 1),\$p" $in_recipe      >> $out_recipe

    # insert Depends for original recipe
    depline=$(grep -n '^Depends:' $out_recipe | cut -f1 -d:)
    if [ -z "$depline" ] ; then
        sed -i -e"${RGstart}iDepends: $depRecipe" $out_recipe
    else 
        sed -i -e"${depline}s|^Depends:\(.*\)|Depends:\1 $depRecipe|" $out_recipe
    fi
done

