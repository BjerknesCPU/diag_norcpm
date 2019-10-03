#!/bin/bash

## link nc data file from other recipe dir
#;;diag_norcpm;; RECIPES: empty

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
    ln -fs ../$i/*.nc .
done
