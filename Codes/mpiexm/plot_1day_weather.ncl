
;; plot one day weather chart of mpiexm
;; vector + shading + contour

;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; YEAR: 1060
;;DIAG_NORCPM; MONTH: 1
;;DIAG_NORCPM; DAY: 30
;;DIAG_NORCPM; COMPONENT: atm
;;DIAG_NORCPM; MODELN: 1
;;NeedBeReplaced: CASE,CASEDIR,YEAR,MONTH,DAY
;;  These are variables to plot
;;DIAG_NORCPM; VECTORU: ustrw
;;DIAG_NORCPM; VECTORV: vstrw
    ;; wind stress over water
;;DIAG_NORCPM; SHADING: aclcov
    ;; trad0 is OLR
    ;; aclcov is total cloud cover
;;DIAG_NORCPM; CONTOUR: tsurf
    ;; surface temperature
;;DIAG_NORCPM; UILEVEL: -1
;;DIAG_NORCPM; VILEVEL: -1
;;DIAG_NORCPM; SILEVEL: -1
;;DIAG_NORCPM; CILEVEL: -1
    ;; level of index of U,V,SHADING,CONTOUR, -1 means 2d data, no level needed
;;DIAG_NORCPM; USECACHE: True
;;
load "CODEDIR/mpiexm/func_read_mpiexm.ncl"

begin
    figfn = "FIGFILENAME"
    cachefile = figfn+".nc"
    title = "TITLE"
    varname = "VARIABLE"
    component = "COMPONENT"
    modeln = MODELN
    usecache = USECACHE

    ;; case to read
    case = "CASE"
    casedir = "CASEDIR"
    ;; variables
    uvectN = "VECTORU"
    vvectN = "VECTORV"
    shadiN = "SHADING"
    contoN = "CONTOUR" ;; not use now
    uilev = UILEVEL
    vilev = VILEVEL
    silev = SILEVEL
    cilev = CILEVEL

    ;; date to read
    year = YEAR
    month = MONTH
    day = DAY

    ;; get data or calculate it
    if(usecache .and. isfilepresent(cachefile))then
        f = addfile(cachefile,"r")
        uvect = f->$uvectN$
        vvect = f->$vvectN$
        shadi = f->$shadiN$
        ;conto = f->$contoN$
        onedto2d_grid(uvect)
        onedto2d_grid(vvect)
        onedto2d_grid(shadi)
        ;onedto2d_grid(conto)
    else
        uvect = read_mpiexm_1day_modeln(case, casedir,component,uvectN,year,month,day,modeln)
        vvect = read_mpiexm_1day_modeln(case, casedir,component,vvectN,year,month,day,modeln)
        shadi = read_mpiexm_1day_modeln(case, casedir,component,shadiN,year,month,day,modeln)
        ;conto = read_mpiexm_1day_modeln(case, casedir,component,contoN,year,month,day,modeln)

        if(uilev .ne. -1)then
            uvect := uvect(uilev,:,:)
        end if
        if(vilev .ne. -1)then
            vvect := vvect(vilev,:,:)
        end if
        if(silev .ne. -1)then
            svect := svect(silev,:,:)
        end if
        ;if(cilev .ne. -1)then
        ;    cvect := cvect(cilev,:,:)
        ;end if

        system("rm -f '"+cachefile+"'")
        f = addfile(cachefile,"c")
        f->$uvectN$ = uvect
        f->$vvectN$ = vvect
        f->$shadiN$ = shadi
        ;f->$contoN$ = conto
    end if


    ;; plot

    wks = gsn_open_wks("ps",figfn)

    res = True
        res@gsnScalarContour = True
        res@cnFillOn = True
        res@cnLinesOn = False
        res@gsnLeftString = title

    PLOTRES

    if(isatt(res,"gsnMaskLambertConformal").and. res@gsnMaskLambertConformal)then
        res@gsnDraw  = False
        res@gsnFrame = False
    end if

    plot = gsn_csm_vector_scalar_map(wks,uvect,vvect,shadi,res)

    ;; if use mask Lambert Conformal projection
    ;; add lat/lon ticmarks by add_lc_labels()
    if(isatt(res,"gsnMaskLambertConformal").and. res@gsnMaskLambertConformal)then
        add_lc_labels(wks,plot,res@mpMinLatF,res@mpMaxLatF,res@mpMinLonF,res@mpMaxLonF)
        draw(plot)
        frame(wks)
    end if
end
