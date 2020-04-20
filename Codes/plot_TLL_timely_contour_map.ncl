;;; following comments are for diag_norcpm read, do not delete it.
;;;     they indicate which data/variable needed here,
;;;     and default values in this script.

;DIAG_NORCPM; need_be_replace: COMPONENT, VARIABLE, FIGFILENAME

;;; Following def will be all replaced with defalut value if not pre-set in recipe.
;DIAG_NORCPM; CNFILLMODE: RasterFill
;DIAG_NORCPM; GSNLEFTSTRING: LeftString
;DIAG_NORCPM; BEFORE_PLOT:

begin
    inputdirs = (/INPUTDIRS/)
    inputfiles = systemfunc("ls "+inputdirs(0)+"/COMPONENT/hist/*.h0.*.nc")
    ;fs = addfiles(inputfiles,"r")
    ;var = fs[:]->VARIABLE

    ;dims = dimsizes(var)
    ;ndim = dimsizes(dims)

    ;time = var&time
    ;dates= cd_calendar(time,-5) ;; -5 for after ncl v6.1.0

    res = True
        res@cnFillMode = "CNFILLMODE"
        res@gsnLeftString = "GSNLEFTSTRING"

    BEFORE_PLOT

    do t = 0,3;dims(0)-1
    ;    figfn = "FIGFILENAME"+"_"+dates(t,0)+"-"+dates(t,1)+"-"+dates(t,2)+"T"+dates(t,3)+"-"+dates(t,4)+"-"+dates(t,5)
    ;    print(figfn+"")
        print("t = "+t)
        ;wks = gsn_open_wks("ps",figfn)
        ;plot = gsn_csm_contour_map(wks,var(t,:,:),res)
    end do
end
