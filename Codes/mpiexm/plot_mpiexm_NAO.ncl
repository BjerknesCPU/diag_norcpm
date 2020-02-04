
;; plot NAO index
;; see method of Wang et al. 2017
;;      A robust empirical seasonal prediction of winter NAO and surface climate
;;      doi:10.1038/s41598-017-00353-y
;;          NAO is defined as the difference between the monthly mean sea level pressure (SLP) anomalies averaged over the domains of (50W-10E, 25-55N) and (40W-20E, 55-85N).

;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; CACHEFILENAME: FIGFILENAME
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; MONTHS: 0
    ;; 0, means all months
;;DIAG_NORCPM; MODELN: 0
;;DIAG_NORCPM; LATBEA: 25.,55.
;;DIAG_NORCPM; LONBEA: -50.,10.
;;DIAG_NORCPM; LATBEB: 55.,85.
;;DIAG_NORCPM; LONBEB: -40.,20.
    ;; difference: A-B
;;DIAG_NORCPM; STANDARIZED: True



load "CODEDIR/mpiexm/func_read_mpiexm.ncl"
begin
    figfn = "FIGFILENAME"
    cachefile = "CACHEFILENAME"+".nc"
    title = "TITLE"
    varname = "VARIABLE"
    component = "COMPONENT"

    isStandarized = STANDARIZED

    case = "CASE"
    casedir = "CASEDIR"
    ybe = (/YEARBE/)
    years = ispan(min(ybe),max(ybe),1)
    months = (/MONTHS/)
    latbeA = (/LATBEA/)
    lonbeA = (/LONBEA/)
    latbeB = (/LATBEB/)
    lonbeB = (/LONBEB/)
    if(any(months .eq.0))then
        months := ispan(1,12,1)
    end if

    modeln = MODELN  ;; if use echam6
    nmodel = dimsizes(modeln)

    ;; read daily time series
    if(isfilepresent(cachefile))then
        f = addfile(cachefile,"r")
        tsdif = f->tsdif
    else
        vartsA = read_mpiexm_var_mean_daily_ts_seasonaly(case,casedir,component,varname,years,months,latbeA,lonbeA,modeln)
        vartsB = read_mpiexm_var_mean_daily_ts_seasonaly(case,casedir,component,varname,years,months,latbeB,lonbeB,modeln)
        ;; daily to monthly (echam6)
        tsMonA = calculate_monthly_values(vartsA,"avg",0,False)
        tsMonB = calculate_monthly_values(vartsB,"avg",0,False)
        ;; monthly to season (annual)
        ny = dimsizes(years)
        nm = dimsizes(months)
        tsSeaA = new(ny, typeof(tsMonA))
        tsSeaB = new(ny, typeof(tsMonB))
        do y = 0, ny-1
            t1 = y*nm
            t2 = ((y+1)*nm)-1
            tsSeaA(y) = avg(tsMonA(t1:t2))
            tsSeaB(y) = avg(tsMonB(t1:t2))
        end do
        tsSeaA!0 = "year"
        tsSeaA&year = years
        tsSeaB!0 = "year"
        tsSeaB&year = years

        tsdif = tsSeaA
        tsdif = tsSeaA - tsSeaB

        f = addfile(cachefile,"c")
        f->tsdif = tsdif
        f->tsSeaA = tsSeaA
        f->tsSeaB = tsSeaB
    end if


    if(isStandarized)then
        tsdif = tsdif - avg(tsdif)
        tsdifstd = stddev(tsdif)
        tsdif = tsdif/tsdifstd
    end if

    wks = gsn_open_wks("ps",figfn)

    res = True
        res@trXMaxF = max(years) +1
        res@trXMinF = min(years) -1
        res@gsnYRefLine = 0.
        res@gsnLeftString = title
        res@gsnRightString = "std.="+sprintf("%2.2f",tsdifstd)
    PLOTRES

    plot = gsn_csm_xy(wks,years,tsdif,res)

    if(isatt(res,"gsnFrame").and. res@gsnFrame.eq.False)then
        frame(wks)
    end if
end
