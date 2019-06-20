
;;
;; plot variance ratio in lat/lon of case/control
;;
;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; MONTHS: 0
    ;; which season in yearly time series 

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

        varvar = dim_variance_n_Wrap(varall(:,0,:,:),0)
        convar = dim_variance_n_Wrap(varcon(:,0,:,:),0)
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

    plot = gsn_csm_contour_map(wks,dvar,res)
    if(lres)then
        plot2 = gsn_csm_contour(wks,dvar,lres)
        overlay(plot,plot2)
    end if
    draw(plot)
    frame(wks)


end
