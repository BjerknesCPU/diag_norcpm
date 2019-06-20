
procedure reorder_dim_var(var)
begin
    ;; assume time, lat,lon
    if(isatt(var,"lat2d"))then ;; not fixed grid
        return
    end if

    ndim = dimsizes(dimsizes(var))
    if(ndim.eq.3)then
        if(isMonotonic(var&$var!1$).eq.-1)then ;; reorder from south to north
            var := var(:,::-1,:) 
        end if
        lon = var&$var!2$

        if(min(lon).lt.0)then ;; reorder to 0-360 lon
            lon = where(lon.lt.0,lon+360,lon)
            qsort(lon)
            lon = where(lon.gt.180,lon-360,lon)
            var = var(:,:,{lon})
            var&$var!2$ = where(var&$var!2$.lt.0,var&$var!2$+360.,var&$var!2$)
        end if
    end if
    if(ndim.eq.4)then
        if(isMonotonic(var&$var!2$).eq.-1)then ;; reorder from south to north
            var := var(:,:,::-1,:) 
        end if
        lon = var&$var!3$

        if(min(lon).lt.0)then ;; reorder to 0-360 lon
            lon = where(lon.lt.0,lon+360,lon)
            qsort(lon)
            lon = where(lon.gt.180,lon-360,lon)
            var = var(:,:,:,{lon})
            var&$var!3$ = where(var&$var!3$.lt.0,var&$var!3$+360.,var&$var!3$)
        end if
    end if

    if (isatt(var,"actual_range"))then ;; actual_range is defined by file
        delete(var@actual_range)
    end if
end

function fn_mpiexm(case, casedir,component,varname,year[1],month[*],modeln)
begin
    ;; get data file name
    ;; very simple one, rewrite if need to expand it

    datadir = casedir+"/outdata/"+component+"/"
    if (component.eq."echam6")then ;; it's daily data, and some of them are grb file. Damn.
        yyyymm = year+sprinti("%2.2d",month)
        ;; "_echam_", "_co2_", "_trdiag_"
        ;; if any operation for daily data
        if(isatt(varname,"cdo_operator"))then ;; sould be string or string array
            if(dimsizes(varname@cdo_operator).eq.1)then
                cdoop = "-"+varname@cdo_operator
            else
                cdoop = str_join("-"+varname@cdo_operator," ")
            end if
        else
            cdoop = "-timmean"
        end if
        if(modeln.eq.0)then ;; control run, use grb file

            gribfn = casedir+"/outdata/"+component+"/"+case+"_"+component+"_echam_"+yyyymm+".grb"
            fns = case+"_"+varname+"_"+str_sub_str(cdoop," ","_")+"_"+component+"_echam_"+yyyymm+".nc"

            ;; make tmp nc file
            nf = dimsizes(gribfn)
            do i =0, nf-1
                if(isfilepresent(fns(i)))then
                    continue
                end if
                system("cdo --silent -t echam6 -f nc "+cdoop+" -select,name="+varname+" "+dailyfn(i)+" 'tmp_"+fns(i)+"' && mv 'tmp_"+fns(i)+"'  '"+fns(i)+"'")
            end do
            return fns
        else
            dailyfn = casedir+"/outdata/"+component+"/"+case+sprinti("%2.2d",modeln)+"_"+component+"_echam_"+yyyymm+".nc"
            fns = case+"_"+varname+"_"+str_sub_str(cdoop," ","_")+"_"+component+"_echam_"+yyyymm+".nc"
            fn = case+"_"+varname+"_"+str_sub_str(cdoop," ","_")+"_"+component+"_echam_"+year+"-"+str_join(month,"-")+".nc"
            ;; make tmp nc file
            nf = dimsizes(dailyfn)
            do i =0, nf-1
                if(isfilepresent(fns(i)))then
                    continue
                end if
                system("cdo --silent -t echam6 -f nc "+cdoop+" -select,name="+varname+" "+dailyfn(i)+" 'tmp_"+fns(i)+"' && mv 'tmp_"+fns(i)+"'  '"+fns(i)+"'")
            end do
            return fns

        end if
    end if
    if (component.eq."mpiom")then
        ;; "_data_2d_dm_", "_data_2d_mm_", "_data_3du_mm_", "_data_3dw_mm_", "_monitorig_ym_", "_timeser_dm_"
        fn = case+"_"+component+"_data_2d_mm_"+year+"0101_"+year+"1231.nc"
    end if

    return casedir+"/outdata/"+component+"/"+fn
