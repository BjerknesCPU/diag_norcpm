;;DIAG_NORCPM; FIGFILENAME: hadisst_sst_obsamv
;;DIAG_NORCPM; OUTPUTFILENAME: FIGFILENAME
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; TITLE: hadisst obs. amv index
;;DIAG_NORCPM; MONTHS: 0


load "/nird/home/pgchiu/scratch/diag_norcpm/Codes//mpiexm/func_read_mpiexm.ncl"
begin
    figfn = "FIGFILENAME"
write_table("figfilelist.txt","a",[/figfn/],"%s") ;; for mk_html_page.sh
    outfn = "OUTPUTFILENAME.nc"
    title = "TITLE"
    latbe = (/0.,65./)
    lonbe = (/-80.,0./)

df = addfile("/nird/home/pgchiu/NS9039K/shared/obsdata/gridded/SST/HadISST_sst_187001-201910.nc","r")

sst = df->sst(:1787,:,:) ;; 1870-2018
;sst = df->sst(:1775,:,:) ;; 1870-2017
;sst = df->sst(:1751,:,:) ;; 1870-2015
;sst = df->sst(:1727,:,:) ;; 1870-2013
sst = where(ismissing(sst),-9999.,sst)
time = cd_calendar(sst&time,0)
varyzll = month_to_annual(sst,1)
varyzll = where(varyzll.lt.-2.,varyzll@_FillValue,varyzll)
varyzll := varyzll(:,::-1,:)
yb = toint(min(time(:,0)))
ye = toint(max(time(:,0)))
varyzll&year = ispan(yb,ye,1)

;; anomaly
varyzll := dim_rmvmean_n_Wrap(varyzll,0)

gts = mean_with_latbe_lonbe(varyzll,(/-90.,90./),(/0.,360./))
;gts = dim_avg_n_Wrap(varyzll,(/1,2/))
gts!0 = varyzll!0
gts&$gts!0$ = varyzll&$varyzll!0$

;; nonlinear detrend
regmap = regCoef_n(gts,varyzll,0,0)
yint = onedtond(regmap@yintercept,dimsizes(regmap))

resualSST = varyzll
dims = dimsizes(varyzll)
do t = 0, dims(0)-1
    resualSST(t,:,:) = varyzll(t,:,:) - (regmap(:,:)*gts(t)) ;-yint
end do

ts = mean_with_latbe_lonbe(resualSST,latbe,lonbe)
;ts = dim_avg_n_Wrap(resualSST(:,{min(latbe):max(latbe)},{min(lonbe):max(lonbe)}),(/1,2/))
ts!0 = varyzll!0
ts&$ts!0$ = varyzll&$varyzll!0$
x = ts&$ts!0$

if(False)then ;; debug
    system("rm -f tmp.nc")
    f = addfile("tmp.nc","c")
    f->resSST = resualSST
    f->varyzll = varyzll
    f->regmap = regmap
    f->gts = gts
    f->obsamv = ts
    delete(varyzll)
end if
 

        ;; bandpass
;wgt = filwgts_lanczos(21,0,1./10.,-999,1.)
;bpassts = wgt_runave(ts,wgt,0)
bpassts := bw_bandpass_filter(ts,0.001,0.1,False,0)



    wks = gsn_open_wks("ps",figfn)

    res = True
        res@gsnYRefLine = 0.
        res@gsnLeftString = title
        res@gsnFrame = False
        
    PLOTRES
    res@vpHeightF = .3
res@trYMinF = -0.4
res@trYMaxF =  0.4
res@tmXBFormat = "f3.0"


    if(isvar("x"))then
        plot = gsn_csm_xy(wks,x,bpassts,res)
        lres = True
        lres@gsLineColor = "gray"
        gsn_polyline(wks,plot,x,ts,lres)
    else
        plot = gsn_csm_y(wks,ts,res)
    end if
    if(isatt(res,"gsnFrame").and. res@gsnFrame.eq.False)then
        frame(wks)
    end if

    ;; output data file
    system("rm -f "+outfn)
    f = addfile(outfn,"c")
    f->ts = bpassts

end

