

;; plot regression/correlation map with given time series (netcdf)
;;      yearly time series
;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; CACHEFILENAME: FIGFILENAME
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; MONTHS: 0
    ;; 0, means all months
;;DIAG_NORCPM; MODELN: 0
;;DIAG_NORCPM; REGRESSION: True 
    ;; True: regression map
    ;; False: correlation map
;;DIAG_NORCPM; TSNETCDFFILE: 
;;DIAG_NORCPM; TSVARNAME: 


load "CODEDIR/mpiexm/func_read_mpiexm.ncl"
begin
    figfn = "FIGFILENAME"
write_table("figfilelist.txt","a",[/figfn/],"%s") ;; for mk_html_page.sh
    cachefile = "CACHEFILENAME"+".nc"
    title = "TITLE"
    varname = "VARIABLE"
    component = "COMPONENT"

    tsFn = "TSNETCDFFILE.nc"
    tsVn = "TSVARNAME"

    modeln = MODELN  ;; if use echam6
    nmodel = dimsizes(modeln)

    ;; read daily time series
        ;; given time series
        df = addfile(tsFn,"r")
        ts = df->$tsVn$  ;; yearly time series
    df = addfile("/nird/home/pgchiu/NS9039K/shared/obsdata/gridded/SST/HadISST_sst_187001-201910.nc","r")
    sst = df->sst(:1787,:,:) ;; 1870-2018
    time = cd_calendar(sst&time,0)
    varyzll = month_to_annual(sst,1)
    varyzll = where(varyzll.lt.-2.,varyzll@_FillValue,varyzll)
    varens := varyzll(:,::-1,:)
    yb = toint(min(time(:,0)))
    ye = toint(max(time(:,0)))
    ybe = (/yb,ye/)
    varens&year = ispan(yb,ye,1)

        ;; cal reg/cor map
        regmap = regCoef_n(ts,varens,0,0)

        ;; assign coordinate if those are 2d
        copy_VarCoords(varens(0,:,:),regmap)


    res = True
        res@gsnLeftString = title
    PLOTRES

    if(isatt(res,"gsnMaskLambertConformal").and. res@gsnMaskLambertConformal)then
        res@gsnDraw  = False
        res@gsnFrame = False
    end if

    wks = gsn_open_wks("ps",figfn)
    plot = gsn_csm_contour_map(wks,regmap,res)
    
    ;; if use mask Lambert Conformal projection
    ;; add lat/lon ticmarks by add_lc_labels()
    if(isatt(res,"gsnMaskLambertConformal").and. res@gsnMaskLambertConformal)then
        add_lc_labels(wks,plot,res@mpMinLatF,res@mpMaxLatF,res@mpMinLonF,res@mpMaxLonF)
        draw(plot)
        frame(wks)
    end if

end
