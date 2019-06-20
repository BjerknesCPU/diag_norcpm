

;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; PLOTRES: ;; PLOTRES
;;DIAG_NORCPM; TITLE: title
;;DIAG_NORCPM; MONTHS: 0

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

    modelns = MODELN  ;; if use echam6
    nmodel = dimsizes(modelns)

    ccase = "CCASE"
    controldir = "CONTROLDIR"
    cybe = (/CONTROLYEARBE/)

    if(any(months.eq.0))then
        months := ispan(1,12,1)
    end if

    ;; get case ensemble
    if(isfilepresent(cachefile))then
        f = addfile(cachefile,"r")
        vardif = f->vardif
    else
        varens = read_mpiexm_season_YZLL(case,casedir,component,varname,ispan(min(ybe),max(ybe),1),months,modelns(0)) 
        varens := dim_avg_n_Wrap(varens,0) / nmodel
        do i = 1, nmodel-1
            print("reading model "+(i+1))
            varens = varens + (dim_avg_n_Wrap(read_mpiexm_season_YZLL(case,casedir,component,varname,ispan(min(ybe),max(ybe),1),months,modelns(i)),0)/nmodel)
        end do

        print("reading control ")
        ;; get control data, assume only 1 model 
        varcon = read_mpiexm_season_YZLL(ccase,controldir,component,varname,ispan(min(cybe),max(cybe),1),months,0)
        print("read control model in "+(get_cpu_time()-begTime)+" sec")
        varcon := dim_avg_n_Wrap(varcom,0)

        vardif = varens  ;; get coordinate
        vardif = varens - varcon

        f = addfile(cachefile,"c")
        f->vardif = vardif
    end if

    res = True
    ;PLOTRES

    wks = gsn_open_wks("ps",figfn)
    plot = gsn_csm_contour_map(wks,vardif,res)
    
end
