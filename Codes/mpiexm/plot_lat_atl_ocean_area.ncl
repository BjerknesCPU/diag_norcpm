

load "func_read_mpiexm.ncl"

figfn = "fig"
write_table("figfilelist.txt","a",[/figfn/],"%s") ;; for mk_html_page.sh
latbe = (/0.,80./)
lonbe = (/-60.,-10./)
;lonbe = (/0.,360./)
reso = 2.  ;; resolution to cal zonal mean
a = read_mpiexm_season_mean_ZLL("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","mpiom","sst",ispan(1060,1060,1),(/1/),0)

regmask = mask_with_latbe_lonbe(a@lat2d,a@lon2d,latbe,lonbe)
wgt = regmask@wgt
copy_VarAtts(a,wgt)
wgt = where(ismissing(a),0,wgt)

;; since gsnZonalMean does not support lat2d...
nzonal = toint((max(latbe)-min(latbe))/reso)
zonalm = new(nzonal,typeof(wgt))
ylat = new(nzonal,typeof(wgt))
do i = 0, nzonal -1
    latb = min(latbe)+(i*reso)
    late = min(latbe)+((i+1)*reso) -0.001
    ylat(i) = avg((/latb,late/))
    m1 = mask_with_latbe_lonbe(a@lat2d,a@lon2d,(/latb,late/),lonbe)
    zonalm(i) = sum(where(m1,wgt,wgt@_FillValue))
    delete(m1)
end do

wks = gsn_open_wks("ps",figfn)

res = True
    res@cnFillOn = True
    res@cnFillMode = "CellFill"
    res@cnLinesOn = False
    res@cnLevels = fspan(0.,1.0,11)
    res@cnLevelSelectionMode = "ExplicitLevels"

plot = gsn_csm_contour_map(wks,wgt,res)
plot2 = gsn_csm_xy(wks,zonalm,ylat,True)

