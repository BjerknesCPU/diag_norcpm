;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; GRIDNCFN: /projects/NS9207K/pgchiu/mpiexm_plot/GR15_rbek_fx.nc
;;DIAG_NORCPM; WEIGHTNCFN: /projects/NS9207K/pgchiu/mpiexm_plot/WeightingMap4MPIOM_NA_20N_5.nc
;;DIAG_NORCPM; PLOTRES:  ;; PLOTRES


undef   ("add_lc_labels")
procedure add_lc_labels(wks,map,minlat,maxlat,minlon,maxlon)
;; add lat/lon tickmarks for masked Lambert Conformal projection.
;; copy from https://www.ncl.ucar.edu/Applications/Scripts/mptick_10.ncl
    local lat_values, nlat, lat1_ndc, lat2_ndc, lon1_ndc, lon2_ndc,slope,txres, \
    lon_values, PI, RAD_TO_DEG, dum_lft, dum_rgt, dum_bot, rotate_val \
    , dlon
    begin
      PI         = 3.14159
      RAD_TO_DEG = 180./PI
      dlon = 15
      dlat = 15

    ;---Determine whether we are in northern or southern hemisphere
      if(minlat.ge.0.and.maxlat.gt.0) then
        HEMISPHERE = "NH"
      else
        HEMISPHERE = "SH"
      end if

    ;---Pick some "nice" values for the latitude labels.
      ;lat_values = ispan(toint(minlat),toint(maxlat),dlat) * 1.
      all_lat_values = ispan(-90,90,dlat)
      lat_values = all_lat_values(ind(all_lat_values.ge.minlat .and. all_lat_values.le.maxlat))
      nlat       = dimsizes(lat_values) -1
    ;
    ; We need to get the slope of the left and right min/max longitude lines.
    ; Use NDC coordinates to do this.
    ;
      lat1_ndc = new(1,float)
      lon1_ndc = new(1,float)
      lat2_ndc = new(1,float)
      lon2_ndc = new(1,float)
      datatondc(map,minlon,lat_values(0)*1.,lon1_ndc,lat1_ndc)
      datatondc(map,minlon,lat_values(nlat-1)*1.,lon2_ndc,lat2_ndc)
      slope_lft = (lat2_ndc-lat1_ndc)/(lon2_ndc-lon1_ndc)
      datatondc(map,maxlon,lat_values(0)*1.,lon1_ndc,lat1_ndc)
      datatondc(map,maxlon,lat_values(nlat-1)*1.,lon2_ndc,lat2_ndc)
      slope_rgt = (lat2_ndc-lat1_ndc)/(lon2_ndc-lon1_ndc)

    ;---Set some text resources
      txres               = True
      txres@txFontHeightF = 0.01
      txres@txPosXF       = 0.1
    ;
    ; Loop through lat values, and attach labels to the left and
    ; right edges of the masked LC plot.  The labels will be 
    ; rotated to fit the line better.
    ;
      dum_lft = new(nlat,graphic)    ; Dummy array to hold attached strings.
      dum_rgt = new(nlat,graphic)    ; Dummy array to hold attached strings.
      do n=0,nlat-1
    ;---Left label
        if(HEMISPHERE.eq."NH") then
          rotate_val = -90
          direction  = "N"
        else
          rotate_val = 90
          direction  = "S"
        end if

    ; Add extra white space to labels.
        lat_label_lft = abs(lat_values(n)) + "~S~o~N~" + direction + \
                        "          "   
        lat_label_rgt = "          "  + abs(lat_values(n)) + "~S~o~N~" + \
                        direction

        txres@txAngleF = RAD_TO_DEG * atan(slope_lft) + rotate_val
    if(False)then ;; turn off left label
        dum_lft(n) = gsn_add_text(wks,map,lat_label_lft,minlon,lat_values(n),txres)
    end if
    ;---Right label
        if(HEMISPHERE.eq."NH") then
          rotate_val = 90
        else
          rotate_val = -90
        end if
        txres@txAngleF = RAD_TO_DEG * atan(slope_rgt) + rotate_val
        dum_rgt(n) = gsn_add_text(wks,map,lat_label_rgt,maxlon,lat_values(n),txres)
      end do

    ;----------------------------------------------------------------------
    ; Now do longitude labels. These are harder because we're not
    ; adding them to a straight line.
    ;
    ; Loop through lon values, and attach labels to the bottom edge
    ; for northern hemisphere, or top edge for southern hemisphere.
    ;
      delete(txres@txPosXF)
      txres@txPosYF = -5.0
    ;---Pick some "nice" values for the longitude labels.
      lon_values = ispan(toint(minlon-dlon),toint(maxlon+dlon),dlon) * 1.
      lon_values = lon_values - mod(lon_values,dlon)
      nlon       = dimsizes(lon_values) -1
      lon_values = where(lon_values.gt.180,360-lon_values,lon_values)

      dum_bot = new(nlon,graphic)    ; Dummy array to hold attached strings.

      lon_labels = "" + lon_values
      lon_labels = where(lon_values.lt.0, abs(lon_values) + \
                        "~S~o~N~W",""+lon_labels)
      lon_labels = where(lon_values.eq.0,"0",lon_labels)
      lon_labels = where(lon_values.gt.0,lon_values + "~S~o~N~E",lon_labels)
      if(HEMISPHERE.eq."NH") then
        lon_labels = "  ~C~  ~C~" + lon_labels
        lat_val   = minlat
      else
        lon_labels = lon_labels + "~C~ ~C~ "
        lat_val    = maxlat
      end if

      do n=0,nlon-1
    ;
    ; For each longitude label, we need to figure out how much to rotate
    ; it, so get the approximate slope at that point.
    ;
        if(HEMISPHERE.eq."NH") then
    ;---Add labels to bottom of LC plot
          datatondc(map,lon_values(n)-0.25,minlat,lon1_ndc,lat1_ndc)
          datatondc(map,lon_values(n)+0.25,minlat,lon2_ndc,lat2_ndc)
        else
    ;---Add labels to top of LC plot
          datatondc(map,lon_values(n)+0.25,maxlat,lon1_ndc,lat1_ndc)
          datatondc(map,lon_values(n)-0.25,maxlat,lon2_ndc,lat2_ndc)
        end if
        slope_bot = (lat1_ndc-lat2_ndc)/(lon1_ndc-lon2_ndc)
        txres@txAngleF  = atan(slope_bot) * RAD_TO_DEG
    ;
    ; Create longitude label. Add extra carriage returns to
    ; move label away from plot.
    ;

    ;---Attach to map.
        dum_bot(n) = gsn_add_text(wks,map,lon_labels(n),lon_values(n),\
                                  lat_val,txres)
      end do
