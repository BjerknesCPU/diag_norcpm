#!/bin/bash

recipes=orig/A*.yml
for ifile in $recipes ; do
    ofile=$(echo $ifile| sed -e's/A/B/' -e's:.*/::')
    sed \
        -e'/^YBE[CASD]: /s/1250/1500/'  \
        -e'/^NY[CASDR]: /s/150/400/'  \
        -e'/^YEARBE: /s/1250/1500/'  \
        -e'/^NYEAR: /s/150/400/'  \
        -e'/^Depends:/,/^[^ ]/s:mpiexm/A:mpiexm/B_400yr/B:' \
        -e's/^\(  *\)REFFRAC: A/\1REFFRAC: B/' \
        -e's/^\(  *\)REFDENO: A/\1REFDENO: B/' \
        -e'/^  *REFDENO: /s/: A/: B/' \
        -e'/^  *RECIPES: /s/: A/: B/' \
    $ifile > $ofile
done
