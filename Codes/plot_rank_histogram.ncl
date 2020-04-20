
;; Rank Histogram (Talagrand Diagram)
;; see https://www.atmos.umd.edu/~ekalnay/syllabi/AOSC630/ensemble101_2014.pdf

;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES section, empty
;;DIAG_NORCPM; TITLE: Rank Histogram
;;DIAG_NORCPM; TITLELEFT: 
;;DIAG_NORCPM; TITLERIGHT: 
;;DIAG_NORCPM; DEBUG: False
;;DIAG_NORCPM; REMOVECACHE: False
    ;; read cahce if present
;;DIAG_NORCPM; CACHEFILENAME: FIGFILENAME
    ;; cache file name, read if presnet, make if not
;;DIAG_NORCPM; LEADMONTHS: -1
;;DIAG_NORCPM; LEADSEASON: -1
    ;; need one of these
;;DIAG_NORCPM; REG: global
;;DIAG_NORCPM; LATBE: LATB,LATE
;;DIAG_NORCPM; LONBE: LONB,LONE
;;DIAG_NORCPM; LATB: -90.
;;DIAG_NORCPM; LATE:  90.
;;DIAG_NORCPM; LONB:   0.
;;DIAG_NORCPM; LONE: 360.
    ;; lat/lon range average to plot 
;;DIAG_NORCPM; OBSDATASET: 
    ;; need be set if use obs data, see OBSDIR
;;DIAG_NORCPM; ANOMALYANALYSIS: False
    ;; get sort bins by anomaly, not total field
    ;; the anomaly used here does not cover all available data years
;;DIAG_NORCPM; OBSVARNAME: OBSVN 
    ;; for compatibility
;;DIAG_NORCPM; OBSPROXY: -1

