undef("reorder_dim_var")
procedure reorder_dim_var(var)
begin
    ;; assume time, lat,lon, bad code need modify
    ;;    if(isMonotonic(var&$var!1$).eq.-1)then ;; reorder from south to north
    ;;        var := var(:,::-1,:) 
    ;;    end if

    ;; wrong code...
    ;;    lon = var&$var!2$
    ;;    if(min(lon).lt.0)then ;; reorder to 0-360 lon
    ;;        lon = where(lon.lt.0,lon+360,lon)
    ;;        qsort(lon)
    ;;        lon = where(lon.gt.180,lon-360,lon)
    ;;        print(lon)
    ;;        var = var(:,:,{lon})
    ;;        var&$var!2$ = where(var&$var!2$.lt.0,var&$var!2$+360.,var&$var!2$)
    ;;    end if

    if (isatt(var,"actual_range"))then ;; actual_range is defined by file
        delete(var@actual_range)
    end if
end

undef("read_file_with_ranges")
function read_file_with_ranges(fn,varname,indtime[*],levs[*],ybe[2],xbe[2],opt)
begin
    ;; fn: file name(s)
    ;; varname: variable to read in file f
    ;; indtime: time coordinate indexes
    ;; levs: level values, if -1 means all levels
    ;; ybe, xbe: ybe, xbe if fixed/gaussian grid
    ;;          get min square area if use lat2d/lon2d
    ;; opt: optional argument, ex. gridfile.nc for ocn data
    
    if(isfile(fn))then
        f = fn
        MultiFile = False
    else
        if(dimsizes(fn).gt.1)then ;; get first file to retrive metadata
            f = addfile(fn(0),"r")
            MultiFile = True
        else
            f = addfile(fn,"r")
            MultiFile = False
        end if
    end if

    fvarnames = getfilevarnames(f)
    if(.not.any(fvarnames.eq.varname))then
        print("read_file_with_ranges(): "+varname+" not found in file ")
        print(""+fvarnames)
        exit
    end if
    dims = getfilevardimsizes(f,varname)
    ndim = dimsizes(dims)

    ;; check if coordinated with lat/lon
    dimnames = getfilevardims(f,varname)
    if(any(str_match_bool_ic(dimnames,"lat")))then
        ilat = ind(str_match_bool_ic(dimnames,"lat"))
        ilon = ind(str_match_bool_ic(dimnames,"lon"))
        COORDed = True
        ;; produce ilatB ilatE ilonB ilonE
        lats = f->$dimnames(ilat)$
        latind = ind(lats.ge.min(ybe) .and. lats.le.max(ybe))
        latB = min(latind)
        latE = max(latind)

        ;; need add lon out of range check
        lons = f->$dimnames(ilon)$
        ;;;; -180-180 or 0-360
        if(any(xbe.lt.0))then ;; -180-180
            lons = where(lons.gt.180,lons-360,lons)
        else ;; 0-360
            lons = where(lons.lt.0,lons+360,lons)
        end if
        lonind = ind(lons.ge.min(xbe) .and. lons.le.max(xbe))
        lonB = min(lonind)
        lonE = max(lonind)
    else
        COORDed = False
    end if

    ;; check first coordinat is time
    COORD0time = False
    if(any(dimnames(0).eq.(/"time","year","month"/)))then
        COORD0time = True
    end if

    ;; read var, need to add file list function
    if(COORDed .and. COORD0time        .and. ndim.eq.3)then ;; assume time is the first
        if(MultiFile)then
            f := addfiles(fn,"r")
            var = f[:]->$varname$(indtime,latB:latE,lonB:lonE)
        else
            var = f->$varname$(indtime,latB:latE,lonB:lonE)
        end if

        reorder_dim_var(var)
        if(typeof(var).eq."short")then
            return short2flt(var)
        else
            return var
        end if
    end if
    if(COORDed .and. (.not.COORD0time) .and. ndim.eq.3)then ;; assume lev is the first
        if(MultiFile)then
            f := addfiles(fn,"r")
            if(any(levs.eq.-1))then
                var = f[:]->$varname$(:,latB:latE,lonB:lonE)
            else
                var = f[:]->$varname$({levs},latB:latE,lonB:lonE)
            end if
        else
            var = f->$varname$({levs},latB:latE,lonB:lonE)
        end if
        reorder_dim_var(var)
        if(typeof(var).eq."short")then
            return short2flt(var)
        else
            return var
        end if
    end if
    if(COORDed .and. COORD0time        .and. ndim.eq.4)then ;; assume time is the first
        if(MultiFile)then
            f := addfiles(fn,"r")
            if(any(levs.eq.-1))then
                var = f[:]->$varname$(indtime,:,latB:latE,lonB:lonE)
            else
                var = f[:]->$varname$(indtime,{levs},latB:latE,lonB:lonE)
            end if
        else
            var = f->$varname$(indtime,{levs},latB:latE,lonB:lonE)
        end if
        reorder_dim_var(var)
        if(typeof(var).eq."short")then
            return short2flt(var)
        else
            return var
        end if
    end if
    if(COORDed)then
        print("read_file_with_ranges(): not supported ndim: "+ndim)
        print("        file(s): "+fn)
        print("        varname: "+varname)
        exit
    end if

    if(.not.COORDed)then ;; assume time is the first and use lat2d/lon2d
        if(.not.isatt(opt,"gridfile"))then
            print("read_file_with_ranges(): var is coordinated with lat2d/lon2d, opt@gridfile is needed.")
            print("        file(s): "+fn)
            print("        varname: "+varname)
            exit
        end if

        gridf = addfile(opt@gridfile,"r")
        varatts = getfilevaratts(f,varname)
        coords = varatts@coordinates
        if(coords .eq. "plon plat")then ;; p cell
            lon = gf->plon
            lat = gf->plat
            ;area= gf->parea
        end if
        if(coords .eq. "ulon ulat")then ;; u cell
            lon = gf->ulon
            lat = gf->ulat
            ;area= gf->uarea
        end if
        if(coords .eq. "vlon vlat")then ;; v cell
            lon = gf->vlon
            lat = gf->vlat
            ;area= gf->varea
        end if
        if(coords .eq. "qlon qlat")then ;; q cell
            lon = gf->qlon
            lat = gf->qlat
            ;area= gf->qarea
        end if
    end if
    
    ;; make rmask to find minium square to read
    rmask = new(dims(n-2:),"logical")
    rmask = True
    rmask = rmask .and. lat2d.ge.min(ybe)
    rmask = rmask .and. lat2d.le.max(ybe)
    rmask = rmask .and. lon2d.ge.min(xbe)
    rmask = rmask .and. lon2d.le.max(xbe)

    ;; get minium square
    conors = id_resolve(ind(rmask),dimsizes(rmask))
    bs = min(conors(:,0))
    bn = max(conors(:,0))
    bw = min(conors(:,1))
    be = max(conors(:,1))
   
    ;; read data
    if(ndim .eq. 3)then ;; t,y,x
        if(MultiFile)then
            f = addfiles(fn,"r")
            var = f[:]->$varname$(indtime,bs:bn,bw:be)
        else
            var = f->$varname$(indtime,bs:bn,bw:be)
        end if
        reorder_dim_var(var)
        if(typeof(var).eq."short")then
            return short2flt(var)
        else
            return var
        end if
    end if
    if(ndim .eq. 4)then
        if(MultiFile)then ;; t,z,y,x
            f = addfiles(fn,"r")
            if(any(levs.eq.-1))then
                var = f[:]->$varname$(indtime,:,bs:bn,bw:be)
            else
                var = f[:]->$varname$(indtime,{levs},bs:bn,bw:be)
            end if
        else
            if(any(levs.eq.-1))then
                var = f->$varname$(indtime,:,bs:bn,bw:be)
            else
                var = f->$varname$(indtime,{levs},bs:bn,bw:be)
            end if
        end if
        reorder_dim_var(var)
        if(typeof(var).eq."short")then
            return short2flt(var)
        else
            return var
        end if
    end if

    print("read_file_with_ranges(): unknow error")
    print("        file(s): "+fn)
    print("        varname: "+varname)
    print(opt)
    exit
