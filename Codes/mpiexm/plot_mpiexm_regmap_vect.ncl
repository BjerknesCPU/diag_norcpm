
;; plot regression vector map with given time series (netcdf)
;;      yearly time series
;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; CACHEFILENAME: FIGFILENAME
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; MONTHS: 0
    ;; 0, means all months
;;DIAG_NORCPM; ILEV: 0
    ;; vertical level index
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
    uname = "UVARIABLE"
    vname = "VVARIABLE"
    ilev = ILEV
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
        ucor = recover_nc_lat2d_lon2d(f->ucor)
        vcor = recover_nc_lat2d_lon2d(f->vcor)
        ureg = recover_nc_lat2d_lon2d(f->ureg)
        vreg = recover_nc_lat2d_lon2d(f->vreg)
        windreg = recover_nc_lat2d_lon2d(f->windreg)
        windcor = recover_nc_lat2d_lon2d(f->windcor)
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
        uensTZLL = read_mpiexm_season_ensmean_YZLL(case,casedir,component,uname,years,months,modeln)
        vensTZLL = read_mpiexm_season_ensmean_YZLL(case,casedir,component,vname,years,months,modeln)
        uens = uensTZLL(:,ilev,:,:) ;; yearly(seasonal) data
        vens = vensTZLL(:,ilev,:,:) ;; yearly(seasonal) data
        windens = sqrt(uens^2 + vens^2)

        ;; cal reg/cor map
        ureg = regCoef_n(ts,uens,0,0)
        vreg = regCoef_n(ts,vens,0,0)
        windreg = regCoef_n(ts,windens,0,0)
        ucor = escorc_n(ts,uens,0,0)
        vcor = escorc_n(ts,vens,0,0)
        windcor = escorc_n(ts,windens,0,0)

        ;; assign coordinate if those are 2d
        if(isatt(ureg,"lat2d"))then
            ureg@lat2d = uens@lat2d
            ureg@lon2d = uens@lon2d
            vreg@lat2d = vens@lat2d
            vreg@lon2d = vens@lon2d
            ucor@lat2d = uens@lat2d
            ucor@lon2d = uens@lon2d
            vcor@lat2d = vens@lat2d
            vcor@lon2d = vens@lon2d
            windreg@lat2d = uens@lat2d
            windreg@lon2d = uens@lon2d
        else
            copy_VarCoords(uens(0,:,:),ureg)
            copy_VarCoords(vens(0,:,:),vreg)
            copy_VarCoords(uens(0,:,:),ucor)
            copy_VarCoords(vens(0,:,:),vcor)
            copy_VarCoords(uens(0,:,:),vcor)
            copy_VarCoords(uens(0,:,:),windreg)
            copy_VarCoords(uens(0,:,:),windcor)
        end if

        f = addfile(cachefile,"c")
        f->ureg = ureg
        f->vreg = vreg
        f->ucor = ucor
        f->vcor = vcor
        f->windreg = windreg
        f->windcor = windcor
    end if


    res = True
        res@gsnLeftString = title
    PLOTRES

    if(isatt(res,"gsnMaskLambertConformal").and. res@gsnMaskLambertConformal)then
        res@gsnDraw  = False
        res@gsnFrame = False
    end if

    wks = gsn_open_wks("ps",figfn)
    plot = gsn_csm_vector_map(wks,ureg,vreg,res)
    
    ;; if use mask Lambert Conformal projection
    ;; add lat/lon ticmarks by add_lc_labels()
    if(isatt(res,"gsnMaskLambertConformal").and. res@gsnMaskLambertConformal)then
        add_lc_labels(wks,plot,res@mpMinLatF,res@mpMaxLatF,res@mpMinLonF,res@mpMaxLonF)
        draw(plot)
        frame(wks)
    end if

end
