
;; plot variable difference
;; only support mpiom(ocn) variable now.

;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; CACHEFILENAME: FIGFILENAME
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; MONTHS: 0

load "CODEDIR/mpiexm/func_read_mpiexm.ncl"
begin
    figfn = "FIGFILENAME"
    cachefile = "CACHEFILENAME.nc"
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

    ;; get case ensemble
    if(isfilepresent(cachefile))then
        f = addfile(cachefile,"r")
        varens = f->varens
        if(isatt(varens,"lat2d"))then ;; netcdf cannot save 2d attitude
            dims = dimsizes(varens)
            ndim = dimsizes(dims)
            dims := dims(ndim-2:)
            varens@lat2d := onedtond(varens@lat2d,dims)
            varens@lon2d := onedtond(varens@lon2d,dims)
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

        f = addfile(cachefile,"c")
        f->varens = varens
    end if

    dims = dimsizes(varens)
    if(dims(0).eq.1)then ;; if only 1 level
        varens := varens(0,:,:) ;; 
    end if

    res = True
        res@gsnLeftString = title
    PLOTRES

    if(isatt(res,"gsnMaskLambertConformal").and. res@gsnMaskLambertConformal)then
        res@gsnDraw  = False
        res@gsnFrame = False
    end if

    wks = gsn_open_wks("ps",figfn)
    plot = gsn_csm_contour_map(wks,varens,res)
    
    ;; if use mask Lambert Conformal projection
    ;; add lat/lon ticmarks by add_lc_labels()
    if(isatt(res,"gsnMaskLambertConformal").and. res@gsnMaskLambertConformal)then
        add_lc_labels(wks,plot,res@mpMinLatF,res@mpMaxLatF,res@mpMinLonF,res@mpMaxLonF)
        draw(plot)
        frame(wks)
    end if
end
