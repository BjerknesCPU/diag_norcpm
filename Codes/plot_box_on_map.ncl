;; plot box on map
;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; ADDBOXLATBE: 0.,80.
;;DIAG_NORCPM; ADDBOXLONBE: 0.,80.
;;DIAG_NORCPM; ADDBOXNAME: 0.,80.
;;DIAG_NORCPM; PLOTRES: ;; empty plotres
begin
    figfn = "FIGFILENAME"
    latbe = (/ADDBOXLATBE/)
    lonbe = (/ADDBOXLONBE/)
    boxnames = "aa"

    wks = gsn_open_wks("ps",figfn)


    res = True
        res@gsnFrame = False
        res@mpFillOn = False
        res@mpGridAndLimbOn = True
        res@mpGridAndLimbDrawOrder = "PreDraw"          ; Draw grid first
        res@mpLimitMode = "LatLon"
        res@mpGridLineDashPattern  = 5                  ; lat/lon lines dashed
        res@mpGridLineColor = "grey"

        res@mpMinLonF = -330.
        res@mpMaxLonF =   30.
        res@mpCenterLonF =   -150.

    lineres = True
        lineres@gsLineColor = "red"
        lineres@gsLineThicknessF = 3.0

    PLOTRES

    plot = gsn_csm_map(wks,res)

    ;; draw box
    ;;;; conter-clockwise
    lats = (/min(latbe),min(latbe),max(latbe),max(latbe),min(latbe)/)
    lons = (/min(lonbe),max(lonbe),max(lonbe),min(lonbe),min(lonbe)/)

    gsn_polyline(wks,plot,lons,lats,lineres)

    frame(wks)
end