end

function read_mpiexm_season_1y(case, casedir,component,ivarname,year,months,modeln)
begin
    ;; read months monthly data in same year
    ;; modeln: mondel number, if echam6 is more than 1 run
    varname = ivarname
    ;if(modeln .eq.0)then ;; someone save control run as grb format
    ;    varname = varname+"_GDS4_SFC" ;; for surface variable....
    ;end if 
    if(component.eq."echam6")then
        fns = fn_mpiexm(case, casedir,component,varname,year,months,modeln)
        ;print(fns)
        ;print("read_mpiexm_12m(): reading echam6 is not done yet")
        ;exit
        fs = addfiles(fns,"r")

        var = fs[:]->$varname$
        
        ;; for time,lev,y,x dims
        dims = dimsizes(var)
        ndim = dimsizes(dims)
        if(ndim.eq.3)then ;; assume time,y,x ; insert lev=0
            dims := (/dims(0),1,dims(1),dims(2)/)
            var4d = conform_dims(dims,var,(/0,2,3/))
            var4d!0 = var!0
            var4d&$var4d!0$ = var&$var!0$
            var4d!1 = "lev"
            var4d!2 = var!1
            var4d&$var4d!2$ = var&$var!1$
            var4d!3 = var!2
            var4d&$var4d!3$ = var&$var!2$
            copy_VarAtts(var,var4d)
        end if
        reorder_dim_var(var4d)
        return var4d
    end if

    if(component.eq."mpiom")then ;; yearly file
        fn = fn_mpiexm(case, casedir,component,varname,year,0,modeln)
        f = addfile(fn,"r")
        var = f->$varname$
        if(var@coordinates .eq. "lon lat")then
            var@lat2d = f->lat
            var@lon2d = f->lon
        end if
        var := var(months-1,:,:,:)
        return var
    end if
    print("read_mpiexm_season_1y(): unknown component: "+component)
    exit
end
function read_mpiexm_12m(case, casedir,component,varname,year,modeln)
begin
    return read_mpiexm_season_1y(case, casedir,component,varname,year,ispan(1,12,1),modeln)
    if(False)then ;; waiting for obsolate
        ;; read 12 month monthly data 
        ;; modeln: mondel number, if echam6 is more than 1 run
        if(component.eq."echam6")then
            ;; pass now
            fns = fn_mpiexm(case, casedir,component,varname,year,ispan(1,12,1),modeln)
            ;print(fns)
            ;print("read_mpiexm_12m(): reading echam6 is not done yet")
            ;exit
            fs = addfiles(fns,"r")

            var = fs[:]->$varname$
            
            ;; for time,lev,y,x dims
            dims = dimsizes(var)
            ndim = dimsizes(dims)
            if(ndim.eq.3)then ;; assume time,y,x ; insert lev=0
                dims := (/dims(0),1,dims(1),dims(2)/)
                var4d = conform_dims(dims,var,(/0,2,3/))
                var4d!0 = var!0
                var4d&$var4d!0$ = var&$var!0$
                var4d!1 = "lev"
                var4d!2 = var!1
                var4d&$var4d!2$ = var&$var!1$
                var4d!3 = var!2
                var4d&$var4d!3$ = var&$var!2$
                copy_VarAtts(var,var4d)
            end if
            return var4d

        end if
        if(component.eq."mpiom")then
            fn = fn_mpiexm(case, casedir,component,varname,year,0,modeln)
            f = addfile(fn,"r")
            var = f->$varname$
            if(var@coordinates .eq. "lon lat")then
                var@lat2d = f->lat
                var@lon2d = f->lon
            end if
            return var
        end if
        print("read_mpiexm_12m(): unknown component: "+component)
        exit
    end if
