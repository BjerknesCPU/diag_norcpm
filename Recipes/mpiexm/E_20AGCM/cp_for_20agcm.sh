#!/bin/bash

recipes=orig/A*.yml
for ifile in $recipes ; do
    ofile=$(echo $ifile| sed -e's/A/E/' -e's:.*/::')
    sed \
        -e'/^YBE[CASD]: /s/1250/1150/'  \
        -e'/^NY[CASD]: /s/150/50/'  \
        -e'/^YEARBE: /s/1250/1150/'  \
        -e'/^NYEAR: /s/150/50/'  \
        -e's/f09_5AGCMs_NASPG_sample/f08_20AGCMs_NASPG_test/'  \
        -e's/IE-sample/IE-average20/'  \
        -e'/^Depends:/,/^[^ ]/s:mpiexm/A:mpiexm/E_20AGCM/E:' \
        -e'/^  *REFFRAC: /s/: A/: E/' \
        -e'/^  *REFDENO: /s/: A/: E/' \
        -e'/^  *RECIPES: /s/: A/: E/' \
    $ifile > $ofile
done
