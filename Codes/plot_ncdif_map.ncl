
;; plot difference of given netcdf file on map
;;      dif = varA - varB

;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; BEFOREPLOT: ;; BEFOREPLOT
;;DIAG_NORCPM; AFTERPLOT: ;; AFTERPLOT
;;DIAG_NORCPM; FIGFILENAMEPROC: write_table("figfilelist.txt","a",[/figfn/],"%s") ;; for mk_html_page.sh


begin
    figfn = "FIGFILENAME"
    title = "TITLE"

    FIGFILENAMEPROC

    ncfileA = "NCFILEA"
    vnA    = "VARIABLEA"
    ncfileB = "NCFILEB"
    vnB    = "VARIABLEB"

    ;; assume varA and varB are same dimension
    fA = addfile(ncfileA,"r")
    varA = fA->$vnA$
    fB = addfile(ncfileB,"r")
    varB = fB->$vnB$

    dif = varA
    dif = varA-varB



    
    res = True

        res@cnFillOn    = True
        res@cnFillMode  = "CellFill"
        res@cnLinesOn   = False
        res@gsnLeftString = title
        
    PLOTRES

    wks = gsn_open_wks("ps",figfn)

    BEFOREPLOT

    plot_fill = gsn_csm_contour_map(wks,dif,res)

    AFTERPLOT
end