end

figfn = "FIGFILENAME"
title = "TITLE"

gridfn="GRIDNCFN"
f = addfile(gridfn,"r")
lon = f->lon
lat = f->lat


fn = "WEIGHTNCFN"
f = addfile(fn,"r")

var1d = f->var511(0,:)

var = onedtond(var1d,dimsizes(lon))

res = True
    res@sfXArray = lon
    res@sfYArray = lat
    res@gsnAddCyclic = False
    res@mpLimitMode = "LatLon"
    res@mpMinLatF = 10.
    res@mpMaxLatF = 80.
    res@mpMinLonF = -100.
    res@mpMaxLonF =  30.
    res@mpCenterLatF = 50.
    res@mpCenterLonF =  -35.
    res@mpProjection = "LambertConformal"
    res@mpGridAndLimbOn = True
    res@gsnMaskLambertConformal = True
    res@gsnFrame = False
    res@gsnDraw = False
    res@tiMainString = title

    res@cnFillOn = True
    res@cnLinesOn = False
    res@cnFillMode = "CellFill"
    res@cnLevelSelectionMode = "ExplicitLevels"
    res@cnLevels = (/0.21,0.5,.99/)
    res@cnFillColors = (/"lightskyblue","lightsteelblue2","lightslategray","lightpink"/)

    PLOTRES

wks = gsn_open_wks("ps",figfn)
plot = gsn_csm_contour_map(wks,var,res)


add_lc_labels(wks,plot,res@mpMinLatF,res@mpMaxLatF,res@mpMinLonF,res@mpMaxLonF)
if(isatt(res,"gsnDraw").and.res@gsnDraw.eq.False)then
    draw(plot)
end if
if(isatt(res,"gsnFrame").and.res@gsnFrame.eq.False)then
    frame(wks)
end if