end

function read_data_profile_04(dataroot, dataset, varname, years, months, lev, latbe, lonbe, opt)
begin
    ;; profile 04: monthly file, points of data(not grided)
    ;;      ex. SAL/EN4
    print("read_data_profile_04(): yearly file not done yet")
end

function read_data_profile_01(dataroot, dataset, varname, years, months, lev, latbe, lonbe, opt)
begin
    ;; profile 01: monthly file, fix lat/lon variable
    ;;      YYYY_MM.nc
    ;;      ex. SST/HADISST
    ;;          EN4/SAL
    if(opt .and. isatt(opt,"filenameFmt"))then
        fFmt = opt@filenameFmt
    else
        fFmt = "{YYYY}-{MM}"
    end if
    nt = dimsizes(years) ;; should be same as months
    fns = (/""/)
    do t = 0, nt-1
        fn = str_sub_str(fFmt,"{YYYY}",""+years(t))
        fn = str_sub_str(fn,"{MM}",sprinti("%2.2d",months(t)))
        ;;fns := array_append_record(fns,dataroot+"/"+dataset+"/"+fn,0)
        fns := array_append_record(fns,fn,0)
    end do
    fns := fns(1:)
    ;; not done yet
    indtime = ispan(0,nt-1,1)
    return read_file_with_ranges(fns,varname,indtime,lev,latbe,lonbe,opt)