end
function read_mpiexm_YMZLL(case, casedir,component,varname,years,modeln)
begin
    ;; frontend of read_mpiexm_12m(), read years
    ;; output var in year,month,(lev,),y,x
    print("read_mpiexm_YMZLL(): need modify metadata")
    exit ;; not done yet

    ny = dimsizes(years)
    var12m = read_mpiexm_12m(case,casedir,component,varname,years(0),modeln)
    dims12m = dimsizes(var12m)
    ndim12m = dimsizes(dims12m)
    dims = array_append_record(ny,dims12m,0)
    varall = conform_dims(dims,var12m,ispan(1,ndim12m,1))

    delete(var12m)
    do y = 1,ny-1
        var12m = read_mpiexm_12m(case,casedir,component,varname,years(y),modeln)
        varall(y,:,:,:,:)  = var12m
        delete(var12m)
    end do

    return varall
end
function read_mpiexm_TZLL(case, casedir,component,varname,years,modeln)
begin
    ;; frontend of read_mpiexm_12m(), read years
    ;; output var in time,(lev,),y,x
    print("read_mpiexm_TZLL(): need modify metadata")
    exit ;; not done yet

    ny = dimsizes(years)
    var12m = read_mpiexm_12m(case,casedir,component,varname,years(0),modeln)
    dims12m = dimsizes(var12m)
    ndim12m = dimsizes(dims12m)
    dims = dims12m
    dims(0) = dims(0)*ny
    varall = new(dims,typeof(var12m))
    time = new(dims(0),typeof(var12m&time))
    varall(0:11,:,:,:) = var12m
    time(0:11) = var12m&time
    tunits = time@units

    delete(var12m)

    do y = 1,ny-1
        var12m = read_mpiexm_12m(case,casedir,component,varname,years(y),modeln)
        varall(y*12:y*12+11,:,:,:)  = var12m
        time(y*12:y*12+11) = cd_convert(var12m&time,tunits) ;; warning:VarVarWrite: lhs has dimension name and rhs doesn't, deleting name of lhs dimension number(0)
        delete(var12m)
    end do
    varall&time = time
    return varall
end

function read_mpiexm_season_YZLL(case, casedir,component,varname,years,imonths,modeln)
begin
    ;; frontend of read_mpiexm_12m(), read yearly average
    ;; output var in year,(lev,),y,x

    if(any(imonths .eq.0))then
        months = ispan(1,12,1)
    else
        months = imonths
    end if

    ny = dimsizes(years)
    nmonth = dimsizes(months)
    var1y = dim_avg_n_Wrap(read_mpiexm_season_1y(case,casedir,component,varname,years(0),months,modeln),0)
    dims1y = dimsizes(var1y)
    dims = array_append_record(ny,dims1y,0)
    varyr = new(dims,typeof(var1y))
    varyr(0,:,:,:) = var1y

    delete(var1y)
    do y =  1,ny-1
        ;;print("read_mpiexm_season_YZLL(): reading "+years(y))
        var1y = dim_avg_n_Wrap(read_mpiexm_season_1y(case,casedir,component,varname,years(y),months,modeln),0)
        varyr(y,:,:,:) = var1y
        delete(var1y)
    end do
    varyr!0 = "year"
    varyr&year = years
    varyr@months = months
    return varyr
end
function read_mpiexm_YZLL(case, casedir,component,varname,years,modeln)
begin
    return read_mpiexm_season_YZLL(case, casedir,component,varname,years,ispan(1,12,1),modeln)
end

function read_mpiexm_season_mean_ZLL(case, casedir,component,varname,years,imonths,modeln)
begin
    ;; frontend of read_mpiexm_season_1y(), read yearly average
    ;; output var in lev,,y,x

    if(any(imonths .eq.0))then
        months = ispan(1,12,1)
    else
        months = imonths
    end if

    ny = dimsizes(years)
    nmonth = dimsizes(months)
    var1y = dim_avg_n_Wrap(read_mpiexm_season_1y(case,casedir,component,varname,years(0),months,modeln),0)
    var1y = var1y/ny

    do y =  1,ny-1
        ;;print("read_mpiexm_season_YZLL(): reading "+years(y))
        var1y = var1y + (dim_avg_n_Wrap(read_mpiexm_season_1y(case,casedir,component,varname,years(y),months,modeln),0)/ny)
    end do
    var1y@months = months
    var1y@years = years
    return var1y
end
