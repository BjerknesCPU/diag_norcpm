
;; plot variable lon-day contour


;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; CACHEFILENAME: FIGFILENAME
;;DIAG_NORCPM; WRITEFIGFILELIST: write_table("figfilelist.txt","a",[/"FIGFILENAME"/],"%s") ;; for mk_html_page.sh
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; POSTPLOT: ;; POSTPLOT
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; YYYYMMS: 120101,120102,120103,120104,120105
;;DIAG_NORCPM; LATBE: 40,45
;;DIAG_NORCPM; LONBE: 0,360

load "CODEDIR/mpiexm/func_read_mpiexm.ncl"

begin
    figfn = "FIGFILENAME"
    WRITEFIGFILELIST
    cachefile = "CACHEFILENAME.nc"
    title = "TITLE"
    varname = "VARIABLE"
    component = "COMPONENT"

    case = "CASE"
    casedir = "CASEDIR"

    modeln = MODELN  ;; if use echam6

    yyyymms = (/YYYYMMS/) ;; shoud be yyyymm
    latbe = (/LATBE/)  ;;  which profile
    lonbe = (/LONBE/)  ;;  x-axis range

    UseCache = True  ;; small data, no need cache
    if(UseCache.and.isfilepresent(cachefile))then 
        f = addfile(cachefile,"r")
        varDL = f->varDL
        if(isatt(varDL,"lat2d"))then
            dims = dimsizes(varDL)
            ndim = dimsizes(dims) ;; should be 3, time,lat,lon
            varDL@lat2d := onedtond(varDL@lat2d,dims(ndim-2:))
            varDL@lon2d := onedtond(varDL@lon2d,dims(ndim-2:))
            delete(dims)
            delete(ndim)
        end if
    else
        varDZLL = read_mpiexm_var_daily_months(case,casedir,component,varname,yyyymms,modeln) ;; day,lev,lat,lon
        if(dimsizes(dimsizes(varDZLL)).eq.4)then
            varDLL = varDZLL(:,0,:,:)
        else
            varDLL = varDZLL
        end if
        delete(varDZLL)

        varDL = varDLL(:,{min(latbe):max(latbe)},:)
        dims = dimsizes(varDL) 
        ndim = dimsizes(dims)
        nt = dims(0)
        if (ndim .eq. 3)then
            varDL := dim_avg_n_Wrap(varDL,1)
            dims := dimsizes(varDL) 
            ndim := dimsizes(dims)
        end if

        if(UseCache)then
            f = addfile(cachefile,"c")
            f->varDL = varDL
        end if
    end if

    if (component.eq."mpiom")then
        print("lat2d/lon2d is not supported yet.")
        print("beacuse hard to determin the lon grids, maybe regrid?")
        exit
    end if

    res = True
        res@tiMainString = title
        res@gsnDraw = False
        res@gsnFrame = False
        res@cnFillOn = True
        res@cnLinesOn = False
        res@cnLineLabelsOn = False
        res@cnFillMode = "CellFill"
        res@cnInfoLabelOn     = False   
        res@lbOrientation = "vertical"
    
        ;; mark first day of months
        res@tmYLMode = "Explicit"
        monthAbbr = (/"","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"/)
        timearr = cd_calendar(varDL&time,0)
        tind = ind(timearr(:,2).eq.1)
        tmYLValues = varDL&time(tind)
        tmYLLabels = monthAbbr(toint(timearr(tind,1)))+"01"
        res@tmYLValues = tmYLValues
        res@tmYLLabels = tmYLLabels
        res@tmYLLabelFontHeightF = .015

        ;; mark longtitude
        if(False)then
        res@tmXBMode = "Explicit"
        lon = varDL&$varDL!1$
        tmXBValues = lon(::24)
        tmXBLabels = tmXBValues
        ;; from 0-360 to 0..90E..180..90W..
        tmXBLabels := where(tmXBLabels.lt.180, toint(tmXBLabels)+"E", (360-toint(tmXBLabels))+"W")   
        tmXBLabels := where(tmXBLabels.eq."0E", "0", tmXBLabels)
        tmXBLabels := where(tmXBLabels.eq."180W", "180", tmXBLabels)

        res@tmXBValues = tmXBValues
        res@tmXBLabels = tmXBLabels
        res@tmXBLabelFontHeightF = .015
        end if


    PLOTRES

    wks = gsn_open_wks("ps",figfn)

    plot = gsn_csm_contour(wks,varDL,res)


    if(isatt(res,"gsnDraw").and.(.not.res@gsnDraw))then
        draw(plot)
    end if
    if(isatt(res,"gsnFrame").and.(.not.res@gsnFrame))then
        frame(wks)
    end if
end

