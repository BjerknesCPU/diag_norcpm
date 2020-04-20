
;; plot variable difference
;; only support mpiom(ocn) variable now.

;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; MONTHS: 0

load "CODEDIR/mpiexm/func_read_mpiexm.ncl"
begin
    figfn = "FIGFILENAME"
    cachefile = figfn+".nc"
    title = "TITLE"
    varname = "VARIABLE"
    component = "COMPONENT"

    case = "CASE"
    casedir = "CASEDIR"
    ybe = (/YEARBE/)
    months = (/MONTHS/)
    if(any(months .eq.0))then
        months := ispan(1,12,1)
    end if

    modelns = MODELN  ;; if use echam6
    nmodel = dimsizes(modelns)

    ccase = "CCASE"
    controldir = "CONTROLDIR"
    cybe = (/CONTROLYEARBE/)

    ;; get case ensemble
    if(isfilepresent(cachefile))then
        f = addfile(cachefile,"r")
        vardif = f->vardif
        if(isatt(vardif,"lat2d"))then ;; netcdf cannot save 2d attitude
            dims = dimsizes(vardif)
            ndim = dimsizes(dims)
            dims := dims(ndim-2:)
            vardif@lat2d := onedtond(vardif@lat2d,dims)
            vardif@lon2d := onedtond(vardif@lon2d,dims)
            delete(dims)
            delete(ndim)
        end if
    else
        varens = read_mpiexm_season_mean_ZLL(case,casedir,component,varname,ispan(min(ybe),max(ybe),1),months,modelns(0)) 
        varens = varens / nmodel
        do i = 1, nmodel-1
            varens = varens + (read_mpiexm_season_mean_ZLL(case,casedir,component,varname,ispan(min(ybe),max(ybe),1),months,modelns(i))/nmodel)
        end do

        ;print("reading control ")
        ;; get control data, assume only 1 model 
        varcon = read_mpiexm_season_mean_ZLL(ccase,controldir,component,varname,ispan(min(cybe),max(cybe),1),months,0)

        vardif = varens  ;; get coordinate
        vardif = varens - varcon

        f = addfile(cachefile,"c")
        f->vardif = vardif
    end if

    dims = dimsizes(vardif)
    if(dims(0).eq.1)then ;; if only 1 level
        vardif := vardif(0,:,:) ;; 
    end if
    if(dims(1).eq.1)then ;; if only 1 level
        vardif := vardif(:,0,:) ;; 
    end if
    if(dims(2).eq.1)then ;; if only 1 level
        vardif := vardif(:,:,0) ;; 
    end if

    res = True
        res@gsnLeftString = title
    PLOTRES


    wks = gsn_open_wks("ps",figfn)
    plot = gsn_csm_contour(wks,vardif,res)
    
end
