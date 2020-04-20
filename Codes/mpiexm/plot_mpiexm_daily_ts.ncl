
;; plot area mean time series of mpiexm

;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; CACHEFILENAME: FIGFILENAME
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; MONTHS: 0
    ;; 0, means all months
;;DIAG_NORCPM; MODELN: 0
;;DIAG_NORCPM; LATBE: 25.,55.
;;DIAG_NORCPM; LONBE: -50.,10.
;;DIAG_NORCPM; STANDARIZED: True



load "CODEDIR/mpiexm/func_read_mpiexm.ncl"
begin
    figfn = "FIGFILENAME"
write_table("figfilelist.txt","a",[/figfn/],"%s") ;; for mk_html_page.sh
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
        ts = f->ts
        if (dimsizes(dimsizes(ts)).gt.1)then
            ts := ts(:,0)
        end if
    else
        ts = read_mpiexm_var_mean_daily_ts_seasonaly(case,casedir,component,varname,years,months,latbe,lonbe,modeln)

        f = addfile(cachefile,"c")
        f->ts = ts
    end if


    wks = gsn_open_wks("ps",figfn)

    res = True
        res@gsnYRefLine = 0.
        res@gsnLeftString = title
        ;res@gsnRightString = "std.="+sprintf("%2.2f",tsdifstd)
    PLOTRES

    if(isvar("x"))then
        plot = gsn_csm_xy(wks,x,ts,res)
    else
        plot = gsn_csm_y(wks,ts,res)
    end if
    if(isatt(res,"gsnFrame").and. res@gsnFrame.eq.False)then
        frame(wks)
    end if
end
