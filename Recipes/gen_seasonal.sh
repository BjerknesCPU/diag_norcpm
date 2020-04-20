#!/bin/bash

declare -a seasons
seasons=(FMA MJJ ASO NDJ FMA MJJ ASO NDJ FMA MJJ ASO NDJ FMA MJJ ASO NDJ)
iseason=(Jan Apr Jul Oct)
imonth=(01 04 07 10 )
for j in {1..4} ; do ## lead season
for i in {1..4} ; do ## 
leads=$j # lead season
init=${iseason[$(expr $i - 1)]} # initial month
initm=${imonth[$(expr $i - 1)]}
sea=${seasons[$(expr $i + $j - 2)]} # forecast season
        echo "-  # lead season ${leads}, init ${init}, global"
        echo "    plotScript: plot_rank_histogram.ncl"
        echo "    TITLE: SST REG rank histogram"
        echo "    TITLELEFT: REG"
        echo "    FIGFILENAME: sst_global_rank_histogram_lead${leads}_${sea}"
        echo "    LEADSEASON: ${leads}"
        echo "    REG: global"
        echo "    LATB: -90."
        echo "    LATE:  90."
        echo "    LONB:   0."
        echo "    LONE: 360."
        echo "    CACHEFILENAME: sst_rank_freq_lead${leads}_${sea}  # cache is made global"
        echo "    # for all forecast start from ${init}"
        echo "    FORECASTDIRS: BASEDIR/RUNPRE{1,2}???${initm}??"

        echo "-  # lead season ${leads}, init ${init}, NAtl"
        echo "    plotScript: plot_rank_histogram.ncl"
        echo "    TITLE: SST REG rank histogram"
        echo "    TITLELEFT: REG"
        echo "    FIGFILENAME: sst_NAtl_rank_histogram_lead${leads}_${sea}"
        echo "    LEADSEASON: ${leads}"
        echo "    REG: NAtl"
        echo "    LATB:   20."
        echo "    LATE:   70."
        echo "    LONB: -110."
        echo "    LONE:   40."
        echo "    CACHEFILENAME: sst_rank_freq_lead${leads}_${sea}  # cache is made global"
        echo "    # for all forecast start from ${init}"
        echo "    FORECASTDIRS: BASEDIR/RUNPRE{1,2}???${initm}??"

        echo "-  # lead season ${leads}, init ${init}, WNPac"
        echo "    plotScript: plot_rank_histogram.ncl"
        echo "    TITLE: SST REG rank histogram"
        echo "    TITLELEFT: REG"
        echo "    FIGFILENAME: sst_WNPac_rank_histogram_lead${leads}_${sea}"
        echo "    LEADSEASON: ${leads}"
        echo "    REG: WNPac"
        echo "    LATB:   20."
        echo "    LATE:   70."
        echo "    LONB:  110."
        echo "    LONE:  180."
        echo "    CACHEFILENAME: sst_rank_freq_lead${leads}_${sea}  # cache is made global"
        echo "    # for all forecast start from ${init}"
        echo "    FORECASTDIRS: BASEDIR/RUNPRE{1,2}???${initm}??"
done
done
