#!/bin/bash

CAA='f08_5AGCMs_NASPG_average'
CNA='IE-average'
year=1180
month=06
metaRecipe=A99E_${CAA}_daily_weather_${year}_${month}.yml

prefix='mpiexm/A99/'
plotRecipes=''
for d in {1..30};do 

    day=$(printf "%2.2d" ${d})
    outfile=A99E_${CAA}_${year}_${month}_${day}.yml
    plotRecipes+=",${prefix}${outfile}"

## headers
cat > $outfile << EOF 
# plot 1 day weather in mpiexm
# mpiexm contains multiple atm(echam6) and one ocn(mpiom) coupling

Title: 1Day QFlux and cloud cover of ${CNA} ${CAA} ${year}-${month}-${day}
Description:  |
    Cloud cover and surface heat flux plots of ${CAA} at ${year}-${month}-${day} </br>
    QFlux is downward heat flux, include sensible, latent heat flux and solar, thermal radiation.
Thumbnail: ${CAA}_Q_FLUX_SFC_mean_${year}_${month}_${day}_thumb.png
COMPONENT:  echam6
VECTORU: u10
VECTORV: v10
SHADING: aclcov
CONTOUR: tsurf
USECACHE: False
YEAR: ${year}
MON: ${month}
DAY: ${day}
MONTH: MON

REG: |
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
    res@mpFillOn = False
PLOTRES: |
    REG
    res@vcMinDistanceF = .02
    res@vcRefLengthF = .05
    res@vcRefMagnitudeF = 20. 
    res@vcGlyphStyle  = "CurlyVector"
    res@vcMonoLineArrowColor  = True
    res@vcLineArrowColor = "yellowgreen"
    res@vcLineArrowThicknessF = 2.5
    res@vcRefAnnoString1  = res@vcRefMagnitudeF+" m/s"

    res@lbBoxSeparatorLinesOn = False
    res@cnLevelSelectionMode = "ExplicitLevels"
    ;res@cnLevels = fspan(-300,-50,91) ;; for trad0
    ;cmap = RGBtoCmap("CODEDIR/mpiexm/Madison_ir.rgb")
    ;res@cnFillPalette = cmap
    ;res@cnLevels = fspan(0.,0.6,61)
    ;res@cnFillPalette = "cmocean_gray"
    res@cnFillMode = "RasterFill"
    res@cnLevels = fspan(.800 ,1.0,26)
    res@cnFillPalette        = "WhiteBlueGreenYellowRed" ; set color map

AVGRES: |
    REG
    res@vcMinDistanceF = .02
    res@vcRefLengthF = .05
    res@vcRefMagnitudeF =  20.
    res@vcGlyphStyle  = "CurlyVector"
    res@vcMonoLineArrowColor  = True
    res@vcLineArrowColor = "yellowgreen"
    res@vcLineArrowThicknessF = 2.5
    res@vcRefAnnoString1  = res@vcRefMagnitudeF+" m/s"
    res@lbBoxSeparatorLinesOn = False
    res@cnLevelSelectionMode = "ExplicitLevels"
    res@cnLevels = fspan(-300,300,201)
    res@cnFillPalette = "NCV_blue_red"


CASEDIR: /tos-project4/NS9207K/pgchiu/CASE
    ## CASE define later

CAA: ${CAA}
CNA: ${CNA}

Scripts:
EOF

## plot scripts
weatherFns=''

    ###### mean QFlux plot
    ##cat >> $outfile << EOF 
    ##-  
    ##    plotScript: mpiexm/plot_1day_weather.ncl
    ##    CASE: CAA
    ##    TITLE: "CNA model mean QFlux at YEAR-MON-DAY"
    ##    MODELN: (/1,2,3,4,5/)
    ##    VECTORU: u10
    ##    VECTORV: v10
    ##    SHADING: Q_FLUX_SFC
    ##    PLOTRES: AVGRES
    ##    FIGFILENAME: CAA_QFlux_mean_YEAR_MON_DAY
    ##EOF
    ##weatherFns+=" CAA_QFlux_mean_${year}_${month}_${day}"
#### cloud cover weather plots
for m in {1..5}; do
cat >> $outfile << EOF 
-  
    plotScript: mpiexm/plot_1day_weather.ncl
    CASE: CAA
    MDN: ${m}
    MODELN: MDN
    TITLE: "CNA model MDN cloud cover and 10 wind at YEAR-MON-DAY"
    FIGFILENAME: CAA_mod${m}_YEAR_MON_DAY
EOF
weatherFns+=" CAA_mod${m}_${year}_${month}_${day}"
done
## QFlux components plots
for var in 'Q_FLUX_SFC' 'ahfs' 'ahfl' 'srads' 'trads' ; do
cat >> $outfile << EOF 
-  
    plotScript: mpiexm/plot_1day_weather.ncl
    CASE: CAA
    TITLE: "CNA model mean ${var} at YEAR-MON-DAY"
    MODELN: (/1,2,3,4,5/)
    VECTORU: u10
    VECTORV: v10
    SHADING: ${var}
    PLOTRES: AVGRES
    FIGFILENAME: CAA_${var}_mean_YEAR_MON_DAY
EOF
weatherFns+=" CAA_${var}_mean_${year}_${month}_${day}"
#### sensible heat flux plots
for m in {1..5}; do
cat >> $outfile << EOF 
-  
    plotScript: mpiexm/plot_1day_weather.ncl
    CASE: CAA
    SHADING: ${var}
    PLOTRES: AVGRES
    MDN: ${m}
    MODELN: MDN
    TITLE: "CNA model MDN ${var} at YEAR-MON-DAY"
    FIGFILENAME: CAA_${var}_mod${m}_YEAR_MON_DAY
EOF
weatherFns+=" ${CAA}_${var}_mod${m}_${year}_${month}_${day}"
done # m
done # var


# footer
cat >> $outfile << EOF 
-  
    plotScript: mk_html_page.sh
    FIGFILES: ${weatherFns}
    COLUMN: mean AGCM1 AGCM2 AGCM3 AGCM4 AGCM5 '</tr><tr>' 'cloud cover' '</tr><tr>' '--' 5 'QFlux' '</tr><tr>' 6 'Sensible Heat Flux' '</tr><tr>' 6 'Latent Heat Flux' '</tr><tr>' 6 'Solar Radiation' '</tr><tr>' 6 'Thermal Radiation' '</tr><tr>' 6
    COMMENT: |
        ECHAM6 model day 10 wind and cloud cover of YEAR-MON-DAY </br>
        QFlux is downward heat flux, include sensible, latent heat flux, solar and thermal radiation.
EOF

done
plotRecipes="${plotRecipes:1}"



# write meta plot
cat > ${metaRecipe} << EOF
# Depends daily weather plot
# mpiexm contains multiple atm(echam6) and one ocn(mpiom) coupling

Title: QFlux and cloud cover meta recipe ${CAA} at ${year}-${month}
Description:  |
    Just a meta recipe. Ignore me please.
ShowInIndex: False
Depends: ${plotRecipes}

Scripts:
-  
    plotScript: mpiexm/mk_daily_ani.sh
    
EOF