end

function read_data_profile_02(dataroot, dataset, varname, years, months, lev, latbe, lonbe, opt)
begin
    ;; profile 02: yearly file, fix lat/lon variable
    ;;      YYYY.nc
    print("read_data_profile_02(): yearly file not done yet")
    exit
end
function read_data_profile_03(dataroot, dataset, varname, years, months, lev, latbe, lonbe, opt)
begin
    ;; profile 03: one file for all time data, fix lat/lon variable
    ;;      ex. PREC/GPCP
    ;; need filename attribute in opt

    ;; data file name
    if(opt .and. isatt(opt,"datafilename"))then
        filename = opt@datafilename
    else
        print("read_data_profile_03() need opt@datafilename to read file.")
        exit
    end if
    if(dimsizes(years).ne.dimsizes(months))then
        print("read_data_profile_03(): dimsizes of years and months must be same.")
        print("                        years:  "+str_join(dimsizes(years),","))
        print("                        months: "+str_join(dimsizes(months),","))
        exit
    end if

    ;; assume data in time,[lev,],lat,lon

    ;; get time for indexing read
    f = addfile(dataroot+"/"+filename,"r")
    datatime = f->time
    dtYYYYMM = cd_calendar(datatime,-1) ;; data time in YYYYMM
    nt = dimsizes(datatime)

    needt = years*100+months
    nnt = dimsizes(years)

    indtime = -1
    do t = 0, nnt-1
        indtime := array_append_record(indtime, ind(needt(t).eq.dtYYYYMM),0)
    end do
    indtime := indtime(1:)
    if(any(ismissing(indtime)))then
        print("read_data_profile_03(): time missing in data file: "+dataroot+"/"+filename)
        print(needt(ind(ismissing(indtime))))
        exit
    end if
    
    ;; read file
    dims = getfilevardimsizes(f,varname)
    ndim = dimsizes(dims)

    var = read_file_with_ranges(f,varname,indtime,lev,latbe,lonbe,opt)

    delete(f)
    return var

end


undef("read_obs_framework_months")
    ;;  remove "framework" when done
