load "Codes/mpiexm/func_read_mpiexm.ncl"
    
begin
    case = "f06_5AGCMs_NASPG_average_pgchiu"
    casedir = "/tos-project4/NS9207K/pgchiu/f06_5AGCMs_NASPG_average_pgchiu"
    ybe = (/1950,2020/)
    ybe = (/1950,1970/)
    months = ispan(1,3,1)

    component = "mpiom"
    varname = "sst"

    component = "echam6"
    varname = "tsurf"

    varens = read_mpiexm_season_YZLL(case,casedir,component,varname,ispan(min(ybe),max(ybe),1),months,1)
    printVarSummary(varens)
end
