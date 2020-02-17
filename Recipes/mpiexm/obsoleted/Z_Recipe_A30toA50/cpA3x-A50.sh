#!/bin/bash

# A3x recipes are making spectral analysis
# A5x recipes do the same thing, but with annual cycle remove

exit ## obsoleted now

recipes=A3*.yml

for infile in $recipes ; do
    outfile=$(echo $infile | sed 's/A3/A5/')
    inrecp=${infile%.*}
    echo "$infile -> $outfile"
    sed -e'/^Title:/s/spectral/(annual cycle removed) spectral/'   \
        -e'/^Description:/s/spectral/(annual cycle removed) spectral/'   \
        -e'/^COMMENT:/s/spectral/(annual cycle removed) spectral/'   \
        -e"23iREMOVEDAILYCLIMATE: True\nDepends: mpiexm/$infile"  \
        -e'/^  *TITLE/s/Daily/Daily acr/'  \
        -e'/^  *TITLE/s/spectral/spec./'  \
        -e"s/^Scripts:/Scripts:\n-  # ln -s data from other recipe\n    plotScript: mk_ln_data.sh\n    RECIPES: ${inrecp}/" \
        "$infile"  > "$outfile"
done