function read_obs_framework_months(dataroot, dataset, varname, years[*], months[*], lev, latbe[2],lonbe[2])
begin
    ;; front end of all reading functions
    ;; dataroot: the path to data, ex. ~/NS9560K/shared/Obs/
    ;; dataset: specifc data set, ex. SST/HADISST
    ;;      both arguments used to determine the reading profile
    ;; 
    ;; varname: variable name to read
    ;; years, months: 1d array with same dimension, data time to read
    ;; latbe, lonbe: range to read, assume small to large, west to east

    if(dataroot.eq."~/NS9560K/shared/Obs" .and. str_match_bool_ic(dataset,"GPCP"))then
        ;; one file with all data
        opt = True
            opt@datafilename = "PRECIP/GPCP.precip.mon.mean.nc"
        return read_data_profile_03(dataroot, dataset, varname, years, months, lev, latbe, lonbe, opt)
    end if
    if(dataroot.eq."~/NS9560K/shared/Obs" .and. str_match_bool_ic(dataset,"HGT/NCEP"))then
        ;; one file with all data
        opt = True
            opt@datafilename = "HGT/NCEP/hgt.mon.mean_1948-2016.nc"
        if(.not.ismissing(str_match_ic_regex(varname,"^hgt[0-9][0-9]*")))then
            vn = "hgt"
            vnlev = stringtoint(str_sub_str(varname,"hgt",""))
            return read_data_profile_03(dataroot, dataset, vn, years, months, vnlev, latbe, lonbe, opt)
        end if
        return read_data_profile_03(dataroot, dataset, varname, years, months, lev, latbe, lonbe, opt)
    end if
    if(dataroot.eq."~/NS9560K/shared/Obs" .and. str_match_bool_ic(dataset,"SST/HADISST"))then
        ;; one month per file
        opt = True
            opt@filenameFmt = "{YYYY}_{MM}.nc"
        return read_data_profile_01(dataroot, dataset, varname, years, months, lev, latbe, lonbe, opt)
    end if
    if(dataroot.eq."~/NS9560K/shared/Obs" .and. str_match_bool_ic(dataset,"SSH/CLS"))then
        ;; one month per file
        opt = True
            opt@filenameFmt = "{YYYY}_{MM}.nc"
        return read_data_profile_01(dataroot, dataset, varname, years, months, lev, latbe, lonbe, opt)
    end if
    if(dataroot.eq."~/NS9560K/shared/Obs" .and. str_match_bool_ic(dataset,"HGT/ERA5"))then
        ;; one file with all data
        opt = True
            opt@datafilename = "HGT/ERA5/era5_hgt.mon.mean_1979-2018.nc"
        if(.not.ismissing(str_match_ic_regex(varname,"^z[0-9][0-9]*")))then
            vn = "z"
            vnlev = stringtoint(str_sub_str(varname,"z",""))
            return read_data_profile_03(dataroot, dataset, vn, years, months, vnlev, latbe, lonbe, opt)
        end if
        return read_data_profile_03(dataroot, dataset, varname, years, months, lev, latbe, lonbe, opt)
    end if
    if(dataroot.eq."~/NS9560K/shared/Obs" .and. str_match_bool_ic(dataset,"GISS"))then
        ;; one file with all data
        opt = True
            opt@datafilename = "AIR_TEM/GISS/air.2x2.250.mon.anom.comb.nc"
        return read_data_profile_03(dataroot, dataset, varname, years, months, lev, latbe, lonbe, opt)
    end if
    if(dataroot.eq."~/NS9560K/shared/Obs" .and. str_match_bool_ic(dataset,"EN4"))then
        ;; monthly data in monthly file
        opt = True 
            opt@filenameFmt = dataroot+"/EN4/ncfiles/"+"EN.4.2.1.f.analysis.g10.{YYYY}{MM}.nc"
        if(varname .eq."ohc")then
            temp = read_data_profile_01(dataroot, dataset, "temperature", years, months, -1, latbe, lonbe, opt)
            saln = read_data_profile_01(dataroot, dataset, "salinity", years, months, -1, latbe, lonbe, opt)
            ohc = cal_ohc_with_temp_salinity_TZLL(temp,saln,100.)
            if(isatt(ohc,"actual_range"))then
                delete(ohc@actual_range)
            end if
            return ohc
        end if
        return read_data_profile_01(dataroot, dataset, varname, years, months, lev, latbe, lonbe, opt)
    end if
    print("read_obs_framework_months(): cannot read data of:")
    print("        dataroot: "+dataroot)
    print("        dataset : "+dataset)
    print("        varname : "+varname)
    exit
    return False
end
function read_obs_framework_leadmonths(dataroot, dataset, varname, inityears[*], initmonths[*], leadmonths[*], lev, latbe[2],lonbe[2])
begin
    ;; produce read time with lead months
    ninit = dimsizes(inityears)
    lnt = dimsizes(leadmonths)
    nt = ninit*lnt
    years = new(nt,"integer")
    months = new(nt,"integer")
    do it = 0, ninit-1
    do l = 0,lnt-1
        t = it*lnt+l
        years(t) = inityears(it)
        months(t) = initmonths(it) + leadmonths(l)
        years(t) = where(months(t).gt.12,years(t)+1,years(t))
        months(t) = where(months(t).gt.12,months(t)-12,months(t))
    end do
    end do

    return read_obs_framework_months(dataroot, dataset, varname, years, months, lev, latbe, lonbe)
