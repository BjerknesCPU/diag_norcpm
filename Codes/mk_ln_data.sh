#!/bin/bash

## link nc data file from other recipe dir
#;DIAG_NORCPM; RECIPES: empty

recipes="RECIPES"
nowdir=$(pwd|sed "s:.*/::")

if [ "$recipes" == "empty" ]; then
    echo "No recipes to make link."
    exit
fi
if [ "$recipes" == "$nowdir" ]; then
    echo "Noneed to make link in same recipe"
    exit
fi

for i in $recipes ; do
    ii=$(basename $i)
    ii=${ii%.*}
    for iii in ../$ii/*.nc; do
        ln -fs "${iii}" .
    done
done
