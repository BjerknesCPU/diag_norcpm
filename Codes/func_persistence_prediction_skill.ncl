undef("")
function persistent_prediction_skill_maskmean(varRef[*][*][*][*]:numeric,wgt[*][*])
begin
    ;; assume varRef is (initTime,time,y,x), weight is (y,x)
    ;; cal monthly persistent prediction correlation and RMSE
    ;;      along the initTime (as sample)
    ;; output correlation (2,t)

    dims = dimsizes(varRef)
    nIT = dims(0) ;; n initTime
    nt  = dims(1) ;; n simulate time

    ;; get regional mean
    varRef_tt = wgt_areaave2(varRef,wgt,0)  ;; (initTime,time)

    ;; persistent prediction means 'tomorrow will be same as today'
    ;; or 'next month will be same as this month' 
    ;; for "leading month", so the prediction will be constant along time
    varSim_tt = varRef_tt ;; create array
    do iniT = 0,nIT-1
        varSim_tt(iniT,:) = varRef_tt(iniT,0) ;; constant forecast
    end do
    varcor = varSim_tt(0,:)*0
    do t =0,nt-2
        varcor(t) = escorc(varRef_tt(:,t),varSim_tt(:,t))
    end do
    ;varcor = esacr_n(varRef_tt,10,1)
    ;print(varRef_tt(0,:))
    ;print(varcor)
    ;exit

    ;; rmse
    dif = varSim_tt - varRef_tt
    rmse  = dim_avg_n(sqrt(dif*dif),0)

    ;; make output array
    output = new((/2,dimsizes(varcor)/),typeof(varcor))
    output(0,:) = varcor
    output(1,:) = rmse

    return output
end
;; test function
;var = random_normal(100.,9.,(/10,13,64,128/))
;do j = 0,9
;do i = 0,12
;    var(j,i,:,:) = i+j
;end do
;end do
;lat = latGlobeF(64,"lat", "latitude", "degrees_north")
;wgt = conform(var(0,0,:,:),NormCosWgtGlobe(lat),0)
;
;a = persistent_prediction_skill_maskmean(var,wgt)
;print(a(0,:)+" "+a(1,:))
;
