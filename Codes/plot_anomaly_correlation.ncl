;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; BEFOREPLOT: ;; BEFOREPLOT section, empty
;;DIAG_NORCPM; TITLE: Anomaly Correlation
;;DIAG_NORCPM; TITLELEFT: 
;;DIAG_NORCPM; TITLERIGHT: 
;;DIAG_NORCPM; SIGMETHOD: True
    ;; True: https://pro.arcgis.com/en/pro-app/tool-reference/spatial-statistics/what-is-a-z-score-what-is-a-p-value.htm
    ;; False: student t test
    
;;DIAG_NORCPM; SIGLEVEL: 99
;;DIAG_NORCPM; OBSPROXY: 1
    ;; use 1 member (>0) or obs(=0) as true solution
;;DIAG_NORCPM; OBSDIR: /cluster/projects/nn9039k/NorCPM/Obs
    ;; this OBSDIR is set for fram

load "CODEDIR/func_read_all_members.ncl"
load "CODEDIR/func_read_obs.ncl"
load "CODEDIR/func_read_framework.ncl" ;; prototype reading function for obs data
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
begin
    ;; Anomaly Correlation (AC)
    ;;  is a measure of the association between the 
    ;;      anomalies of (usually) gridpoint forecast and verification values.
    ;;
    ;;  Ref. Predictability and Forecast Skill in NMME
    ;;      Becker etal 2014, doi: 10.1175/JCLI-D-13-00597.1
    ;;      eq.3, but use initial forecast time as year
    ;;          and change bottom term to stddev(should be an error in paper?)
    ;;
    ;; create: 11Apr2019, pgchiu 

    ;; input from diag_norcpm
    dirs=systemfunc("ls -d FORECASTDIRS")
    vn="VARIABLE"
    component="COMPONENT"
    ocngridfile="OCNGRIDFILE"
    lead_season = LEADSEASON
    figfilename = "FIGFILENAME"
    siglevel = SIGLEVEL
    proxyObs = OBSPROXY -1  ;; < 0 means real obs, 0 is the first member
    obsdir = "OBSDIR"
    obsdataset = "OBSDATASET"
    obsvn = "OBSVN"

    ;; read variable in member dirs, output as (forecast,member,time,y,x)
    ;;      the time here is depend on lead_season and first simulation month
    ;;      ie. simulation start from 1989-01, and lead_season is 1
    ;;          then read time is 1989-02,1989-03,1989-04
    ;;      if lead_season is 2
    ;;          then read time is 1989-05,1989-06,1989-07

    cache = figfilename+".nc"
    if(isfilepresent(cache))then
        f = addfile(cache,"r")
        AChom2 = f->AChom2 
        p = f->p
    else
        var = read_noresm_forecasts_members_leadseason(dirs,component,vn,lead_season,ocngridfile)
        dims = dimsizes(var)
        ndim = dimsizes(dims)
        if(ndim.gt.5)then
            printVarSummary(var)
            print("variable over 5 dims is not support yet.")
            print("assume data is (forecast,member,dmonth,y,x)")
            print("exit...")
            exit
        end if

        ;; some meta data
        readMM = var@readMM
        monNames = (/"0","J","F","M","A","M","J","J","A","S","O","N","D"/)
        readMonName = str_concat(monNames(readMM))

        ;; homogeneous predictability (proxyObs is 0 or postive)
        ;; heterogeneous predictability (proxyObs is negative)
        ;;     use forecast index as year (j)
        ;;;; set first member is proxy observation at all forecast
        ;;;; ensemble members are other than proxyObs
        if(proxyObs .ge.0)then
            modelEns = 0
            do i = 0, dims(1)-1
                if(i.ne.proxyObs)then
                    modelEns := array_append_record(modelEns,i,0)
                end if
            end do
            modelEns := modelEns(1:)
        else
            modelEns = ispan(0,dims(1)-1,1) 
        end if

        nEns = dimsizes(modelEns)
        nforecast = dims(0)

        ;; seasonal var (forecast,member,months,y,x)->(forecast,member,y,x)
        varSea = dim_avg_n_Wrap(var,2)
        dimsSea = dimsizes(varSea)

        ;;;; get climate (average along forecast index)(member,y,x)
        ;;;;;; TBD: need to revise
        varSeaClm = dim_avg_n_Wrap(varSea,0) ;; only with seasonal 

        ;;;; get anomaly (substract varClm)(forecast,member,y,x)
        varSeaAno = varSea ;; create array with coordinate
        varSeaAno = varSea - conform_dims(dimsSea,varSeaClm,(/1,2,3/))

        ;;;; get ensemble anomaly
        varSeaEnsAno = dim_avg_n_Wrap(varSeaAno,1)

        ;;;; AChom at each grid, along forecast(as year)
        if (False)then ;; manual calculate, obsoleted
            ;;AChom = varSeaAno(0,modelEns,:,:)  ;; create array with no attrs.
            AChom = varSeaAno(0,0,:,:)  ;; create array 
            AChom@long_name = "Anomaly correlation"
            AChom@units = ""
            delete(AChom@valid_range)
            delete(AChom@actual_range)
            
            lower_righ = dim_stddev_n(varSeaAno(:,proxyObs,:,:),0)

            upper_term = dim_avg_n(varSeaEnsAno(:,:,:) * varSeaAno(:,proxyObs,:,:),0)
            lower_left = dim_stddev_n(varSeaEnsAno(:,:,:),0)
            lower_term = lower_left * lower_righ
            lower_term = where(lower_term.eq.0,lower_term@_FillValue,lower_term)
            AChom(:,:) = upper_term / lower_term

            AChom = AChom*100
        end if

        ;; use escorc_n to cal linear cross-correlation
        if(proxyObs.ge.0)then
            AChom2 = varSeaAno(0,0,:,:)  ;; create array, AChom only when proxyObs.ge.0
            if(isatt(AChom2,"actual_range"))then
                delete(AChom2@actual_range)
                delete(AChom2@valid_range)
            end if
            AChom2 = 0
            AChom2 = escorc_n(varSeaAno(:,proxyObs,:,:), varSeaEnsAno,0,0)
        else
            AChet = varSeaAno(0,0,:,:)  ;; create array, use real obs data
            AChet = 0.
            obsvarSea = varSeaAno(:,0,:,:)*0 ;;  create array

            inittimes = cd_calendar(varSeaAno&forecast,-1)
            leadmonths = (/1,2,3/)+((lead_season-1)*3)
            nt = dimsizes(inittimes)
            opt = True ;; for esmf regrid
                opt@DstGridLat = get_latlon2d(varSeaAno,"lat2d")
                opt@DstGridLon = get_latlon2d(varSeaAno,"lon2d")
                opt@DstGridMask = where(ismissing(varSeaAno(0,0,:,:)),0,1)
                ;opt@ForceOverwrite = True
                ;opt@Overwrite = True
            do t = 0, nt-1
                ;; multi-year 1season
                if(vn.eq."sst")then
                    var1 = dim_avg_n_Wrap(read_obs_leadmonths(obsdir,obsdataset,obsvn,inittimes(t)/100,mod(inittimes(t),100),leadmonths),0)
                else
                    var1 = dim_avg_n_Wrap(read_obs_framework_leadmonths(obsdir,obsdataset,obsvn,inittimes(t)/100,mod(inittimes(t),100),leadmonths,0,(/-90.,90/),(/0.,360./)),0) ;; 
                end if

                    opt@SrcGridMask = where(ismissing(var1),0,1)
                ;; regrid to model grid
                system("rm -f source_grid_file.nc destination_grid_file.nc weights_file.nc")
                var1g =  ESMF_regrid(var1,opt)
                obsvarSea(t,:,:) = var1g
                delete(var1)
                delete(var1g)
            end do
                    
            obsvarSeaClm = dim_avg_n_Wrap(obsvarSea,0)
            obsvarSeaAno = obsvarSea ;; create array with coordinate
            obsvarSeaAno = obsvarSea - conform(obsvarSeaAno,obsvarSeaClm,(/1,2/))
            AChet = escorc_n(obsvarSeaAno, varSeaEnsAno,0,0)
            AChom2 = AChet ;; well.....
        end if

        ;; confidence intervals, see:
        ;; https://www.ncl.ucar.edu/Document/Functions/Built-in/escorc.shtml
        if (SIGMETHOD) then
            df = nforecast -2
            ;;;; Fisher z-transformation
            z = 0.5*log((1+AChom2)/(1-AChom2))
            se= 1.0/sqrt(nforecast-3) ;; standard error of z-statisic
            ;;;;;; z-score
            ;;;;;; https://pro.arcgis.com/en/pro-app/tool-reference/spatial-statistics/what-is-a-z-score-what-is-a-p-value.htm
            if(siglevel .eq. 99)then
                zlow = z- 2.58*se   ;; 1.96 for 95%, 2.58 for 99%
                zhi  = z+ 2.58*se   ;; 1.96 for 95%, 2.58 for 99%
            else
                siglevel = 95 ;; others are not supported
                zlow = z- 1.96*se   ;; 1.96 for 95%, 2.58 for 99%
                zhi  = z+ 1.96*se   ;; 1.96 for 95%, 2.58 for 99%
            end if
            rlow = (exp(2*zlow)-1)/(exp(2*zlow)+1)
            rhi  = (exp(2*zhi)-1)/(exp(2*zhi)+1)
            ;;;; if 0 contain between rlow and rhi, then not significant
            p = where(rlow*rhi.ge.0,0.005,1.)  ;; for contour interval
        else
            ;;;; this is significant level, not confidence intervals
            ;;;; student t test
            t    = AChom2*sqrt((nforecast-2)/(1-AChom2^2))
            p    = student_t(t,nforecast-2)
                ;; if p < 0.01 => is significant at 99% level
        end if
        if(False)then ;; debug
            system("rm -f ptmp.nc")
            f = addfile("ptmp.nc","c")
            f->p = p
            f->AChom2 = AChom2
            f->obsvarSeaClm  = obsvarSeaClm 
            f->obsvarSea  = obsvarSea
        end if

        AChom2 = AChom2*100
        AChom2@readMMName = readMonName 

        f = addfile(cache,"c")
        f->AChom2 = AChom2
        f->p = p

    end if
    ;; define color table with paper figure 8
    ;; rgb
    color_map =(/(/255,255,255/), \
                (/  0,  0,  0/), \
                (/255,255,255/), \
                (/255,250,169/), \
                (/255,231,120/), \
                (/200,255,190/), \
                (/150,245,141/), \
                (/ 80,240, 80/), \
                (/220,220,254/) , \
                (/160,140,255/), \
                (/112, 96,220/), \
                (/ 61, 40,181/) /)

    cmap = tofloat(color_map)/255.



    ;; plot AChom figure  
    res = True
        res@cnFillOn    = True
        res@cnLinesOn   = False
        res@cnLevelSelectionMode = "ExplicitLevels"
        res@cnLevels = fspan(10,90,9)
        res@tiMainString  = "TITLE"
        if("TITLELEFT" .eq. "")then
            res@gsnLeftString = AChom2@readMMName
        else
            res@gsnLeftString = "TITLELEFT"
        end if
        if("TITLERIGHT" .eq. "")then
            res@gsnRightString = "Confidence="+siglevel+"%, Lead Season="+lead_season
        else
            res@gsnRightString = "TITLERIGHT"
        end if

        res@mpLimitMode = "LatLon"
        res@mpMinLonF = -330.
        res@mpMaxLonF =   30.
        res@mpCenterLonF =   -150.


        ;; for add dot shading
        res@gsnDraw = False
        res@gsnFrame = False

    pres  = True
        pres@gsnDraw = False
        pres@gsnFrame = False
        pres@cnFillOn = True
        pres@cnMonoFillPattern = True
        pres@cnMonoFillColor = False
        pres@cnFillPattern = 17
        ;pres@cnFillScaleF = 0.6 ;; more dots
        pres@cnLinesOn = False
        pres@cnLevelSelectionMode = "ExplicitLevels"
        pres@cnFillColors = (/1,-1/)  ;; fill dots below 0.01
        pres@cnLevels = (/0.01/)      ;; 99% confidence level
        pres@lbLabelBarOn  = False ;; turn off label bar
        pres@cnLineLabelsOn = False
        pres@cnInfoLabelOn = False

    if(isatt(AChom2,"lat2d"))then ;; convert coords to 2d, which was reshaped to 1d in netcdf file
        lat2d := AChom2@lat2d
        lon2d := AChom2@lon2d
        if(dimsizes(dimsizes(lat2d)).eq.1)then
            lat2d := onedtond(AChom2@lat2d,dimsizes(AChom2(:,:)))
            lon2d := onedtond(AChom2@lon2d,dimsizes(AChom2(:,:)))
        end if
        AChom2@lat2d := lat2d
        AChom2@lon2d := lon2d
        p@lat2d := lat2d
        p@lon2d := lon2d
    else
        copy_VarCoords(AChom2,p)
    end if


    BEFOREPLOT


    wks = gsn_open_wks("ps",figfilename)
    gsn_define_colormap(wks,cmap)
    plot = gsn_csm_contour_map(wks,AChom2,res)
    pplot = gsn_csm_contour(wks,p,pres)
    if(False)then ;; debug
        draw(plot)
        frame(wks)
        draw(pplot)
        frame(wks)
    end if
    overlay(plot,pplot)
    draw(plot)
    frame(wks)
end