end


;; tests
    ;;    dataroot = "~/NS9560K/shared/Obs" ;;/PRECIP/GPCP.precip.mon.mean.nc"
    ;;    dataset = "PRECIP/GPCP"
    ;;    varname = "precip"
    ;;    years = (/1989,1990,1991,1992/)
    ;;    months = years
    ;;    months = 1
    ;;    lev = 0
    ;;    latbe = (/-15.,15./)
    ;;    lonbe = (/110.,270./)
    ;;    a = read_obs_framework_months(dataroot, dataset, varname, years, months, lev, latbe, lonbe)
    ;;    printVarSummary(a)
    ;;    printMinMax(a,0)
    ;;    system("rm -f tmp.nc")
    ;;    f = addfile("tmp.nc","c")
    ;;    f->a = a
    ;;
;;
    ;;    dataroot = "~/NS9560K/shared/Obs" ;;/PRECIP/GPCP.precip.mon.mean.nc"
    ;;    dataset = "EN4/SAL"
    ;;    varname = "salinity"
    ;;    years = (/1989,1990,1991,1992/)
    ;;    months = years
    ;;    months = 1
    ;;    lev = -1
    ;;    latbe = (/-90.,90./)
    ;;    lonbe = (/0.,360./)
    ;;    a = read_obs_framework_months(dataroot, dataset, varname, years, months, lev, latbe, lonbe)
    ;;    printVarSummary(a)
    ;;    printMinMax(a,0)
    ;;    system("rm -f tmp.nc")
    ;;    f = addfile("tmp.nc","c")
    ;;    f->a = a
;;
    ;;    dataroot = "~/NS9560K/shared/Obs" ;;/PRECIP/GPCP.precip.mon.mean.nc"
    ;;    dataset = "HGT/NCEP"
    ;;    varname = "hgt"
    ;;    years = (/1989,1990,1991,1992/)
    ;;    months = years
    ;;    months = 1
    ;;    lev = 700
    ;;    latbe = (/-90.,90./)
    ;;    lonbe = (/0.,360./)
    ;;    a = read_obs_framework_months(dataroot, dataset, varname, years, months, lev, latbe, lonbe)
    ;;    printVarSummary(a)
    ;;    printMinMax(a,0)
    ;;    system("rm -f tmp.nc")
    ;;    f = addfile("tmp.nc","c")
    ;;    f->a = a
;;
    ;;    dataroot = "~/NS9560K/shared/Obs" ;;/PRECIP/GPCP.precip.mon.mean.nc"
    ;;    dataset = "HGT/ERA5"
    ;;    varname = "z"
    ;;    years = (/1989,1990,1991,1992/)
    ;;    months = years
    ;;    months = 1
    ;;    lev = 700
    ;;    latbe = (/-90.,90./)
    ;;    lonbe = (/0.,360./)
    ;;    a = read_obs_framework_months(dataroot, dataset, varname, years, months, lev, latbe, lonbe)
    ;;    printVarSummary(a)
    ;;    printMinMax(a,0)
    ;;    system("rm -f tmp.nc")
    ;;    f = addfile("tmp.nc","c")
    ;;    f->a = a
;;
    ;;    dataroot = "~/NS9560K/shared/Obs" 
    ;;    dataset = "SSH/CLS"
    ;;    varname = "zo"
    ;;    years = (/1999,2000,2001,2002/)
    ;;    months = years
    ;;    months = 1
    ;;    lev = -1
    ;;    latbe = (/-90.,90./)
    ;;    lonbe = (/0.,360./)
    ;;    a = read_obs_framework_months(dataroot, dataset, varname, years, months, lev, latbe, lonbe)
    ;;    printVarSummary(a)
    ;;    printMinMax(a,0)
    ;;    system("rm -f tmp.nc")
    ;;    f = addfile("tmp.nc","c")
    ;;    f->a = a
