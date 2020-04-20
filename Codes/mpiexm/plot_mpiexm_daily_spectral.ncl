
;; plot daily spectral analysis

;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; CACHEFILENAME: FIGFILENAME
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; MONTHS: 0
    ;; should be 0, means annual time series
;;DIAG_NORCPM; LATBE: -90,90
;;DIAG_NORCPM; LONBE: 0,360
;;DIAG_NORCPM; DETREND: 0
;;DIAG_NORCPM; SMOOTH: 11
;;DIAG_NORCPM; PERCENTTAPER: 0.10
;;DIAG_NORCPM; CONFIDENCELOW: 0.05
;;DIAG_NORCPM; CONFIDENCEHIGH: 0.95
;;DIAG_NORCPM; CONFIDENCELINES: ':'
;;DIAG_NORCPM; RPLRES: ;; RPLRES here
;;DIAG_NORCPM; REDNOISEFILE: none
;;DIAG_NORCPM; OUTPUTREDNOISE: False
    ;; the red line
;;DIAG_NORCPM; REMOVEDAILYCLIMATE: False
;;DIAG_NORCPM; PICKMONTHS: 0
    ;; do spectrum only months


load "CODEDIR/mpiexm/func_read_mpiexm.ncl"
begin
    figfn = "FIGFILENAME"
    cachefile = "CACHEFILENAME"+".nc"
    title = "TITLE"
    varname = "VARIABLE"
    component = "COMPONENT"

    isRemoveDailyClimate = REMOVEDAILYCLIMATE
    pickMonths = PICKMONTHS
    redfn = "REDNOISEFILE"
    outputred = OUTPUTREDNOISE

    case = "CASE"
    casedir = "CASEDIR"
    ybe = (/YEARBE/)
    years = ispan(min(ybe),max(ybe),1)
    months = (/MONTHS/)
    latbe = (/LATBE/)
    lonbe = (/LONBE/)
    if(any(months .eq.0))then
        months := ispan(1,12,1)
    end if

    modeln = MODELN  ;; if use echam6
    nmodel = dimsizes(modeln)

    ;; read daily time series
    if(isfilepresent(cachefile))then
        f = addfile(cachefile,"r")
        varts = f->varts
    else
        varts = read_mpiexm_var_mean_daily_ts_seasonaly(case,casedir,component,varname,years,months,latbe,lonbe,modeln)
        f = addfile(cachefile,"c")
        f->varts = varts
    end if

    dims = dimsizes(varts)
    ndim = dimsizes(dims)

    ;; make array is only time series
    ;; bad idea due to not general
    if(ndim.eq.2 .and. dims(1).eq.1)then ;; for sst
        if(typeof(varts).eq."float")then
            ts = flt2dble(varts(:,0))
        end if
    else
        if(typeof(varts).eq."float")then
            ts = flt2dble(varts)
        end if
    end if

    if(isRemoveDailyClimate)then
        time := cd_calendar(ts&time,0)
        ddd := day_of_year(toint(time(:,0)),toint(time(:,1)),toint(time(:,2)))
        yyyyddd = toint(time(:,0))*1000+ddd
        tsTLL = conform_dims((/dimsizes(ts),1,1/),ts,0)
        clmday = clmDayTLL(tsTLL,yyyyddd)
        dayAnoTLL = calcDayAnomTLL(tsTLL,yyyyddd,clmday)
        ts =  (/dayAnoTLL(:,0,0)/)
        delete(time)
        delete(ddd)
        delete(yyyyddd)
        delete(tsTLL)
        delete(clmday)
        delete(dayAnoTLL)
    end if
    if (.not.any(pickMonths.eq.0))then
        time := cd_calendar(ts&time,0)
        ts_mon = toint(time(:,1))
        l_ts = ts_mon.eq.0 
        do m = 0,dimsizes(pickMonths)-1
            l_ts = l_ts .or. ts_mon.eq.pickMonths(m)
        end do
        ts := ts(ind(l_ts))
        avgnday = num(l_ts)/dimsizes(years)
    end if

    ;; spectral analysis
    ;; ref: https://www.ncl.ucar.edu/Applications/spec.shtml
    d = DETREND
    sm = SMOOTH
    pct = PERCENTTAPER
    confLo = CONFIDENCELOW
    confHi = CONFIDENCEHIGH

    spec = specx_anal(ts,d,sm,pct)
    split = specx_ci(spec, confLo, confHi)

    if (any(pickMonths.eq.0))then
        freq = spec@frq*365. ;; day to year
        period_5day = 73 ;; 
    else
        freq = spec@frq*avgnday ;; seasonal days to year
        period_5day = avgnday/5
    end if

    if(outputred)then
        spec5 = specx_anal(ts/(5^.5),d,sm,pct)
        split5 = specx_ci(spec5, confLo, confHi)

        rednoise = split(1,:)
        rednoise@long_name = "CTL red noise"
        rednoise5 = split5(1,:)
        rednoise5@long_name = "1/5 CTL red noise"
        system("rm -f '"+redfn+"'")
        redf = addfile(redfn,"c")
        redf->rednoise = rednoise
        redf->rednoise5 = rednoise5
    else
        if(redfn.ne."none".and.isfilepresent(redfn))then
            redf = addfile(redfn,"r")
            rednoise = redf->rednoise
            rednoise5 = redf->rednoise5
        end if
        if(redfn.eq."self")then
            rednoise = spec@xvaro/(freq^2)
        end if
    end if

    wks = gsn_open_wks("ps",figfn)

    res = True
        res@trXAxisType = "LogAxis"
        res@trYAxisType = "LogAxis"
        res@gsnFrame = False
        res@gsnLeftString = title
        res@tiXAxisString = "Frequency (1/year)"
        res@tiYAxisString = "Spectral Density"
    PLOTRES

    plot = gsn_csm_xy(wks,freq,split(CONFIDENCELINES,:),res)

    ;; reflines
    rpl = True
        rpl@gsLineThicknessF = 2.
        rpl@gsLineColor = "green"
        rpl@txFontHeightF = 0.01
        rpl@txFontColor = "green"
    ymax = res@trYMaxF
    ymin = res@trYMinF
    gsn_polyline(wks,plot,(/period_5day,period_5day/),(/ymin,ymax/),rpl) ;; x-ref
        rpl@txJust = "CenterRight"
    gsn_text(wks,plot,"5 day period",period_5day-20,ymax*.05,rpl)
    if(isvar("rednoise"))then
            rpl@gsLineColor = "red"
            rpl@txFontColor = "red"
        gsn_polyline(wks,plot,freq,rednoise,rpl)
            rpl@gsLineDashPattern = 2
        gsn_polyline(wks,plot,freq,rednoise5,rpl)

        itext = minind(abs(freq-0.1))
            rpl@txJust = "BottomLeft"
        gsn_text(wks,plot,rednoise@long_name,0.1,rednoise(itext),rpl)
            rpl@txJust = "TopRight"
        gsn_text(wks,plot,rednoise5@long_name,0.1,rednoise5(itext),rpl)
    end if


    if(isatt(res,"gsnFrame").and. res@gsnFrame.eq.False)then
        frame(wks)
    end if
end
