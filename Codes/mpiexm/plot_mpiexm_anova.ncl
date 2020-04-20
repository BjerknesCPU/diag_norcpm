
;; plot ANOVA to analysis variance between AGCMs
;;      time in yearly(season)
;; Chapter 9 of "Statistical Analysis in Climate Research"
;;      ISBN 0511010184
;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; CACHEFILENAME: FIGFILENAME
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; POSTPLOT: ;; POSTPLOT
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; MONTHS: 0
    ;; 0, means all months
;;DIAG_NORCPM; MODELN: 0


load "CODEDIR/mpiexm/func_read_mpiexm.ncl"
begin
    figfn = "FIGFILENAME"
write_table("figfilelist.txt","a",[/figfn/],"%s") ;; for mk_html_page.sh
    cachefile = "CACHEFILENAME"+".nc"
    title = "TITLE"
    varname = "VARIABLE"
    component = "COMPONENT"

    case = "CASE"
    casedir = "CASEDIR"
    ybe = (/YEARBE/)
    years = ispan(min(ybe),max(ybe),1)
    nyear = dimsizes(years)
    months = (/MONTHS/)
    if(any(months .eq.0))then
        months := ispan(1,12,1)
    end if

    modeln = MODELN  ;; if use echam6
    nmodel = dimsizes(modeln)

    ;; read daily time series
    if(isfilepresent(cachefile))then
        f = addfile(cachefile,"r")
        anova = f->anova
    else
        varMTZLL = read_mpiexm_season_MYZLL(case,casedir,component,varname,years,months,modeln)
        dims = dimsizes(varMTZLL)
        nt = dims(1)

        varensTZLL = dim_avg_n_Wrap(varMTZLL,0) ;; Yoj
        varensTavgZLL = dim_avg_n_Wrap(varensTZLL,0) ;; Yoo
        SSA = nmodel * dim_sum_n((varensTZLL - conform(varensTZLL,varensTavgZLL,(/1,2,3/)))^2,0)  ;; ZLL
        SSE = dim_sum_n((varMTZLL - conform(varMTZLL,varensTZLL,(/1,2,3,4/)))^2,(/0,1/))  ;; ZLL
        fac1 = nt-1
        fac2 = nt*(nmodel-1)
        numerator = SSA - (SSE*fac1/fac2) 
        SST = SSA + SSE
        anova = numerator / SST
        anova := anova(0,:,:)  ;; ZLL -> LL
        copy_VarCoords(varMTZLL(0,0,0,:,:),anova)
        copy_VarCoords(varMTZLL(0,0,:,:,:),SST)
        copy_VarCoords(varMTZLL(0,0,:,:,:),SSA)
        copy_VarCoords(varMTZLL(0,0,:,:,:),SSE)
        copy_VarCoords(varMTZLL(0,0,:,:,:),numerator)

        f = addfile(cachefile,"c")
        f->anova = anova
        f->SST = SST
        f->SSA = SSA
        f->SSE = SSE
        f->numerator = numerator

    end if
    res = True
        res@cnFillOn = True
        res@cnFillMode = "CellFill"
        res@cnLinesOn = False
        res@gsnLeftString = title
        res@gsnRightString = ""
        res@gsnDraw = False
        res@gsnFrame = False
        res@cnLevelSelectionMode = "ExplicitLevels"
        res@cnLevels = fspan(0.,1.,21)
        res@cnFillPalette = "WhiteYellowOrangeRed"


    PLOTRES

    if(isatt(res,"gsnMaskLambertConformal").and. res@gsnMaskLambertConformal)then
        res@gsnDraw  = False
        res@gsnFrame = False
    end if

    wks = gsn_open_wks("ps",figfn)
    plot = gsn_csm_contour_map(wks,anova,res)
    ;;pplot = gsn_csm_contour(wks,regp,pres)
    ;;overlay(plot,pplot)
    
    POSTPLOT

    ;; if use mask Lambert Conformal projection
    ;; add lat/lon ticmarks by add_lc_labels()
    if(isatt(res,"gsnMaskLambertConformal").and. res@gsnMaskLambertConformal)then
        add_lc_labels(wks,plot,res@mpMinLatF,res@mpMaxLatF,res@mpMinLonF,res@mpMaxLonF)
    end if
    if(isatt(res,"gsnDraw").and. res@gsnDraw .eq. False)then
        draw(plot)
    end if
    if(isatt(res,"gsnFrame").and. res@gsnFrame .eq. False)then
        frame(wks)
    end if

end
