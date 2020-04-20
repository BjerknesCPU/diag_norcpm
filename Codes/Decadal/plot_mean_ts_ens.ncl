;;; plot variable time series in a regional mean
;;; with ensemble type
;;;
;;; following comments are for diag_norcpm read, do not delete it.
;;;     they indicate which data/variable needed here,
;;;     and default values in this script.

;DIAG_NORCPM; need_be_replace: INPUTFILES, VARIABLE, FIGFILENAME

;;; Following def will be all replaced with defalut value if not pre-set in recipe.
;DIAG_NORCPM; ADDRUNAVE: False
    ;; add red 13 months running average line
;DIAG_NORCPM; TITLE: title
;DIAG_NORCPM; FIGFILENAME: fig
;DIAG_NORCPM; CACHEFILENAME: FIGFILENAME
;DIAG_NORCPM; OBSTSPROCESS: 
;DIAG_NORCPM; FORECASTTSPROC: 
;DIAG_NORCPM; LATBE: 
;DIAG_NORCPM; LONBE: 
;DIAG_NORCPM; LEV: 0
;DIAG_NORCPM; MONTHS: 0
;DIAG_NORCPM; OCNGRIDFILE: ../../Data/grid.nc
    ;; mpiom grid data file
;DIAG_NORCPM; FIGFORMAT: ps
;DIAG_NORCPM; OBSDIR:
;DIAG_NORCPM; PLOTRES:
;DIAG_NORCPM; LINESRES:
;DIAG_NORCPM; READCACHEONLY: False
    ;; True: cache file will be prepared, do not read raw data here.

load "CODEDIR/func_read_all_members.ncl"
load "CODEDIR/func_read_framework.ncl" ;; prototype reading function for obs data
begin
    forecastdirs=systemfunc("ls -d FORECASTDIRS|sort")
    varname = "VARIABLE"
    ocngridfile = "OCNGRIDFILE"
    component = "COMPONENT"
    title = "TITLE"
    figfn = "FIGFILENAME"
    cacheprefix = "CACHEFILENAME"
    yearbe = (/YEARBE/)
    years = ispan(min(yearbe),max(yearbe),1)
    months = (/MONTHS/)
    if(any(months.eq.0))then
        months := ispan(1,12,1)
    end if
    latbe = (/LATBE/)
    lonbe = (/LONBE/)

    obsdir = "OBSDIR"
    obsdataset = "OBSDATASET"
    obsvn = "OBSVARNAME"

    readcacheonly = READCACHEONLY


    ;; read obs and plot background figure
    ;;;; read obs
    obscache = cacheprefix+"_obs.nc"
    if(isfilepresent(obscache))then
        f = addfile(obscache,"r")
        obsts = f->obsts
    else
        if(readcacheonly)then
            print("plot_mean_ts_ens.ncl: read cache only but missing obscache: "+obscache)
            exit
        end if
        obsts = read_obs_framework_season_ts(obsdir,obsdataset,obsvn,years,months,-1,latbe,lonbe)
            ;; time unit should be year
        OBSTSPROCESS
        f = addfile(obscache,"c")
        f->obsts = obsts
    end if

    ;;;; plotres
    res = True
        res@gsnLeftString = title
        res@vpHeightF = .3
        res@gsnRightString = "std.="+sprintf("%2.2f",stddev(obsts))
        res@gsnDraw = False
        res@gsnFrame = False
    PLOTRES

    ;;;; wks
    wks = gsn_open_wks("ps",figfn)

    ;;;; plot
    plot = gsn_csm_xy(wks,years,obsts,res)
    
    delete(res) ;; use for add lines later

    ;; read forecasts and add lines on figure
    ;;;; lines res
    res = True
        res@gsLineColor = "grey"
        res@tfPolyDrawOrder = "PreDraw"
    ensplot  = True ;;store ensemble lines
    ensres = True
        ensres@gsLineColor = "red"
        ensres@gsMarkerColor = "red"
        ensres@gsMarkerIndex = 16
        ensres@gsMarkerSizeF = .01

    LINESRES

    ;;;; read forecasts
    nfcast = dimsizes(forecastdirs)
    do i = 0, nfcast -1
        forecache = cacheprefix+"_f"+sprinti("%2.2d",i)+".nc"
        if(isfilepresent(forecache))then
            f = addfile(forecache,"r")
            ts = f->ts
        else
            if(readcacheonly)then
                print("plot_mean_ts_ens.ncl: read cache only but missing forecache: "+forecache)
                exit
            end if
            ts = read_norcpm_forecast_members_var_ts_season_latbe_lonbe_yearly(forecastdirs(i),component,varname,months,latbe,lonbe,ocngridfile) ;; yearly ts
            
            FORECASTTSPROC

            f = addfile(forecache,"c")
            f->ts = ts
        end if

        dims := dimsizes(ts)
        nline = dims(0)
        time := cd_calendar(ts&time,0)
        do l = 0, nline-1
            gsn_polyline(wks,plot,time(:,0),ts(l,:),res)
        end do
        tsens := dim_avg_n_Wrap(ts,0)
        ensplot@$unique_string("ensplot")$ =gsn_add_polyline(wks,plot,time(:,0),tsens,ensres)
        ensplot@$unique_string("ensplot")$ =gsn_add_polymarker(wks,plot,min(time(:,0)),tsens(0),ensres)
        delete(tsens)
        delete(ts)
    end do
    
    ;; draw and frame
    draw(plot)
    frame(wks)
end
