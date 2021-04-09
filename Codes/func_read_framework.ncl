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

undef("expand_years_months")
function expand_years_months(years[*],months[*])
begin
    ;; expand years and months
    ;; ex. years = (/1999,2000,2001,2002/)
    ;;     months = (/6,7,8/)
    ;; return (/(/1999,1999,1999,2000,2000,2000,2001,2001,2001,2002,2002,2002/)
    ;;         ,(/  6,   7,   8,   6,   7,   8,   6,   7,   8,   6,   7,   8 /)/)
    ny = dimsizes(years)
    nm = dimsizes(months)
    ;; expand year and month
    ym = new((/ny*nm,2/),"integer")

    n = 0
    do y = 0,ny-1
    do m = 0,nm-1
        ym(n,0) = years(y)
        ym(n,1) = months(m)
        n = n+1
    end do
    end do

    return ym
end
undef("align_years_months")
procedure align_years_months(year[*],month[*])
begin
    ;; turn month=13 to year+1 month=1
    ;; year and month dimension must same 
    iyear = year
    imonth = month

    do i = 0, 200
        if(any(month.gt.12))then
            year = where(month.gt.12,year+1,year)
            month = where(month.gt.12,month-12,month)
            continue
        end if
        if(any(month.lt.1))then
            year = where(month.lt.1,year+1,year)
            month = where(month.lt.1,month-12,month)
            continue
        end if
        break
    end do
    if(i.ge.200)then
        print("align_years_months(): year/month="+iyear+"/"+imonth+" -> "+year+"/"+month )
        print("align_years_months(): something wrong, check me in func_read_all_members.ncl")
    end if
    return
end
undef("put_val_to_left_dim")
procedure put_val_to_left_dim(large,small,n)
begin
    dims = dimsizes(small)
    ndim = dimsizes(dims)
    if(ndim .eq.2)then
        large(n,:,:) = small
    end if
    if(ndim .eq.3)then
        large(n,:,:,:) = small
    end if
    if(ndim .eq.4)then
        large(n,:,:,:,:) = small
    end if
    if(ndim .eq.5)then
        large(n,:,:,:,:,:) = small
    end if
    return large
end
undef("add_1_dim_left")
function add_1_dim_left(x,n)
begin
    dims = dimsizes(x)
    ndim = dimsizes(dims)
    newx = new(array_append_record(n,dims,0),typeof(x))
    put_val_to_left_dim(newx,x,0)
    return newx
end


undef("mask_with_latbe_lonbe")
function mask_with_latbe_lonbe(ilat2d,ilon2d,latbe,lonbe)
begin
    ;; return a logical mask inside latbe and lonbe
    ;;    dims follow lat2d and lon2d

    ;; check lat2d and lon2d
    latdims = dimsizes(ilat2d)
    londims = dimsizes(ilon2d)
    ;; check them should be same, TBD

    if(dimsizes(latdims).eq.1)then ;; incase 1d lat/lon
        lat2d = conform_dims((/latdims,londims/),ilat2d,0)
        lon2d = conform_dims((/latdims,londims/),ilon2d,1)
    end if
    if(dimsizes(latdims).eq.2)then ;; really 2d lat/lon
        lat2d = ilat2d
        lon2d = ilon2d
    end if

    ;;      if longitude is -180 to +180, middle 0deg
    if(any(lonbe.lt.0))then
        lonmid0 = True
    else ;; if longitude is 0    to  360
        lonmid0 = False
    end if
    
    if(max(lon2d).gt.200 .eq. lonmid0)then
        if(lonmid0)then
            lon2d = where(lon2d.gt.180,lon2d-360.,lon2d)
        else
            lon2d = where(lon2d.lt.0,lon2d+360.,lon2d)
        end if
    end if

    vmask =             lat2d.ge.min(latbe) .and. lat2d.le.max(latbe)
    vmask = vmask .and. lon2d.ge.min(lonbe) .and. lon2d.le.max(lonbe)
    vmask@lat2d = lat2d
    vmask@lon2d = lon2d

    if(dimsizes(latdims).eq.1)then ;; incase 1d lat/lon
        wgt = where(vmask,cos(lat2d/180*get_pi("double")),0)
        vmask@wgt = wgt
    end if

    return vmask
