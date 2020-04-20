;;; plot variable time series in a regional mean
;;; with ensemble type
;;;
;;; following comments are for diag_norcpm read, do not delete it.
;;;     they indicate which data/variable needed here,
;;;     and default values in this script.

;DIAG_NORCPM; need_be_replace: INPUTFILES, VARIABLE, FIGFILENAME

;;; Following def will be all replaced with defalut value if not pre-set in recipe.
;DIAG_NORCPM; BEFORE_PLOT:
;DIAG_NORCPM; ADDRUNAVE: False
    ;; add red 13 months running average line
;DIAG_NORCPM; TITLE:
;DIAG_NORCPM; RIGHTTITLE:
;DIAG_NORCPM; LEFTTITLE:
;DIAG_NORCPM; LAT: :
;DIAG_NORCPM; LON: :
;DIAG_NORCPM; LEV: 1000
;DIAG_NORCPM; OCNGRIDFILE: ../../Data/grid.nc
    ;; mpiom grid data file
;DIAG_NORCPM; ALLOW_MISSING: 0
    ;; 0: avg only non-missings, 1: missing if any missing; use in wgt_areaave_Wrap()
;DIAG_NORCPM; ENSPLOT: stddev
    ;; use stddev or line to plot ensemble members
;DIAG_NORCPM; FIGFORMAT: ps
;DIAG_NORCPM; OBSDIR:

load "FUNCTIONDIR/func_read_sst_fram.ncl"
begin
    inputfiles = "INPUTFILES"
    varname = "VARIABLE"
    ocngridfile = "OCNGRIDFILE"
    component = "COMPONENT"
    title = "TITLE"
    rightTitle = "RIGHTTITLE"
    leftTitle = "LEFTTITLE"
    obsdir = "OBSDIR"
    ensplot = "ENSPLOT"

    cache = varname+"_LAT_LON_members_.nc"
    if(isfilepresent(cache))then
        f = addfile(cache,"r")
        varts = f->varts
        time = f->time
        nmember = f->nmember
        dataUnits = f->varts@units
    else
        if(any(.not.ismissing(str_match(inputfiles,"*"))))then
            inputfiles := systemfunc("ls "+inputfiles)
        else
            inputfiles := str_split(inputfiles,",")
        end if

        ;; rad constant
        rad =  4.0*atan(1.0)/180.0
        allow_missing = ALLOW_MISSING    ;; must be 0 for ocn plot

        ;; get number of members
        nmember = dimsizes(inputfiles)

        ;; reading first to time series 
        f = addfile(inputfiles(0),"r")
        dims = getfilevardimsizes(f,varname)
        ndim = dimsizes(dims)

        nt = dims(0)
        ;;;; last memeber is for mean value
        varts = new((/nmember+1,nt/),"float")
        varts!0 = "members"
        varts&members = ispan(1,nmember+1,1)
        dataUnits = f->$varname$@units

        do i = 0, nmember-1
            f = addfile(inputfiles(i),"r")
            if(component.eq."atm")then
                if(ndim .eq. 4)then ;; assume (time,lev,lat,lon)
                    var1 = f->$varname$(:,{LEV},{LAT},{LON})
                end if
                if(ndim .eq. 3)then ;; assume (time,lat,lon)
                    var1 = f->$varname$(:,{LAT},{LON})
                end if
            end if
            if(component.eq."ocn")then
                ;; get area and needmask 
                if(.not.isvar("area"))then
                    if(.not.isfilepresent(ocngridfile))then
                        print("plot_mean_ts_ens.ncl: OCN plots need grid file.")
                        exit
                    end if
                    gf = addfile(ocngridfile,"r")
                    coords = f->$varname$@coordinates

                    if(coords .eq. "plon plat")then ;; p cell
                        lon = gf->plon
                        lat = gf->plat
                        area= gf->parea
                    end if
                    if(coords .eq. "ulon ulat")then ;; u cell
                        lon = gf->ulon
                        lat = gf->ulat
                        area= gf->uarea
                    end if
                    if(coords .eq. "vlon vlat")then ;; v cell
                        lon = gf->vlon
                        lat = gf->vlat
                        area= gf->varea
                    end if
                    if(coords .eq. "qlon qlat")then ;; q cell
                        lon = gf->qlon
                        lat = gf->qlat
                        area= gf->qarea
                    end if
                    if(.not.isvar("area"))then ;; not all above
                        print("plot_mean_ts_ens.ncl: cannot find coordinate: "+coords)
                        exit
                    end if
                    needlatS = "LAT" ;; string, maybe ":" or "latb:late"
                    needlonS = "LON"
                    if(needlatS.eq.":")then
                        needlatS = "-90:90"
                    end if
                    if(needlonS.eq.":")then
                        needlonS = "0:360"
                    end if
                    latbe = tofloat(str_split(needlatS,":"))
                    lonbe = tofloat(str_split(needlonS,":"))
                    ;;TBD, minus lon
                    if(any(lonbe.lt.0))then
                        lon = where(lon.gt.180,lon-360.,lon)
                    end if
                    needmask = .not.ismissing(area)
                    needmask = needmask .and. (lat.ge.min(latbe).and.lat.le.max(latbe))
                    needmask = needmask .and. (lon.ge.min(lonbe).and.lon.le.max(lonbe))
                    area = where(needmask,area,0)
                    delete(lat)
                    delete(lon)
                    delete(latbe)
                    delete(lonbe)
                end if
                ;; read var1 with all data. area=0 where the data do not needed
                var1 = f->$varname$
                time = f->time
            end if
            delete(f)

            if(typeof(var1).eq."short")then
                var1f = short2flt(var1) ;; for scale and offset
            else
                var1f = tofloat(var1) 
            end if
            delete(var1)

            ;; avg to time series
            dims1 = dimsizes(var1f)
            ndim1 = dimsizes(dims1)
            if(component.eq."atm")then
                if(ndim1 .eq. 4)then ;; assume (time,lev,lat,lon)
                    varts(i,:) = dim_avg_n_Wrap(wgt_areaave_Wrap(var1f,clat,1.0,allow_missing),1)
                end if
                if(ndim1 .eq. 3)then ;; assume (time,lat,lon)
                    ;; need check right most 2 dim name, TBD
                    varts(i,:) = wgt_areaave_Wrap(var1f,clat,1.0,allow_missing)
                end if
            end if
            if(component.eq."ocn")then
                if(ndim1 .eq. 4)then ;; assume (time,lev,lat,lon)
                    varts(i,:) = dim_avg_n_Wrap(wgt_areaave2(var1f,area,allow_missing),1)
                end if
                if(ndim1 .eq. 3)then ;; assume (time,lat,lon)
                    varts(i,:) = wgt_areaave2(var1f,area,allow_missing)
                end if
            end if
            delete(var1f)
        end do  ;; i
        if(component.eq."ocn")then
            varts!1 = "time"
            varts&time = time
            varts@units = dataUnits
        end if
        
        ;; write cache
        f = addfile(cache,"c")
        f->varts = varts
        f->time = time
        f->nmember = nmember
    end if ;; isfilepresent()
    
    ;; make ensemble mean at nmember
    varts(nmember,:) = dim_avg_n(varts(:nmember-1,:),0)
    if(component.eq."ocn")then ;; 
        varts!1 = "time"
        varts&time = time
    else 
        time = varts&$varts!1$
    end if

    datea = cd_calendar(time,0)
    
    ilabelpos = ind(datea(:,1).eq.6 .and. mod(datea(:,0),10).eq.0)
    res = True
        res@gsnYRefLine = 0.0
        res@gsnFrame = False
        res@gsnDraw = False
        res@vpHeightF = 0.3
        res@vpWidthF = 0.7
        res@xyLineColor = "black"
        res@tmXBMode = "Explicit"
        if(.not.ismissing(ilabelpos))then
            res@tmXBValues = time(ilabelpos)
            res@tmXBLabels = ""+datea(ilabelpos,0)
        else
            res@tmXBValues = time
            res@tmXBLabels = ""+datea(:,1)
        end if
        res@gsnStringFont =  21
        res@tiMainFont = 21
        if(title.eq."")then
            res@tiMainString = "ens "+varname+" time series "
        else
            res@tiMainString = title
        end if
        if(rightTitle.eq."")then
            res@gsnRightString = dataUnits
        end if
        if(leftTitle.eq."")then
            res@gsnLeftString = "lat LAT , lon LON"
        end if

    resLine = True
        resLine@gsLineColor = "gray" ;; ensplot = "Line"
        resLine@gsFillColor = "gray" ;; ensplot = "stddev"
        resLine@gsFillOpacityF = .5

    resrunave = True
        resrunave@gsLineColor = "black"
        resrunave@gsLineThicknessF = 5.0
 
    resObsLine = True
        resObsLine@gsLineColor = "green"
    resObsLineRunave = True
        resObsLineRunave@gsLineColor = "darkgreen"
        resObsLineRunave@gsLineThicknessF = 5.0

  
    BEFORE_PLOT


    wks = gsn_open_wks("FIGFORMAT","FIGFILENAME")
    plot = gsn_csm_xy(wks,time,varts(nmember,:),res)

    if(ensplot.eq."Line")then
        do i = 0,nmember -1
            newstr="forpool"+i
            gsn_polyline(wks,plot,time,varts(i,:),resLine)
        end do
    end if
    if(ensplot.eq."stddev")then
        ts_stddev = dim_stddev_n_Wrap(varts(0:nmember-1,:),0)
        upB = varts(nmember,:) + ts_stddev
        loB = varts(nmember,:) - ts_stddev
        YBound = array_append_record(upB,loB(::-1),0)
        XBound = array_append_record(time,time(::-1),0)
        gsn_polygon(wks,plot,XBound,YBound,resLine)
    end if
 
    draw(plot)

    ;; if obsdir, add green HadISST, directory for fram
    if(obsdir.ne."")then
        yb = toint(min(datea(:,0)))
        ye = toint(max(datea(:,0)))
        obsvar = read_obs_sst_fram_monthly(obsdir+"/SST/HADISST","sst",(/yb,ye/))

        ;;;; quick way to average
        rad = 4*atan(1.0)/180.
        if(dimsizes(dimsizes(obsvar)).eq. 3)then ;; assume (time,lat,lon)
            obslat = obsvar&$obsvar!1$
            obslat&$obslat!0$ = obslat
            obslat := obslat({LAT})
            obsts = wgt_areaave_Wrap(obsvar(:,{LAT},{LON}),cos(obslat*rad),1.0,1)
        end if
        obstime = cd_convert(obsts&time,time@units)
        gsn_polyline(wks,plot,obstime,obsts,resObsLine)
        if(ADDRUNAVE)then
            gsn_polyline(wks,plot,obstime,runave_Wrap(obsts,13,0),resObsLineRunave)
        end if
    end if
 
    ;; 13 months running average
    if(ADDRUNAVE)then
        rave13 = runave_Wrap(varts(nmember,:),13,0)
        gsn_polyline(wks,plot,time,rave13,resrunave)
    end if


   frame(wks)

    ;; if obsts, plot difference between obs and ens mean. directory for fram
    if(False .and. isvar("obsts"))then
        res@tiMainString = "dif"+res@tiMainString
        dif = varts(:,:)
        do i = 0,nmember
            dif(i,:) = varts(i,:) - obsts
        end do
        wksdif = gsn_open_wks("FIGFORMAT","FIGFILENAME"+"_dif")
        pdif = gsn_csm_xy(wksdif,time,dif(nmember,:),res)
 
        if(ensplot.eq."Line")then
            do i = 0,nmember-1
                gsn_polyline(wksdif,pdif,time,dif(i,:),resLine)
            end do
        end if
        if(ensplot.eq."stddev")then
            upB := dif(nmember,:) +ts_stddev
            loB := dif(nmember,:) -ts_stddev
            YBound := array_append_record(upB,loB(::-1),0)
            XBound := array_append_record(time,time(::-1),0)
            gsn_polygon(wksdif,pdif,XBound,YBound,resLine)
        end if
        draw(pdif)
        frame(wksdif)
    end if
end
