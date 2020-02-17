#!/bin/bash

recipes=orig/A*.yml
for ifile in $recipes ; do
    ofile=$(echo $ifile| sed -e's/A/B/' -e's:.*/::')
    sed \
        -e'/^YBE[CASD]: /s/1250/1500/'  \
        -e'/^NY[CASD]: /s/150/400/'  \
        -e'/^YEARBE: /s/1250/1500/'  \
        -e'/^NYEAR: /s/150/400/'  \
        -e'/^Depends:/,/^[^ ]/s:mpiexm/A:mpiexm/B_400yr/B:' \
        -e'/^  *REFFRAC: /s/: A/: B/' \
        -e'/^  *REFDENO: /s/: A/: B/' \
        -e'/^  *RECIPES: /s/: A/: B/' \
    $ifile > $ofile
done