end
undef("wgt_with_latbe_lonbe")
function wgt_with_latbe_lonbe(var,ilat2d,ilon2d,latbe,lonbe)
begin
    ;; get mask
    vmask = mask_with_latbe_lonbe(ilat2d,ilon2d,latbe,lonbe)

    ;; if area2d is in var
    if(isatt(var,"area2d"))then
        wgt = var@area2d
        wgt = where(vmask,wgt,0)
        wgt = wgt/sum(wgt)
        return wgt
    end if
    ;; if 1d lat
    if(isatt(vmask,"wgt"))then
        wgt = vmask@wgt
        return wgt
    end if

    ;; read area.nc, bad idea but should work, need modify
    g_areafile = "~/scratch/diag_norcpm/Data/mpiexm_areas.nc"  ;; bad idea
    dims = dimsizes(lat2d)
    if(all(dims.eq.(/96,192/)))then  ;; for atm, need modify
        af = addfile(g_areafile,"r")
        vn = "al01.srf"
        area = f->$vn$
        wgt = wgt / sum(wgt)
    end if
    if(all(dims.eq.(/220,256/)))then  ;; for ocn, need modify
        af = addfile(g_areafile,"r")
        vn = "oces.srf"
        area = af->$vn$
        ;; there are 2 lon line overlap overlap in data
        adims = dimsizes(area)
        adims(1) = adims(1)+2
        wgt = new(adims,typeof(area))
        wgt = 0.
        wgt(:,:adims(1)-3) = area
        wgt(:,adims(1)-2:) = area(:,:1)
        wgt = wgt / max(wgt)
    end if
    if(.not.isvar("wgt"))then
        print(dims)
        print("mask_with_latbe_lonbe(): no wgt defined...")
        print("see mask_with_latbe_lonbe() in func_read_framework.ncl")
        ;print(lon2d(0,0)+" "+lon2d(0,1))
        ;print(lon2d(0,254)+" "+lon2d(0,255))
        ;print(lat2d(0,0)+" "+lat2d(0,1))
        ;print(lat2d(0,254)+" "+lat2d(0,255))
        exit
    end if


    wgt = where(vmask,wgt,0)
    return wgt
end
undef("mean_with_latbe_lonbe")
function mean_with_latbe_lonbe(var,latbe[2],lonbe[2])
begin
    ;; average rightmost 2 dims with latbe and lonbe
    ;; var should be large than 2 dims
    ;; var should have coordinates or lat2d/lon2d attitdue
    dims = dimsizes(var)
    ndim = dimsizes(dims)
    if(isatt(var,"lat2d"))then
        lat2d = var@lat2d
        lon2d = var@lon2d
    else
        latname = var!(ndim-2)
        lonname = var!(ndim-1)
        lat2d =  var&$latname$;; not really lat2d, but compilable with mask_with_latbe_lonbe()
        lon2d =  var&$lonname$;; not really lon2d, but compilable with mask_with_latbe_lonbe()
    end if
    wgt = wgt_with_latbe_lonbe(var,lat2d,lon2d,latbe,lonbe)
    varts = wgt_areaave2(var,wgt,0) ;; 0 means use non-missing value only
    if(False)then ;; debug
        system("rm -f wgt.nc")
        f = addfile("wgt.nc","c")
        f->wgt = wgt
    end if

    if (ndim.eq.3)then
        copy_VarCoords(var(:,0,0),varts)
    end if
    if (ndim.eq.4)then
        copy_VarCoords(var(:,:,0,0),varts)
    end if
    if (ndim.eq.5)then
        copy_VarCoords(var(:,:,:,0,0),varts)
    end if
    return varts
