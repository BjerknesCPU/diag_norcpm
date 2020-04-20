
;;
;; plot variance ratio in lat/lon of case/control
;;
;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; CACHEFILENAME: FIGFILENAME
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; MONTHS: 0
    ;; which season in yearly time series 

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

    ccase = "CCASE"
    controldir = "CONTROLDIR"
    cybe = (/CONTROLYEARBE/)

    if(isfilepresent(cachefile))then
        f = addfile(cachefile,"r")
        dvar = f->dvar
        dims = dimsizes(dvar)
        if(isatt(dvar,"lat2d"))then
        dvar@lat2d := onedtond(dvar@lat2d,dims)
        dvar@lon2d := onedtond(dvar@lon2d,dims)
        end if
    else
        varall = read_mpiexm_season_YZLL(case,casedir,component,varname,ispan(min(ybe),max(ybe),1),months,1)
        varcon = read_mpiexm_season_YZLL(ccase,controldir,component,varname,ispan(min(cybe),max(cybe),1),months,1)

        dims = dimsizes(varall)
        ndim = dimsizes(dims)
        if(ndim .eq. 3)then
            varvar = dim_variance_n_Wrap(varall(:,:,:),0)
            convar = dim_variance_n_Wrap(varcon(:,:,:),0)
        end if
        if(ndim .eq. 4)then ;; 
            if(dims(1).ne.1)then
                print("Warning, not only one z axis")
                print("    plot first layer")
            end if
            varvar = dim_variance_n_Wrap(varall(:,0,:,:),0)
            convar = dim_variance_n_Wrap(varcon(:,0,:,:),0)
        end if
        dvar = varvar
        dvar = varvar / where(convar.eq.0,convar@_FillValue,convar)

        f = addfile(cachefile,"c")
        f->dvar = dvar
    end if

    res = True
        res@gsnLeftString = title
        res@gsnDraw =  False
        res@gsnFrame = False
        
    lres = True ; additional contour line
        lres@gsnDraw =  False
        lres@gsnFrame = False
        lres@gsnLeftString = ""
        lres@gsnRightString = ""

    PLOTRES

    wks = gsn_open_wks("ps",figfn)

    if(isatt(res,"gsnMaskLambertConformal").and. res@gsnMaskLambertConformal)then
        res@gsnDraw  = False
        res@gsnFrame = False
    end if

    plot = gsn_csm_contour_map(wks,dvar,res)
    if(lres)then
        plot2 = gsn_csm_contour(wks,dvar,lres)
        overlay(plot,plot2)
    end if
    ;; if use mask Lambert Conformal projection
    ;; add lat/lon ticmarks by add_lc_labels()
    if(isatt(res,"gsnMaskLambertConformal").and. res@gsnMaskLambertConformal)then
        add_lc_labels(wks,plot,res@mpMinLatF,res@mpMaxLatF,res@mpMinLonF,res@mpMaxLonF)
    end if
    if(isatt(res,"gsnDraw").and.(.not.res@gsnDraw))then
        draw(plot)
    end if
    if(isatt(res,"gsnFrame").and.(.not.res@gsnFrame))then
        frame(wks)
    end if


end
