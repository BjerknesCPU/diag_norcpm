
;; Rank Histogram (Talagrand Diagram)
;; see https://www.atmos.umd.edu/~ekalnay/syllabi/AOSC630/ensemble101_2014.pdf

;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; BEFOREPLOT: ;; BEFOREPLOT section, empty
;;DIAG_NORCPM; TITLE: Anomaly Correlation
;;DIAG_NORCPM; TITLELEFT: 
;;DIAG_NORCPM; TITLERIGHT: 
;;DIAG_NORCPM; DEBUG: True

load "CODEDIR/func_read_all_members.ncl"
load "CODEDIR/func_read_obs.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin
    ;; Rank Histogram
    ;;     seasonal mean
    ;; create: pgchiu 20Jun2019

    ;; input from diag_norcpm
    dirs=systemfunc("ls -d FORECASTDIRS")
    vn="VARIABLE"
    component="COMPONENT"
    ocngridfile="OCNGRIDFILE"
    lead_season = LEADSEASON
    leadmonths = (/1,2,3/)+((lead_season-1)*3)
    figfilename = "FIGFILENAME"
    obsdir = "OBSDIR"
    debug = DEBUG

    ;; some meta data
    readMM = var@readMM
    monNames = (/"0","J","F","M","A","M","J","J","A","S","O","N","D"/)
    readMonName = str_concat(monNames(readMM))


    ;; read model monthly data, should be (forecast,months,member,y,x)
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

    ;; monthly to seasonal
    varSea = dim_avg_n_Wrap(var,2)


    ;; set first member is proxy observation at all forecast
    ;; ensemble members are other than proxyObs
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

    ;; varSea_mem(forecast,member,y,x) and varSea_obs(time,y,x)
    ;;;; ensemble memebers
    varSea_mem = varSea(:,modelEns,:,:)

    ;;;; obs or proxy obs data
    if(proxyObs .ge.0)then ;; use 1 member as obs
        varSea_obs = varSea(:,proxyObs,:,:)
    else ;; read real obs data
        inita = cd_calendar(varSea_mem&forecast,0)
        nt = dimsizes(varSea_mem&forecast)

        opt = True ;; for esmf regrid
            opt@DstGridLat = varSeaAno@lat2d
            opt@DstGridLon = varSeaAno@lon2d
            opt@DstGridMask = where(ismissing(varSeaAno(0,0,:,:)),0,1)
            ;opt@ForceOverwrite = True
            ;opt@Overwrite = True

        varSea_obs = varSea(:,0,:,:) ;; make array

        do t = 0,nt-1
            inityear  = inita(t,0)
            initmonth = inita(t,1)
            ;; multi-year 1season
            var1 = dim_avg_n_Wrap(read_obs_leadmonths(obsdir,obsdataset,obsvn,inityear,initmonth,leadmonths),0)

            ;; regrid to model grid
            opt@SrcGridMask = where(ismissing(var1),0,1)
            system("rm -f source_grid_file.nc destination_grid_file.nc weights_file.nc")
            var1g =  ESMF_regrid(var1,opt)
            varSea_obs(t,:,:) = var1g
            delete(var1)
            delete(var1g)
        end do

    end if

    if(debug);; output read data for debug
        fn = figfilename+"_debug.nc"
        system("rm -f "+fn)
        f = addfile(fn,"c")
        f->varSea_obs = varSea_obs
        f->varSea_mem = varSea_mem
    end if

    ;; 

end
