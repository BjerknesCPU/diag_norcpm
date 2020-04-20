;;DIAG_NORCPM; FIGFILEPRE: fig
;;DIAG_NORCPM; LEADSEASON: 1
;;DIAG_NORCPM; FIGFILEPRE: fig

;; not done yet ;;;


load "CODEDIR/func_read_all_members.ncl"
begin
    exit
    foredirs=systemfunc("ls -d FORECASTDIRS")
    vn="VARIABLE"
    component="COMPONENT"
    ocngridfile="OCNGRIDFILE"
    lead_season = LEADSEASON
    figpre = "FIGFILEPRE"

    ;; read data
    var = read_noresm_forecasts_members_leadseason(foredirs,component,vn,lead_season,ocngridfile) ;; froecast,member,time,y,x or f,m,t,lev,y,x

    dims = dimsizes(var)
    nfore = dims(0)
    nmem = dims(1)
    nt = dims(2) ;; should be 3 (1 season)
    t0 = var@t0
    t0@units = var@t0units
    t0YYYYMMDD = cd_calendar(t0,-2)


    ;; plot res
    ;; plot all

    ;do fore = 0, nfore-1
    ;do t = 0, nt-1
    ;do mem = 0, nmem-1
    ;    fn = figpre+"_i"+t0YYYYMMDD+"_"
    ;end do
    ;end do
    ;end do

end
