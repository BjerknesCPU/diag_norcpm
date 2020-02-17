
;; plot daily spectral analysis

;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; OUTPUTFILENAME: FIGFILENAME
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; DETREND: 0
;;DIAG_NORCPM; SMOOTH: 11
;;DIAG_NORCPM; PERCENTTAPER: 0.10
;;DIAG_NORCPM; CONFIDENCELOW: 0.05
;;DIAG_NORCPM; CONFIDENCEHIGH: 0.95
;;DIAG_NORCPM; CONFIDENCELINES: ':'
;;DIAG_NORCPM; RPLRES: ;; RPLRES here
;;DIAG_NORCPM; REDNOISEFILEFRAC: none
;;DIAG_NORCPM; REDNOISEFILEDENO: none
;;DIAG_NORCPM; REMOVEDAILYCLIMATE: False
    ;; the red line


load "CODEDIR/mpiexm/func_read_mpiexm.ncl"
begin
    figfn = "FIGFILENAME"
    title = "TITLE"
    outputfn = "OUTPUTFILENAME.nc" ;; output data only

    redfn_frac = "REDNOISEFILEFRAC"
    redfn_deno = "REDNOISEFILEDENO"

    datafnFrac = "DATAFNFRAC"
    datafnDeno = "DATAFNDENO"

    isRemoveDailyClimate = REMOVEDAILYCLIMATE

    ff = addfile(datafnFrac,"r")
    ts_frac = ff->varts
    fd = addfile(datafnDeno,"r")
    ts_deno = fd->varts

    ;; remove additional dim
    dims := dimsizes(ts_frac)
    ndim = dimsizes(dims)
    if(ndim.eq.2 .and. dims(1).eq.1)then 
        ts_frac := flt2dble(ts_frac(:,0))
    else
        ts_frac := flt2dble(ts_frac)
    end if
    dims := dimsizes(ts_deno)
    ndim = dimsizes(dims)
    if(ndim.eq.2 .and. dims(1).eq.1)then 
        ts_deno := flt2dble(ts_deno(:,0))
    else
        ts_deno := flt2dble(ts_deno)
    end if

    
    if(isRemoveDailyClimate)then ;; remove annual cycle
        time := cd_calendar(ts_deno&time,0)
        ddd := day_of_year(toint(time(:,0)),toint(time(:,1)),toint(time(:,2)))
        yyyyddd = toint(time(:,0))*1000+ddd
        ts_denoTLL = conform_dims((/dimsizes(ts_deno),1,1/),ts_deno,0)
        clmday = clmDayTLL(ts_denoTLL,yyyyddd)
        dayAnoTLL = calcDayAnomTLL(ts_denoTLL,yyyyddd,clmday)
        ts_deno =  (/dayAnoTLL(:,0,0)/)
        delete(time)
        delete(ddd)
        delete(yyyyddd)
        delete(ts_denoTLL)
        delete(clmday)
        delete(dayAnoTLL)

        time := cd_calendar(ts_frac&time,0)
        ddd := day_of_year(toint(time(:,0)),toint(time(:,1)),toint(time(:,2)))
        yyyyddd = toint(time(:,0))*1000+ddd
        ts_fracTLL = conform_dims((/dimsizes(ts_frac),1,1/),ts_frac,0)
        clmday = clmDayTLL(ts_fracTLL,yyyyddd)
        dayAnoTLL = calcDayAnomTLL(ts_fracTLL,yyyyddd,clmday)
        ts_frac =  (/dayAnoTLL(:,0,0)/)
        delete(time)
        delete(ddd)
        delete(yyyyddd)
        delete(ts_fracTLL)
        delete(clmday)
        delete(dayAnoTLL)
    end if
    
    ;; for difference length, take min one
    nt = min((/dimsizes(ts_frac),dimsizes(ts_deno)/))
    ts_frac := ts_frac(:nt-1)
    ts_deno := ts_deno(:nt-1)


    ;; spectral analysis
    ;; ref: https://www.ncl.ucar.edu/Applications/spec.shtml
    d = DETREND
    sm = SMOOTH
    pct = PERCENTTAPER
    confLo = CONFIDENCELOW
    confHi = CONFIDENCEHIGH

    spec_frac = specx_anal(ts_frac,d,sm,pct)
    spec_deno = specx_anal(ts_deno,d,sm,pct)
    splt_frac = specx_ci(spec_frac, confLo, confHi)
    splt_deno = specx_ci(spec_deno, confLo, confHi)

    splt_ratio = splt_frac/splt_deno

    freq = spec_frac@frq*365. ;; day to year

    if(.not.any("none" .eq. (/redfn_frac,redfn_deno/))) ;; with red noise file
        f = addfile(redfn_frac,"r")
        rn_frac = f->rednoise
        f = addfile(redfn_deno,"r")
        rn_deno = f->rednoise

        ;; align
        nt = min((/dimsizes(rn_frac),dimsizes(rn_deno)/))
        rn_frac := rn_frac(:nt-1)
        rn_deno := rn_deno(:nt-1)

        rn_ratio = rn_frac
        rn_ratio = rn_frac/rn_deno
        rn_ratio@long_name = "CTL red response"
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

    plot = gsn_csm_xy(wks,freq,splt_ratio(CONFIDENCELINES,:),res)

    ;; output plotted data
    system("rm -f "+outputfn)
    f = addfile(outputfn,"c")
    f->freq = freq
    f->splt_ratio = splt_ratio(CONFIDENCELINES,:)

    ;; reflines
    rpl = True
        rpl@gsLineThicknessF = 2.
        rpl@gsLineColor = "green"
        rpl@txFontHeightF = 0.01
        rpl@txFontColor = "green"
    period_5day = 73 ;; 
    ymax = res@trYMaxF
    ymin = res@trYMinF
            gsn_polyline(wks,plot,(/period_5day,period_5day/),(/ymin,ymax/),rpl) ;; x-ref
                rpl@txJust = "CenterRight"
            gsn_text(wks,plot,"5 day period",period_5day-20,ymax*.05,rpl)

        rpl@gsLineColor = "red"
        rpl@txFontColor = "red"
    itext = minind(abs(freq-0.1))
    if(isvar("rn_ratio"))then
        gsn_polyline(wks,plot,freq,rn_ratio,rpl)
            rpl@txJust = "BottomLeft"
        gsn_text(wks,plot,rn_ratio@long_name,0.1,rn_ratio(itext),rpl)
    end if
    if(isvar("rn5_ratio"))then
            rpl@gsLineDashPattern = 2
        gsn_polyline(wks,plot,freq,rn5_ratio,rpl)
            rpl@txJust = "TopRight"
        gsn_text(wks,plot,rn5_ratio@long_name,0.1,rn5_ratio(itext),rpl)
    end if

    if(isatt(res,"gsnFrame").and. res@gsnFrame.eq.False)then
        frame(wks)
    end if
end