end
undef("read_file_with_ranges")
function read_file_with_ranges(fn,varname,iindtime[*],levs[*],ybe[2],xbe[2],opt)
begin
    ;; fn: file name(s)
    ;; varname: variable to read in file f
    ;; indtime: time coordinate indexes
    ;; levs: level values, if -1 means all levels
    ;; ybe, xbe: ybe, xbe if fixed/gaussian grid
    ;;          get min square area if use lat2d/lon2d
    ;; opt: optional argument, ex. gridfile.nc for ocn data
    indtime = iindtime 
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

    ;; missing time
    imissingT = ind(ismissing(indtime))
    if(any(ismissing(imissingT)))then
        misTime = False
    else
        ;;;; fill with 0
        indtime(imissingT) = 0
        misTime = True
    end if

    ;; read var, need to add file list function
    if(COORDed .and. COORD0time        .and. ndim.eq.3)then ;; assume time is the first
        if(MultiFile)then
            f := addfiles(fn,"r")
            var = f[:]->$varname$(indtime,latB:latE,lonB:lonE)
        else
            var = f->$varname$(indtime,latB:latE,lonB:lonE)
        end if
        ;; fill _FillValue at missing time
        if(misTime)then
            var(imissingT,:,:) = var@_FillValue
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
                ;; fill _FillValue at missing time
                if(misTime)then
                    var(imissingT,:,:,:) = var@_FillValue
                end if
            else
                var = f[:]->$varname$(indtime,{levs},latB:latE,lonB:lonE)
                ;; fill _FillValue at missing time
                if(misTime)then
                    if(dimsizes(levs).eq.1)then
                        var(imissingT,:,:) = var@_FillValue
                    else
                        var(imissingT,:,:,:) = var@_FillValue
                    end if
                end if
            end if
        else
            var = f->$varname$(indtime,{levs},latB:latE,lonB:lonE)
            ;; fill _FillValue at missing time
            if(misTime)then
                if(dimsizes(levs).eq.1)then
                    var(imissingT,:,:) = var@_FillValue
                else
                    var(imissingT,:,:,:) = var@_FillValue
                end if
            end if
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
        if(misTime)then
            var(imissingT,:,:) = var@_FillValue
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
                if(misTime)then
                    var(imissingT,:,:,:) = var@_FillValue
                end if
            else
                var = f[:]->$varname$(indtime,{levs},bs:bn,bw:be)
                if(misTime)then
                    if(dimsizes(levs).eq.1)then
                        var(imissingT,:,:) = var@_FillValue
                    else
                        var(imissingT,:,:,:) = var@_FillValue
                    end if
                end if
            end if
        else
            if(any(levs.eq.-1))then
                var = f->$varname$(indtime,:,bs:bn,bw:be)
                if(misTime)then
                    var(imissingT,:,:,:) = var@_FillValue
                end if
            else
                var = f->$varname$(indtime,{levs},bs:bn,bw:be)
                if(misTime)then
                    if(dimsizes(levs).eq.1)then
                        var(imissingT,:,:) = var@_FillValue
                    else
                        var(imissingT,:,:,:) = var@_FillValue
                    end if
                end if
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
function read_data_profile_03(dataroot, dataset, varname, iyears, imonths, lev, latbe, lonbe, opt)
begin
    ;; profile 03: one file for all time data, fix lat/lon variable
    ;;      ex. PREC/GPCP
    ;; need filename attribute in opt

    years = iyears
    months = imonths
    ;; data file name
    if(opt .and. isatt(opt,"datafilename"))then
        filename = opt@datafilename
    else
        print("read_data_profile_03() need opt@datafilename to read file.")
        exit
    end if

    align_years_months(years,months)

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
        print(" FillValue, YYYYMM: "+needt(ind(ismissing(indtime))))
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
    ny = dimsizes(years)
    nm = dimsizes(months)
    if(ny.ne.nm)then
        print("read_obs_framework_months(): dims of years and months must be same")
        exit
    end if

    ;;if(str_match_bool_ic(dataroot,"obsdata/gridded") .and. str_match_bool_ic(dataset,"SST/HADISST"))then
    if(str_match_bool_ic(dataset,"SST/HADISST"))then ;; read HadISST from my download
        ;;/nird/home/pgchiu/NS9039K/shared/obsdata/gridded/SST/HadISST_sst_187001-201910.nc
        ;; one file with all data
        opt = True
            opt@datafilename = "SST/HadISST_sst_187001-201910.nc"
        data = read_data_profile_03("~/NS9039K/shared/obsdata/regridded", dataset, varname, years, months, lev, latbe, lonbe, opt)
        data = where(data.lt.-2,data@_FillValue,data)
        return data
    end if

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
    end do
    end do

    return read_obs_framework_months(dataroot, dataset, varname, years, months, lev, latbe, lonbe)
end
function read_obs_framework_season(dataroot, dataset, varname, years[*], months[*], lev, latbe[2],lonbe[2])
begin
    ;;; read and return yearly seasonal data
    ;;; frontend of read_obs_framework_months()
    ym2 = expand_years_months(years,months)
    ny = dimsizes(years)
    nm = dimsizes(months)
    varmon = read_obs_framework_months(dataroot, dataset, varname, ym2(:,0), ym2(:,1), lev, latbe,lonbe)
    dims = dimsizes(varmon)
    ndim = dimsizes(dims)
    ;; create array
    if(ndim.eq.3)then ;; t,y,x
        varall = varmon(:ny-1,:,:) 
    end if
    if(ndim.eq.4)then ;; t,z,y,x
        varall = varmon(:ny-1,:,:,:)
    end if
    do y = 0,ny-1
        if(ndim.eq.3)then ;; t,y,x
            varall(y,:,:) = dim_avg_n_Wrap(varmon(y*nm:(y+1)*nm-1,:,:),0)
        end if
        if(ndim.eq.4)then ;; t,z,y,x
            varall(y,:,:,:) = dim_avg_n_Wrap(varmon(y*nm:(y+1)*nm-1,:,:,:),0)
        end if
    end do

    varall!0 = "year"
    varall&year = years
    varall@months = months
    return varall
end 

function read_obs_framework_season_ts(dataroot, dataset, varname, years[*], months[*], lev, latbe[2],lonbe[2])
begin
    var = read_obs_framework_season(dataroot, dataset, varname, years, months, lev, latbe,lonbe)
    return mean_with_latbe_lonbe(var,latbe,lonbe)
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
;;
    ;;    dataroot = "~/NS9039K/shared/obsdata/gridded" 
    ;;    dataset = "SST/HADISST"
    ;;    varname = "sst"
    ;;    years = (/2018,2019,2020/)
    ;;    months = years
    ;;    months = 1
    ;;    lev = -1
    ;;    latbe = (/-90.,90./)
    ;;    lonbe = (/0.,360./)
    ;;    a = read_obs_framework_months(dataroot, dataset, varname, years, months, lev, latbe, lonbe)
    ;;    b = dim_avg_n_Wrap(a,0)
    ;;    printVarSummary(a)
    ;;    printMinMax(a,0)
    ;;    system("rm -f tmp.nc")
    ;;    f = addfile("tmp.nc","c")
    ;;    f->a = a
    ;;    f->b = b

