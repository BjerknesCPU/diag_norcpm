
;;DIAG_NORCPM; CORFIGFILENAME: fig_cor
;;DIAG_NORCPM; RMSEFIGFILENAME: fig_rmse
;;DIAG_NORCPM; BEFOREPLOT: ;; BEFOREPLOT section, empty
;;DIAG_NORCPM; TITLE: Prediction Correlation
;;DIAG_NORCPM; TITLELEFT: 
;;DIAG_NORCPM; TITLERIGHT: 
;;DIAG_NORCPM; LEADMONTHS: 12
;;DIAG_NORCPM; READSAMEMONTH: True
    ;; check if read are same month(Jan ... etc)
;;DIAG_NORCPM; OBSDATASET: SST/HADISST
;;DIAG_NORCPM; OBSVARIABLE: sst

;;DIAG_NORCPM; MINLAT: -5
;;DIAG_NORCPM; MAXLAT:  5
;;DIAG_NORCPM; MINLON: -150
;;DIAG_NORCPM; MAXLON:  -90

load "CODEDIR/func_read_all_members.ncl"
load "CODEDIR/func_read_obs.ncl"
load "CODEDIR/func_persistence_prediction_skill.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
begin
    ;; xy plot, forecast time(x) and correlation/RMSE(y)
    ;; member 01(ind 0) is assumed as true solution
    ;; plot lines:
    ;;     presistent forecast
    ;;     members in every initTime
    ;; 
    print("plot_forecast_correlation.ncl: observation data reading is not apply yet")
    print("plot_forecast_correlation.ncl: do not run this until fix")
    ;exit
    ocngridfile  ="OCNGRIDFILE"
    forecastdirs = systemfunc("ls -d FORECASTDIRS")
    forecastdirs@check_month = READSAMEMONTH
    varname = "VARIABLE"
    component = "COMPONENT"
    latbe = (/MINLAT,MAXLAT/)
    lonbe = (/MINLON,MAXLON/)
    plotmonths = LEADMONTHS  ;; for x axis
    obsdir = "OBSDIR"
    obsdata = "OBSDATASET"
    obsvar = "OBSVARIABLE"

    nmember = 9+1 ;; bad idea, try other way. 0 is for ensemble mean

    cachefile = "CORFIGFILENAME.nc"
    if(isfilepresent(cachefile))then
        f = addfile(cachefile,"r")
        varcor = f->varcor
        varrmse = f->varrmse
        ppcor  = f->ppcor
        pprmse = f->pprmse
        wgt = f->wgt
        obswgt = f->obswgt

    else
        varcor = new(plotmonths+1,"float")
        varrmse = new(plotmonths+1,"float")
        ppcor = new(plotmonths+1,"float")
        pprmse = new(plotmonths+1,"float")
        do m = 0, plotmonths  ;; for each lead month
            var1m = read_noresm_forecasts_ens_leadmonths(forecastdirs,component,varname,m,ocngridfile) 
                ;; [forecast | 104] x [time | 1] x [y | 384] x [x | 320]
            if(.not.isvar("wgt"))then ;; run only once
                ;; get weighting for area mean and desired region
                wgt = get_var_area_wgt_lat_lon_2d(var1m,"wgt")
                lat2d = get_var_area_wgt_lat_lon_2d(var1m,"lat")
                lon2d = get_var_area_wgt_lat_lon_2d(var1m,"lon")
                wgtmask = .not.ismissing(var1m(0,0,:,:))
                wgtmask = wgtmask .and. lat2d.ge.min(latbe) .and. lat2d.le.max(latbe)
                wgtmask = wgtmask .and. lon2d.ge.min(lonbe) .and. lon2d.le.max(lonbe)
                wgt = where(wgtmask,wgt,0)
                wgt = wgt/sum(wgt)  ; normalize area as weight
                delete(wgtmask)

            end if

            var1m_mean = wgt_areaave2(var1m,wgt,0) ;; forecast,1 

            ;; read obs data and get mean
            inittime = cd_calendar(var1m&forecast,-1)
            varobsny1m = read_obs_months(obsdir,obsdata,obsvar,inittime/100,mod(inittime,100)+m) ;; t,y,x
            if(.not.isvar("obswgt"))then ;; run only once
                obswgt = get_var_area_wgt_lat_lon_2d(varobsny1m,"wgt")
                obslat2d = get_var_area_wgt_lat_lon_2d(varobsny1m,"lat")
                obslon2d = get_var_area_wgt_lat_lon_2d(varobsny1m,"lon")
                if(min(obslon2d).ge.0)then
                    obslon2d = obslon2d - 360.
                end if
                wgtmask = .not.ismissing(varobsny1m(0,:,:))
                wgtmask = wgtmask .and. obslat2d.ge.min(latbe) .and. obslat2d.le.max(latbe)
                wgtmask = wgtmask .and. obslon2d.ge.min(lonbe) .and. obslon2d.le.max(lonbe)
                obswgt = where(wgtmask,obswgt,0)
                obswgt = obswgt/sum(obswgt)
            end if

            ;; obsdata regional mean
            obs1 = wgt_areaave2(varobsny1m,obswgt,0) ;; t

            if(m.eq.0)then ;; save lead month 0 for persistence forecast
                obs0 = obs1
            end if

            ;; regrid obs data to model grid 
            varcor(m) = escorc_n(obs1,var1m_mean,0,0) ;; ensemble mean correlation
            varrmse(m) =sqrt(avg((var1m_mean(:,0)-obs1)^2))

            ;; persistence forecast
            ppcor(m) = escorc(obs1,obs0)
            pprmse(m) = sqrt(avg((obs1-obs0)^2))

            delete(var1m)
            delete(var1m_mean)
            delete(varobsny1m)
            delete(obs1)
        end do

        ;; save cache file
        f = addfile(cachefile,"c")
        f->varcor = varcor
        f->varrmse = varrmse 
        f->ppcor = ppcor
        f->pprmse = pprmse
        f->wgt = wgt
        f->obswgt = obswgt
    end if

    res = True
        res@gsnDraw                = False
        res@gsnFrame               = False
        res@trYMaxF = 1.0
        res@gsnYRefLine = 0
        res@gsnYRefLineColor = "gray"
        ;res@gsnXRefLine = fspan(0.,12.,13)
        ;res@gsnXRefLineColor = "gray"
        res@tmXBMinorOn = False
        res@tmXTMinorOn = False
        res@xyCurveDrawOrder = "PostDraw"
        res@xyLineThicknessF = 2.0

        res@tiXAxisString = "lead time (month)"
        res@tiYAxisString = "r"
        res@tiMainString = "CORTITLE"
        
        res@xyLineColors = (/"black","red"/)
        res@xyDashPattern = 0
    nitems = 2
    legend_labels = (/"  Ens. mean","  Persistance"/)
    lgres = True
        lgres@lgLineColors = (/"black","red"/)
        lgres@lgLineThicknessF = res@xyLineThicknessF
        lgres@lgItemType = "Lines"
        lgres@vpWidthF =  0.20
        lgres@vpHeightF =  0.1
        lgres@lgLineLabelsOn  = False
        lgres@lgLabelFontHeightF = 0.20
        lgres@lgPerimOn = False
        lgres@lgMonoDashIndex = True
    amres = True
        amres@amParallelPosF = -0.3
        amres@amOrthogonalPosF =  0.3

    pp = (/varcor,ppcor/)

    wks = gsn_open_wks("ps","CORFIGFILENAME")
    plot = gsn_csm_y(wks,pp,res)
    lbid = gsn_create_legend(wks,nitems,legend_labels,lgres) ;; make legend
    a = gsn_add_annotation(plot,lbid,amres)

    draw(plot)
    ;drawNDCGrid(wks)

        delete(res@trYMaxF)
        delete(res@gsnYRefLine)
        res@pmLegendParallelPosF = .3
        res@tiYAxisString = "RMSE"
        res@tiMainString = "RMSETITLE"

    pp = (/varrmse,pprmse/)

    wks = gsn_open_wks("ps","RMSEFIGFILENAME")
    plot = gsn_csm_y(wks,pp,res)
    draw(plot)
    ;printVarSummary(varall_cor)

end
