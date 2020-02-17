
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; SUBTITLE: none
;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; NCFILES: none
;;DIAG_NORCPM; NCFILEVARSX: (/"none"/)
;;DIAG_NORCPM; NCFILEVARSY: (/"none"/)
;;DIAG_NORCPM; LINESLEGEND: (/"none"/)
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; BASEPLOTRES: ;; BASEPLOTRES
;;DIAG_NORCPM; ADDLINESRES: ;; ADDLINESRES
;;DIAG_NORCPM; LEGENDRES: ;; LEGENDRES
;;DIAG_NORCPM; ATTACHRES: ;; ATTACHRES

begin
    title = "TITLE"
    subtitle = "SUBTITLE"
    figfn = "FIGFILENAME"
    ncfiles = NCFILES
    xvns = NCFILEVARSX
    yvns = NCFILEVARSY
    legs = LINESLEGEND

    nf = dimsizes(ncfiles)

    res = True
        if(subtitle.eq."none")then
            res@gsnLeftString = title
        else
            res@tiMainString = title
            res@gsnLeftString = subtitle
        end if
        res@gsnFrame = False
        res@gsnDraw = False

    PLOTRES
    BASEPLOTRES

    wks = gsn_open_wks("ps",figfn)

    if(nf .eq.1)then
        f = addfile(ncfiles,"r")
        x = f->$xvns$
        y = f->$yvns$
        plot = gsn_csm_xy(wks,x,y,res)
        exit
    end if

    f = addfile(ncfiles(0),"r")
    x = f->$xvns(0)$
    y = f->$yvns(0)$
    plot = gsn_csm_xy(wks,x,y,res)
    
    delete(res)
    res = True
    do i = 1,nf-1
        ADDLINESRES
        f = addfile(ncfiles(i),"r")
        x := f->$xvns(i)$
        y := f->$yvns(i)$
        gsn_polyline(wks,plot,x,y,res)
    end do
    delete(res)

    ;; add legend
    res = True
        res@lgItemType         = "Lines"
        res@vpWidthF = .15
        res@vpHeightF = .1
    LEGENDRES
    lbid = gsn_create_legend(wks,nf,legs,res)
    delete(res)
    res = True
        res@amParallelPosF = .0
        res@amOrthogonalPosF = .0
    ATTACHRES
    ann = gsn_add_annotation(plot,lbid,res)
    draw(plot)
    frame(wks)
end