load "CODEDIR/func_read_all_members.ncl"
load "CODEDIR/func_read_obs.ncl"
load "CODEDIR/func_read_framework.ncl"
load "CODEDIR/func_areamean.ncl"
load "CODEDIR/func_rank_histogram.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
    ;; Rank Histogram
    ;;     seasonal mean
    ;;     make global cachefile
    ;; create: pgchiu 20Jun2019

    ;; input from diag_norcpm
    dirs=systemfunc("ls -d FORECASTDIRS")
    vn="VARIABLE"
    component="COMPONENT"
    ocngridfile="OCNGRIDFILE"
    slseason = False
    leadmonths = (/LEADMONTHS/)
    if(any(leadmonths.lt.0))then
        lead_season = LEADSEASON
        leadmonths := (/1,2,3/)+((lead_season-1)*3)
        slseason = True
    end if
    figfilename = "FIGFILENAME"
    obsdir = "OBSDIR"
    region = "REG"
    latbe = (/LATBE/)
    lonbe = (/LONBE/)
    titleright = "TITLERIGHT"
    titleleft = "TITLELEFT"
    obsdataset = "OBSDATASET" 
    obsvn = "OBSVARNAME"
    anoanalysis = ANOMALYANALYSIS

    debug = DEBUG
    removecache = REMOVECACHE ;; if True than remove cache file
    cache = "CACHEFILENAME" ;; cache file name, if present than read it
    ;; add .nc if no
    cache = where(ismissing(str_match_regex(cache,".nc$")),cache+".nc",cache)
    proxyObs = OBSPROXY


    if(isfilepresent(cache))then
        f = addfile(cache,"r")
        rank_freq = f->rank_freq
        dims = dimsizes(rank_freq) ;; should be nbins,y,x
        if(isatt(rank_freq,"lat2d"))then ;; netcdf only save 1d array in attitude
            rank_freq@lat2d := onedtond(rank_freq@lat2d,dims(1:2))
            rank_freq@lon2d := onedtond(rank_freq@lon2d,dims(1:2))
        end if
        readMM = rank_freq@readMM
    else
        ;; read model monthly data, should be (forecast,member,month,y,x)
        var = read_noresm_forecasts_members_latlon_leadmonths(dirs,component,vn,leadmonths,latbe,lonbe,ocngridfile)
        dims = dimsizes(var)
        ndim = dimsizes(dims)

        readMM = var@readMM

        if(ndim.gt.5)then
            printVarSummary(var)
            print("variable over 5 dims is not support yet.")
            print("assume data is (forecast,member,dmonth,y,x)")
            print("exit...")
            exit
        end if

        ;; monthly to seasonal
        varSea = dim_avg_n_Wrap(var,2) ;; (forecast,member,y,x)
        if(anoanalysis)then
            varClm = dim_avg_n_Wrap(varSea,0) ;; (member,y,x)
            do i = 0,dims(0)-1 ;; for each forecast
                varSea(i,:,:,:) = varSea(i,:,:,:) - varClm
            end do
        end if


        ;; set first member is proxy observation at all forecast
        ;; ensemble members are other than proxyObs
        if(proxyObs .gt.0)then
            modelEns = 0
            do i = 0, dims(1)-1
                if(i.ne.(proxyObs-1))then
                    modelEns := array_append_record(modelEns,i,0)
                end if
            end do
            modelEns := modelEns(1:)
        else
            modelEns = ispan(0,dims(1)-1,1) 
        end if

        ;; varSea_mem(forecast,member,y,x) and varSea_obs(time,y,x)
        ;;;; ensemble memebers
        varSea_mem = varSea(:,modelEns,:,:)

        ;;;; obs or proxy obs data
        if(proxyObs .gt.0)then ;; use 1 member as obs
            varSea_obs = varSea(:,proxyObs-1,:,:)
        else ;; read real obs data
            inita = cd_calendar(varSea_mem&forecast,0)
            nt = dimsizes(varSea_mem&forecast)

            opt = True ;; for esmf regrid
                ;; assume lat2d, need to add fix lat/lon support
                opt@DstGridLat = get_latlon2d(varSea_mem,"lat2d")
                opt@DstGridLon = get_latlon2d(varSea_mem,"lon2d")
                opt@DstGridMask = where(ismissing(varSea_mem(0,0,:,:)),0,1)
                ;opt@ForceOverwrite = True
                ;opt@Overwrite = True

            varSea_obs = varSea(:,0,:,:)*0. ;; make array

            do t = 0,nt-1
                inityear  = toint(inita(t,0))
                initmonth = toint(inita(t,1))
                ;; multi-year 1season
                ;var1 = dim_avg_n_Wrap(read_obs_leadmonths(obsdir,obsdataset,obsvn,inityear,initmonth,leadmonths),0)
                var1 = dim_avg_n_Wrap(read_obs_framework_leadmonths(obsdir,obsdataset,obsvn,inityear,initmonth,leadmonths,-1,latbe,lonbe),0)
                if(obsvn.eq."sst")then ;; remove too small data
                    var1 = where(var1.lt.0.,var1@_FillValue,var1)
                end if

                ;; regrid to model grid
                opt@SrcGridMask = where(ismissing(var1),0,1)
                system("rm -f source_grid_file.nc destination_grid_file.nc weights_file.nc")
                var1g =  ESMF_regrid(var1,opt)
                varSea_obs(t,:,:) = var1g
                delete(var1)
                delete(var1g)
            end do

            if(anoanalysis)then
                obsClm = dim_avg_n_Wrap(varSea_obs,0) ;; (y,x)
                do i = 0,nt-1 ;; for each time
                    varSea_obs(i,:,:) = varSea_obs(i,:,:) - obsClm
                end do
            end if
        end if

        if(debug);; output read data for debug
            fn = figfilename+"_debug.nc"
            system("rm -f "+fn)
            f = addfile(fn,"c")
            f->varSea_obs = varSea_obs
            f->varSea_mem = varSea_mem
        end if

        ;; cal frequency of each bin each grid
        rank_freq = rank_histogram_2d(varSea_mem,varSea_obs)
        rank_freq@readMM = readMM

        f = addfile(cache,"c")
        f->rank_freq  = rank_freq
    end if

    ;; some meta data
    monNames = (/"0","J","F","M","A","M","J","J","A","S","O","N","D"/)
    readMMs = str_concat(monNames(readMM))

    ;; cal mean rank histogram from global data
    mean_rank = areamean_latbe_lonbe(rank_freq,latbe,lonbe)

    ;; plot histogram
    res = True
        res@gsnXYBarChart = True
        res@vpWidthF = 0.7
        res@vpHeightF = 0.3
        res@trYMinF = 0.00
        res@trYMaxF = 1./dims(0) *2. ; 0.21
        res@trXMinF = 0.4
        res@trXMaxF = dimsizes(mean_rank)+0.6
        res@gsnXYBarChartBarWidth = 0.50                 ; change bar widths
        res@tmXBMode  = "Explicit" 
        res@tmXBLabels  = ispan(1,dimsizes(mean_rank),1)
        res@tmXBValues  = mean_rank&bin
        res@tmXTOn = False
        res@gsnXYBarChartColors  = "Gray"
        res@tiMainString = "TITLE"
        res@gsnLeftString = "TITLELEFT"
        res@gsnRightString = "TITLERIGHT"
        res@gsnLeftString = where(res@gsnLeftString.eq."",region,res@gsnLeftString)
        if(slseason)then
            res@gsnRightString = where(res@gsnRightString.eq."", "leadseason="+lead_season+", "+readMMs,res@gsnRightString)
        else 
            res@gsnRightString = where(res@gsnRightString.eq."", readMMs,res@gsnRightString)
        end if


    PLOTRES

    wks = gsn_open_wks("ps",figfilename)
    plot = gsn_csm_xy(wks,mean_rank&bin, mean_rank,res)
end
