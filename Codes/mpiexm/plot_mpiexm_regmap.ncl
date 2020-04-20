
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
    cachefile = "CACHEFILENAME"+".nc"
    title = "TITLE"
    varname = "VARIABLE"
    component = "COMPONENT"

    tsFn = "TSNETCDFFILE.nc"
    tsVn = "TSVARNAME"

    case = "CASE"
    casedir = "CASEDIR"
    ybe = (/YEARBE/)
    years = ispan(min(ybe),max(ybe),1)
    months = (/MONTHS/)
    if(any(months .eq.0))then
        months := ispan(1,12,1)
    end if

    modeln = MODELN  ;; if use echam6
    nmodel = dimsizes(modeln)

    ;; read daily time series
    if(isfilepresent(cachefile))then
        f = addfile(cachefile,"r")
        regmap = recover_nc_lat2d_lon2d(f->regmap)
        cormap = recover_nc_lat2d_lon2d(f->cormap)
    else
        ;; given time series
        df = addfile(tsFn,"r")
        ts = df->$tsVn$  ;; yearly time series
        years = ispan(min(ybe),max(ybe),1)
        if(dimsizes(ts) .ne. dimsizes(years))then
            print("plot_mpiexm_regmap.ncl: Error, dimsize not match")
            exit
        end if

        ;; read data
        varensTZLL = read_mpiexm_season_ensmean_YZLL(case,casedir,component,varname,years,months,modeln)
        varens = varensTZLL(:,0,:,:) ;; yearly(seasonal) data

        ;; cal reg/cor map
        regmap = regCoef_n(ts,varens,0,0)
        cormap = escorc_n(ts,varens,0,0)

        ;; assign coordinate if those are 2d
        if(isatt(varens,"lat2d"))then
            regmap@lat2d = varens@lat2d
            regmap@lon2d = varens@lon2d
            cormap@lat2d = varens@lat2d
            cormap@lon2d = varens@lon2d
        end if

        copy_VarCoords(varens(0,:,:),regmap)
        copy_VarCoords(varens(0,:,:),cormap)
        f = addfile(cachefile,"c")
        f->regmap = regmap
        f->cormap = cormap
    end if


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
