
;;DIAG_NORCPM; CORFIGFILENAME: fig_cor
;;DIAG_NORCPM; RMSEFIGFILENAME: fig_rmse
;;DIAG_NORCPM; BEFOREPLOT: ;; BEFOREPLOT section, empty
;;DIAG_NORCPM; TITLE: Prediction Correlation
;;DIAG_NORCPM; TITLELEFT: 
;;DIAG_NORCPM; TITLERIGHT: 
;;DIAG_NORCPM; LEADMONTHS: 13
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
begin
    ;; xy plot, forecast time(x) and correlation/RMSE(y)
    ;; member 01(ind 0) is assumed as true solution
    ;; plot lines:
    ;;     presistent forecast
    ;;     members in every initTime
    ;; 
    
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

    cachefile = "CORFIGFILENAME.nc"
    if(isfilepresent(cachefile))then
        f = addfile(cachefile,"r")
        varall_rmse = f->varall_rmse
        varall_cor = f->varall_cor
        ppCor  = f->ppCor
        ppRmse = f->ppRmse
        wgt = f->wgt
        varall = f->varall


    else
        varcor = new(plotmonths,"float")
        varrmse = new(plotmonths,"float")
        varobs = read_obs_monthly(obsdir,obsdata,obsvar,(/1965,2000/))
        exit
        varens = read_noresm_forecasts_ens_leadmonths(forecastdirs,component,varname,ispan(0,12,1),ocngridfile) 
        printVarSummary(varens)
        do m = 0, plotmonths
            var1m = read_noresm_forecasts_members_leadmonths(forecastdirs,component,varname,m,ocngridfile) 
                ;; [forecast | 104] x [member | 9] x [time | 1] x [y | 384] x [x | 320]
            if(.not.isvar("wgt"))then
                ;; get weighting for area mean and desired region
                wgt = get_var_area_wgt_lat_lon_2d(var1m,"wgt")
                lat2d = get_var_area_wgt_lat_lon_2d(var1m,"lat")
                lon2d = get_var_area_wgt_lat_lon_2d(var1m,"lon")
                wgtmask = .not.ismissing(var1m)
                wgtmask = wgtmask .and. lat2d.ge.min(latbe) .and. lat2d.le.max(latbe)
                wgtmask = wgtmask .and. lon2d.ge.min(lonbe) .and. lon2d.le.max(lonbe)
                wgt = where(wgtmask,wgt,0)
                wgt = wgt/sum(wgt)  ; normalize area as weight
            end if
            var1m_mean = wgt_areaave2(var1m,wgt,0) ;; forecast,member,1 or forecast,member,1,lev
            ;; correlation with 1st member

            
        end do

        if(False)then ;; read all version, comsume too much memory
            varall = read_norcpm_forecasts_members_var(forecastdirs,component,varname,ocngridfile) 
                ;; forcast,member,time,y,x or forecast,member,time,lev,y,x
            dims = dimsizes(varall)
            ndim = dimsizes(dims)

            ;; wgt, desired region to cal
            if(component.eq."atm")then ;; coordinate is attached on variable
                lats = varall&lat
                lons = varall&lon
                wgt = conform_dim((/dimsizes(lats),dimsizes(lons)/),NormCosWgtGlobe(lats),0)
            end if
            if(component.eq."ocn")then ;; coordinate is stored in ocngridfile
                area2d = varall@area2d
                lat2d = varall@lat2d
                lon2d = varall@lon2d
                if(dimsizes(dimsizes(area2d)).eq.1)then
                    area2d := onedtond(area2d,dims(ndim-2:))
                    lon2d := onedtond(lon2d,dims(ndim-2:))
                    lat2d := onedtond(lat2d,dims(ndim-2:))
                end if
                wgt = area2d
            end if
            
            ;;; set wgt outside latbe,lonbe to zero
            if(component.eq."atm")then ;; 
                needwgt = wgt({min(latbe):max(latbe)},{min(lonbe):max(lonbe)})
                wgt = 0.
                wgt({min(latbe):max(latbe)},{min(lonbe):max(lonbe)}) = needwgt
                delete(needwgt)
            end if
            if(component.eq."ocn")then ;; 
                wgtmask = .not.ismissing(area2d)
                wgtmask = wgtmask .and. lat2d.ge.min(latbe) .and. lat2d.le.max(latbe)
                wgtmask = wgtmask .and. lon2d.ge.min(lonbe) .and. lon2d.le.max(lonbe)
                wgt = where(wgtmask,wgt,0)
            end if
            wgt = wgt/sum(wgt)  ; normalize area as weight

            ;;; mean value of region
            varall_mean = wgt_areaave2(varall,wgt,0) ;; forecast,member,time or forecast,member,time,lev

            ;; assume mem01(ind0) in each forecast is the true solution
            ;;; cal correlation, result dim should be time (,lev)
            ;;;; cor along the forecast time and members

            varall_cor = new(dims(2),"float") ;; assume it is time depend

            do t = 0,dims(2)-1
                x = varall_mean(:,1:,t)
                y = conform(x,varall_mean(:,0,t),0)
                varall_cor(t) = escorc(ndtooned(x),ndtooned(y))
                delete(x)
                delete(y)
            end do

            ;;; cal RMSE, result dim should be time (,lev)
            ;;;; cor along the forecast time and members

            varall_rmse = new(dims(2),"float") ;; assume it is time depend, ignore lev now

            do t = 0,dims(2)-1
                x = varall_mean(:,1:,t)
                y = conform(x,varall_mean(:,0,t),0)
                dif = ndtooned(x-y)
                varall_rmse(t) = avg(sqrt(dif*dif))
                delete(x)
                delete(y)
                delete(dif)
            end do


            ;; get persistent prediction skill correlation and RMSE
            ppCorRmse = persistent_prediction_skill_maskmean(varall(:,0,:,:,:),wgt)

            system("rm -f "+cachefile)
            f = addfile(cachefile,"c")
            f->varall_rmse = varall_rmse
            f->varall_cor = varall_cor
            f->ppCor  = ppCorRmse(0,:)
            f->ppRmse = ppCorRmse(1,:)
            f->wgt = wgt
            f->varall = varall
            ppCor = ppCorRmse(0,:)
            ppRmse = ppCorRmse(1,:)
        end if

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
        
        res@pmLegendDisplayMode = "Always"
        res@pmLegendSide = "Top"
        res@pmLegendWidthF = .15
        res@pmLegendHeightF = .10
        res@pmLegendParallelPosF = .8
        res@pmLegendOrthogonalPosF = -.3
        res@lgLabelFontHeightF  = .015
        res@xyExplicitLegendLabels = (/"  Dynamical forecast","  Persistent"/)
        res@lgPerimFill  = 0

    wks = gsn_open_wks("ps","CORFIGFILENAME")
    plot = gsn_csm_y(wks,(/varall_cor,ppCor/),res)
    print(wks)
    print(plot)
    print(res)
    draw(plot)
    ;drawNDCGrid(wks)

        delete(res@trYMaxF)
        delete(res@gsnYRefLine)
        res@pmLegendParallelPosF = .3
        res@tiYAxisString = "RMSE"
        res@tiMainString = "RMSETITLE"
    wks = gsn_open_wks("ps","RMSEFIGFILENAME")
    plot = gsn_csm_y(wks,(/varall_rmse,ppRmse/),res)
    draw(plot)
    ;printVarSummary(varall_cor)

end
