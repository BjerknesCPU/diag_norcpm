
;; plot leftest and rightest bin lat/lon plot
;; Rank Histogram (Talagrand Diagram)
;; see https://www.atmos.umd.edu/~ekalnay/syllabi/AOSC630/ensemble101_2014.pdf

;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES section, empty
;;DIAG_NORCPM; TITLE: Rank Histogram
;;DIAG_NORCPM; CACHEFILENAME: 
    ;; cache file name, read it to plot
;;DIAG_NORCPM; CACHEVARNAME: rank_freq

begin
    figfilename = "FIGFILENAME"
    cache = "CACHEFILENAME"+".nc" ;; cache file name
    vn = "CACHEVARNAME"

    f=addfile(cache,"r")
    rank_freq = f->$vn$
    dims = dimsizes(rank_freq)
    binl = rank_freq(0,:,:)
    binr = rank_freq(dims(0)-1,:,:)

    if(isatt(binl,"lat2d"))then
        binl@lat2d := onedtond(binl@lat2d,dims(1:))
        binl@lon2d := onedtond(binl@lon2d,dims(1:))
        binr@lat2d := onedtond(binr@lat2d,dims(1:))
        binr@lon2d := onedtond(binr@lon2d,dims(1:))
    end if
    res = True
        res@gsnDraw  = False     ; don't draw
        res@gsnFrame = False     ; don't advance frame
        res@cnLinesOn = False
        res@cnLineLabelsOn = False   ; turn off cn line label
        res@cnFillOn = True
        res@cnFillMode = "CellFill"
        res@cnLevelSelectionMode = "ManualLevels"
        res@cnMinLevelValF = 0.0
        res@cnMaxLevelValF = 1.0
        res@cnLevelSpacingF  = 0.05
        res@lbLabelBarOn = False

        res@mpLimitMode = "LatLon"
        res@mpMinLonF = -330.
        res@mpMaxLonF =   30.
        res@mpCenterLonF =   -150.

    resP = True
        resP@gsnPanelLabelBar = True

        PLOTRES

    wks = gsn_open_wks("ps",figfilename)
    plot = new(2,"graphic")
    res@gsnLeftString = "Bin 1 rank freq. (model overestimate)"
    plot(0) = gsn_csm_contour_map(wks,binl,res)
    res@gsnLeftString = "Bin "+dims(0)+" rank freq. (model underestimate)"
    plot(1) = gsn_csm_contour_map(wks,binr,res)

    gsn_panel(wks,plot,(/2,1/),resP) 

end
