
undef("assign_ocn_grid")
procedure assign_ocn_grid(var,ocngridfile)
begin
    if(.not.isatt(var,"coordinates"))then ;; not ocn data
        return
    end if
    if(.not.isfilepresent(ocngridfile))then ;; no ocn grid file
        print("assign_ocn_grid(): no ocn grid file: '"+ocngridfile+"'")
        return
    end if

    if (isfilepresent(ocngridfile))then ;; assign lat/lon to ocn variables
        gf = addfile(ocngridfile,"r")
        coords = var@coordinates
        if(coords .eq. "plon plat")then ;; p cell
            lon = gf->plon
            lat = gf->plat
            area= gf->parea
        end if
        if(coords .eq. "ulon ulat")then ;; u cell
            lon = gf->ulon
            lat = gf->ulat
            area= gf->uarea
        end if
        if(coords .eq. "vlon vlat")then ;; v cell
            lon = gf->vlon
            lat = gf->vlat
            area= gf->varea
        end if
        if(coords .eq. "qlon qlat")then ;; q cell
            lon = gf->qlon
            lat = gf->qlat
            area= gf->qarea
        end if 
        if(isatt(var,"mask2d"))then ;; regional data
            l2dmask = var@mask2d
            i = ind_resolve(ind(ndtooned(l2dmask)),dimsizes(l2dmask))
            bs = min(i(:,0))
            bn = max(i(:,0))
            bw = min(i(:,1))
            be = max(i(:,1))
            var@lat2d = lat(bs:bn,bw:be)
            var@lon2d = lon(bs:bn,bw:be)
            var@area2d = area(bs:bn,bw:be)

        else
            var@lat2d = lat
            var@lon2d = lon
            var@area2d = area
        end if
    end if
end
undef("align_years_months")
procedure align_years_months(year[*],month[*])
begin
    ;; turn month=13 to year+1 month=1
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
function get_latlon2d(var,lat2dorlon2d)
begin
    ;; use var attitude or coordinate
    if(isatt(var,lat2dorlon2d))then
        return var@$lat2dorlon2d$
    else
        ;; get coordinate
        dims = dimsizes(var)
        ndim = dimsizes(dims)
        if(lat2dorlon2d .eq."lat2d")then
            src = var&lat
            nn = ndim-2
            dn = 0
        end if
        if(lat2dorlon2d .eq."lon2d")then
            src = var&lon
            nn = ndim-1
            dn = 1
        end if
        src2d = conform_dims(dims(ndim-2:),src,dn)
        return src2d
    end if

end

function get_file_latlon2d(fn,varname,ocngridfile)
begin
    ;; var can be empty with getfilevaratts()
    f = addfile(fn,"r")
    varatts = getfilevaratts(f,varname)
    if(any(varatts .eq. "coordinates"))then ;; ocn data
        varatts@coordinates = f->$varname$@coordinates
        assign_ocn_grid(varatts,ocngridfile)
        return varatts
    end if
    ;; atm data, lat/lon
    lat = f->lat
    lon = f->lon
    dims = getfilevardimsizes(f,varname)
    ndim = dimsizes(dims)
    lat2d = conform_dims(dims,lat,ndim-2)
    lon2d = conform_dims(dims,lon,ndim-1)
    varatts@lat2d = lat2d
    varatts@lon2d = lon2d
    return varatts
end
undef("")
function get_members_path(forecastdir[1])
begin
    ;; not done yet
    ;; list members path with 1 forecast dir or .tar.gz
    ;; used to replace:  memberdirs = systemfunc("ls -d "+forecastdir+"/*mem??")
    
    ;if(.not.ismissing(str_match_regex(forecastdir,".tar.gz$")))then ;; if end with .tar.gz
        
    ;end if

    ;; normally without any postprocess
    memberdirs = systemfunc("ls -d "+forecastdir+"/*mem??")
    return memberdirs
end 
undef("get_var_area_wgt2d")   
function get_var_area_wgt_lat_lon_2d(var,whichone) ;; old function
begin
    ;; get 2D wgt or lat or lon from var
    ;; whichone should be "lat", "lon", "wgt"
    if(isatt(var,"lat2d"))then
        ; ocn use 2d area, lat and lon
        if(whichone.eq."wgt")then
            varcod = var@area2d
        end if
        if(whichone.eq."lat")then
            varcod = var@lat2d
        end if
        if(whichone.eq."lon")then
            varcod = var@lon2d
        end if
        if(dimsizes(dimsizes(varcod)).eq.1)then ;; read from nc, 2d attitude is saved as 1d 
            dims = dimsizes(var)
            ndim = dimsizes(dims)
            varcod := onedtond(varcod,dims(ndim-2:)) ;; assume rightmost is lat,lon
        end if
        return varcod
    else 
        ; atm use 1D lat and lon
        ;; assume right most 2 dim is lat,lon
        ndim = dimsizes(dimsizes(var))
        latd = ndim-2
        lond = ndim-1
        lats = var&$var!latd$
        lons = var&$var!lond$
        if(whichone.eq."wgt")then
            varcod = conform_dims((/dimsizes(lats),dimsizes(lons)/),NormCosWgtGlobe(lats),0)
        end if
        if(whichone.eq."lat")then
            varcod = conform_dims((/dimsizes(lats),dimsizes(lons)/),lats,0)
        end if
        if(whichone.eq."lon")then
            varcod = conform_dims((/dimsizes(lats),dimsizes(lons)/),lons,1)
        end if
        return varcod
    end if
    print("get_var_area_wgt_lat_lon_2d(): ERROR, see var summary:")
    printVarSummary(var)
    print("get_var_area_wgt_lat_lon_2d(): whichone = "+whichone)
    exit
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

    vmask = mask_with_latbe_lonbe(ilat2d,ilon2d,latbe,lonbe)
    ;; if area2d is in var
    if(isatt(var,"area2d"))then
        wgt = var@area2d
        wgt = where(vmask,wgt,0)
        wgt = wgt/sum(wgt)
        return wgt
    end if
    ;; get mask if 1d lat
    if(isatt(vmask,"wgt"))then
        wgt = vmask@wgt
        return wgt
    end if

    ;; read area.nc, bad idea but should work, need modify
    g_areafile = "~/scratch/diag_norcpm/Data/mpiexm_areas.nc"  ;; bad idea
    dims = dimsizes(ilat2d)
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
        print("see mask_with_latbe_lonbe() in func_read_all_members.ncl")
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
undef("get_year_month_from_dirname")
function get_year_month_from_dirname(dirname[1]:string)
begin
    ;; get year and month from member or forecast dir 
    ;; ex: ana_19800115_me_dec_20111015
    ;; ex: ana_19800115_me_dec_20111015_mem04
    ;; return year,month array

    ;; rightmost digital string
    dirname_fields = str_split(dirname,"_")
    yyyymmdd = dirname_fields(max(ind(is_string_numeric(dirname_fields))))
    if(.not.(strlen(yyyymmdd).eq.8))then
        print("get_year_month_from_dirname(): parsing error to "+dirname)
        exit
    end if

    ;;aa1 = str_split(dirname,"_")
    ;;na = dimsizes(aa1)
    ;;yyyymm = where(str_match_bool(aa1(na-1),"mem"),aa1(na-2),aa1(na-1))

    year = toint(yyyymmdd)/10000
    month = (toint(yyyymmdd)%10000)/100
    return (/year,month/)

end
undef("get_start_date_ncfn_from_dirname")
function get_start_date_ncfn_from_dirname(dirname,component)
begin
    ;;;; assume dirname is split by "_"
    ;;;; and start date placed at last numeric field

    monfix=""
    if(component.eq."ocn")then
        monfix="hm"
    end if
    if(component.eq."atm")then
        monfix="h0"
    end if

    ym = get_year_month_from_dirname(dirname)
    start_date_year = ym(0)
    start_date_mm = ym(1)
    fn = systemfunc("ls "+dirname+"/"+component+"/hist/*"+monfix+"*"+start_date_year+"-"+sprinti("%2.2d",start_date_mm)+".nc|sort|head -n1")
    fn@start_date_year = start_date_year
    fn@start_date_month = start_date_mm
    return fn
end
undef("get_year_month_from_filename")
function get_year_month_from_filename(fns[*]:string)
begin
    ;; get year and month from file name
    ;; ex: ana_19800115_me_dec_20111015_mem04.micom.hm.2022-07.nc
    ;; return year,month array
    nfn = dimsizes(fns)
    fns_ym = new((/nfn,2/),"integer")
    do i = 0, nfn-1
        fn = fns(i)
        aa1 = str_split(fn,".")
        aa2 = aa1(dimsizes(aa1)-2) ;; get second rightmost item
        fns_ym(i,:) = toint(str_split(aa2,"-"))
    end do
    return fns_ym
end
undef("ls_monthly_season_nc_files")
function ls_monthly_season_nc_files(path,component,months)
begin
    ;; path is the 1 member dir, which contains:
    ;;      path/atm/hist/*.nc
    ;; or
    ;;      path(with .tar.gz)/atm/hist/*.nc
    monfix=""
    if(component.eq."ocn")then
        monfix="hm"
    end if
    if(component.eq."atm")then
        monfix="h0"
    end if
    ;;print("ls_monthly_nc_files(): Warning, readall datafiles, need modify.")

    ;; normally the data is not gzipped or postprocessed
    ;;fns = systemfunc("ls "+path+"/"+component+"/hist/*"+monfix+"*.nc|sort|head -n13") ;; only 13 month data, bad idea
    fns = systemfunc("find "+path+"/"+component+"/hist/ -type f -name \*"+monfix+"\*.nc|sort") ;; all file in dir, also bad idea

    if(any(ismissing(fns)))then
        print("ls_monthly_season_nc_files(): data missing in ")
        print("ls_monthly_season_nc_files(): "+path+"/"+component+"/hist/")
        exit
    end if

    ;; filtering files needed
    ;;;; get year month in filename
    fns_ym = get_year_month_from_filename(fns)
    ym_start = get_year_month_from_dirname(path)
    nm = dimsizes(months)
    startyear = ym_start(0)
    endyear = max(fns_ym(:,0))
    ineed = (/-1/)
    gotyears = (/-1/)
    do y = startyear,endyear
        ineedyr = (/-1/)
        do m = 0,nm-1
            needyear = y
            needmonth = months(m)
            align_years_months(needyear,needmonth)
            ii = ind(fns_ym(:,0).eq.needyear .and. fns_ym(:,1).eq.needmonth)
            if(.not.ismissing(ii))then
                ineedyr := array_append_record(ineedyr,ii,0)
            end if
        end do
        if(dimsizes(ineedyr).eq.(nm+1))then ;; all month matched in this year
            ineed := array_append_record(ineed,ineedyr(1:),0)
            gotyears := array_append_record(gotyears,y,0)
        end if
        delete(ineedyr)
    end do
    if(dimsizes(ineed).ge.1)then ;; every thing goes fine
        ineed := ineed(1:)
        return fns(ineed)
    else
        print("ls_monthly_season_nc_files(): something goes wrong here.")
        print("path: "+path)
        print("component: "+component)
        print("months: "+months)
        exit
    end if

    ;; if data files are tar and gz...
    ;; not done yet
        ;; tar -C tmp/ --strip-components 9  --occurrence  -vxf  /tos-project3/NS9602K/V1c60/HIND/ocn/sfe60_hindcast_19951015_ocn.tar.gz  cluster/work/users/madimm/archive/tar_folder/sfe60_hindcast_19951015_ocn/sfe60_hindcast_19951015_mem09/ocn/hist/sfe60_hindcast_19951015_mem09.micom.hm.1996-05.nc
            ;; bad idea, if we need the last file in tar.gz, then the occurrence argument will not help
            ;; it will become:
                ;; extract all file -> 2 mins
                ;; extract 1 file -> 2sec to 2mins, each file
        ;; since gz is line ziper, so extract all files is a more effency method
        ;; untar all zip and extract one variable, than remove data files
            ;; when to remove datafiles? after all plots done?
                ;; or just after extract 1 variable of all files in 1 tar.gz
                    ;; problem is this will repeat extract same file for each variable
                ;; or use a plotScript to extract all variable in all recipe
                    ;; A meta recipe collect all variables?
            ;; extract variable to where?
                ;; common tmp data directory, but where?
                ;; too large for /tmp or /dev/shm
    if(.not.ismissing(str_match_regex(path,".tar.gz$")))then
        tmpdir = "./tmpdata"
        system("mkdir -p "+tmpdir)

    end if

    if(any(ismissing(fns)))then
        print("ls_monthly_nc_files(): no file in "+path)
        exit
    end if
    ;print("ls_monthly_nc_files(): read ncfiles:")
    ;print(fns)
    ;exit
    return fns
end

undef("ls_monthly_nc_files")
function ls_monthly_nc_files(path,component)
begin
    return ls_monthly_season_nc_files(path,component,ispan(1,12,1))
end
undef("read_partial_file_by_indbox")
function read_partial_file_by_indbox(f,varname,bs,bn,bw,be)
begin
    ;; f is file list, can be only 1 file. But must list
    ;; f[:]->$varname$(:,bs:bn,bw:be)
    ;; bs < bn, bw < be. Those just for index, not exactly lat/lon
    dims = getfilevardimsizes(f[0],varname)
    ndim = dimsizes(dims)
    vtype = getfilevartypes(f[0],varname)

    if(vtype .eq. "short")then
        nfile = ListCount(f)
        dims := array_append_record(nfile,dims,0)
        dims(ndim) = be-bw+1
        dims(ndim-1) = bn-bs+1
        var = new(dims,"float")  ;; convert short to float with add_offset and scale_factor
        do i = 0,nfile-1
            if(ndim.eq.2)then
                var(i,:,:) = short2flt(f[i]->$varname$(bs:bn,bw:be))
            end if
            if(ndim.eq.3)then
                var(i,:,:,:) = short2flt(f[i]->$varname$(:,bs:bn,bw:be))
            end if
            if(ndim.eq.4)then
                var(i,:,:,:,:) = short2flt(f[i]->$varname$(:,:,bs:bn,bw:be))
            end if
            if(ndim.eq.5)then
                var(i,:,:,:,:,:) = short2flt(f[i]->$varname$(:,:,:,bs:bn,bw:be))
            end if
        end do
    else
        if(ndim.eq.2)then
            var = f[:]->$varname$(bs:bn,bw:be)
        end if
        if(ndim.eq.3)then
            var = f[:]->$varname$(:,bs:bn,bw:be)
        end if
        if(ndim.eq.4)then
            var = f[:]->$varname$(:,:,bs:bn,bw:be)
        end if
        if(ndim.eq.5)then
            var = f[:]->$varname$(:,:,:,bs:bn,bw:be)
        end if
    end if

    dims := dimsizes(var)
    ndim = dimsizes(dims)
    if(dims(1).eq.1)then ;; remove only 1 gird dim, maybe level
        if(ndim.eq.4)then
            return var(:,0,:,:)
        end if
        if(ndim.eq.5)then
            return var(:,0,:,:,:)
        end if
    end if
    return var
end

undef("read_partial_file_by_2dmask")
function read_partial_file_by_2dmask(f,varname[1]:string,i2dmask[*][*])
local i
begin
    ;; read only part of variable from file list
    ;; f = list of files with addfiles()

    if(isnumeric(i2dmask))then
        l2dmask = i2dmask .ge.1
    end if
    if(islogical(i2dmask))then
        l2dmask = i2dmask
    end if

    dims = getfilevardimsizes(f[0],varname)
    ndim = dimsizes(dims)
    if(any(dims(ndim-2:).ne.dimsizes(l2dmask)))then ;; rightmost 2 dims
        print("read_partial_file_by_2dmask(): i2dmask is not match to file "+varname)
        exit
    end if

    ;; get minium square of l2dmask
    i = ind_resolve(ind(ndtooned(l2dmask)),dimsizes(l2dmask))
    bs = min(i(:,0))
    bn = max(i(:,0))
    bw = min(i(:,1))
    be = max(i(:,1))

    var = read_partial_file_by_indbox(f,varname,bs,bn,bw,be)

    ;; mask out the other than needs
    var = where(conform(var,l2dmask(bs:bn,bw:be),(/ndim-2,ndim-1/)),var,var@_FillValue)
    ;; lat2d and lon2d
    return var
end

undef("read_all_files_var")
function read_all_files_var(fns[*]:string,varname[1]:string,ocngridfile[1]:string) ;; took too much ram, should be modify.
begin
    ;; assume one file per member
    ;;     not used in forecast dirs
    ;; read all var in filenames(fns)
    ;; will add a dim to left as members(fns)
    ;; assume var in fns are same dimsizes
    ;; so daily data may not useful (unless read all Jan etc.)
    ;; ocngridfile is necessary when read mpiom data

    nmem = dimsizes(fns)

    ;; get var dims
    f = addfile(fns(0),"r")
    dims = getfilevardimsizes(f,varname)
    alldims = array_append_record(nmem,dims,0)
    nalldim = dimsizes(alldims)

    ;; create var for all members
    vartype = getfilevartypes(f,varname)
    varall = new(alldims,where(vartype.eq."short","float",vartype))

    ;; read them 
    do i = 0, nmem-1
        ;;print(fns(i)+"")
        f = addfile(fns(i),"r")
        var1t = f->$varname$
        if(vartype.eq."short")then ;; extract var from scale and offset
            var1 = short2flt(var1t)
        else
            var1 = var1t
        end if
        delete(var1t)

        ;; assign to varall, the coordinate should be assign automatically
        if(nalldim.eq.5)then ;; (member,t,z,y,x)
            varall(i,:,:,:,:) = var1
        end if
        if(nalldim.eq.4)then ;; (member,t,y,x)
            varall(i,:,:,:) = var1
        end if
        if(nalldim.eq.3)then ;; (member,y,x)
            varall(i,:,:) = var1
        end if
        if(nalldim.eq.2)then ;; (member,t)
            varall(i,:) = var1
        end if
        delete(var1)
    end do
    varall!0 = "members"

    assign_ocn_grid(varall,ocngridfile)
    return varall
end

undef("read_norcpm_forecast_members_var_season_latbe_lonbe") 
function read_norcpm_forecast_members_var_season_latbe_lonbe(forecastdir[1],component,varname,months,latbe,lonbe,ocngridfile)
begin
    ;; read members in forecastdir
    memberdirs = systemfunc("ls -d "+forecastdir+"/*mem??")
    nmember = dimsizes(memberdirs)
    fns = ls_monthly_season_nc_files(memberdirs(0),component,months)
    varatts  = get_file_latlon2d(fns(0),varname,ocngridfile)
    l2dmask = mask_with_latbe_lonbe(varatts@lat2d,varatts@lon2d,latbe,lonbe)
    fs = addfiles(fns,"r")
    var1m = read_partial_file_by_2dmask(fs,varname,l2dmask)

    if(typeof(var1m).eq."short")then
        var1mf = short2flt(var1m) ;; apply add_offset and scale_factor
        delete(var1m)
        var1m = var1mf ;; apply add_offset and scale_factor
        delete(var1mf)
        delete(var1m@valid_range)
        ;delete(var1m@actural_range)
    end if
    dim1m = dimsizes(var1m)
    ndim1 = dimsizes(dim1m)

    varall = conform_dims(array_append_record(nmember,dim1m,0),var1m,ispan(1,ndim1,1))
    delete(fns)
    delete(var1m)
    delete(fs)

    ;; read other members
    do i = 1, nmember-1
        fns = ls_monthly_season_nc_files(memberdirs(i),component,months)
        if(any(ismissing(fns)))then
            print("read_all_forecast_members_var(): no data file in "+memberdirs(i))
            exit
        end if

        fs = addfiles(fns,"r")
        var1m = read_partial_file_by_2dmask(fs,varname,l2dmask)
        if(typeof(var1m).eq."short")then
            var1mf = short2flt(var1m) ;; apply add_offset and scale_factor
            delete(var1m)
            var1m = var1mf
            delete(var1mf)
            delete(var1m@valid_range)
            ;delete(var1m@actural_range)
        end if
        if(any(dim1m.ne.dimsizes(var1m)))then
            print("dims mismatch in "+memberdirs(i))
            print("varall: "+str_join(dimsizes(varall),","))
            print("var1m: "+str_join(dimsizes(var1m),","))
        end if

        if(ndim1.eq.3)then ;; t,y,x
            varall(i,:,:,:) = var1m
        end if
        if(ndim1.eq.4)then ;; time,lev,y,x
            varall(i,:,:,:,:) = var1m
        end if

        delete(fns)
        delete(var1m)
    end do

    ;; assign lat2d/lon2d
    bnd = ind_resolve(ind(ndtooned(l2dmask)),dimsizes(l2dmask))
    bs = min(bnd(:,0))
    bn = max(bnd(:,0))
    bw = min(bnd(:,1))
    be = max(bnd(:,1))
    lat2d = varatts@lat2d
    lon2d = varatts@lon2d
    area2d = varatts@area2d
    varall@lat2d := lat2d(bs:bn,bw:be)
    varall@lon2d := lon2d(bs:bn,bw:be)
    varall@area2d := area2d(bs:bn,bw:be)

    varall!0 = "member"
    varall&member = ispan(1,nmember,1)

    return varall
end
undef("read_norcpm_forecast_members_var_season_latbe_lonbe_yearly") 
function read_norcpm_forecast_members_var_season_latbe_lonbe_yearly(forecastdir[1],component,varname,months,latbe,lonbe,ocngridfile)
begin
    ;; front end of read_norcpm_forecast_members_var_season_latbe_lonbe()
    ;; read monthly and convert to yearly(seaonally)
    var = read_norcpm_forecast_members_var_season_latbe_lonbe(forecastdir,component,varname,months,latbe,lonbe,ocngridfile)
        ;; member,month,(z),y,x
    nm = dimsizes(months)
    if(nm.eq.1)then
        return var
    end if

    dims = dimsizes(var)
    dims(1) = dims(1)/nm ;; year coordinate

    varyr = new(dims,typeof(var))
    ndim = dimsizes(dims)
    time = var&time
    do y = 0, dims(1)-1
        i1 = y*nm
        i2 = y*nm+nm-1
        if(ndim.eq.4)then
            varyr(:,y,:,:) = dim_avg_n_Wrap(var(:,i1:i2,:,:),1)
        end if
        if(ndim.eq.5)then
            varyr(:,y,:,:,:) = dim_avg_n_Wrap(var(:,i1:i2,:,:,:),0)
        end if
    end do
    varyr!1 = "time"
    varyr&time = time(::nm)
    return varyr
end

undef("read_norcpm_forecast_members_var_latbe_lonbe") 
function read_norcpm_forecast_members_var_latbe_lonbe(forecastdir[1],component,varname,latbe,lonbe,ocngridfile)
begin
    return read_norcpm_forecast_members_var_season_latbe_lonbe(forecastdir,component,varname,ispan(1,12,1),latbe,lonbe,ocngridfile)
end
undef("read_norcpm_forecast_members_var_ts_latbe_lonbe") 
function read_norcpm_forecast_members_var_ts_latbe_lonbe(forecastdir[1],component,varname,latbe,lonbe,ocngridfile)
begin
    ;; read time series
    a = read_norcpm_forecast_members_var_latbe_lonbe(forecastdir,component,varname,latbe,lonbe,ocngridfile)
    return mean_with_latbe_lonbe(a,latbe,lonbe)
end
undef("read_norcpm_forecast_members_var_ts_season_latbe_lonbe") 
function read_norcpm_forecast_members_var_ts_season_latbe_lonbe(forecastdir[1],component,varname,months,latbe,lonbe,ocngridfile)
begin
    ;; read time series
    ;; return members,time
    a = read_norcpm_forecast_members_var_season_latbe_lonbe(forecastdir,component,varname,months,latbe,lonbe,ocngridfile)
    return mean_with_latbe_lonbe(a,latbe,lonbe)
end
undef("read_norcpm_forecast_members_var_ts_season_latbe_lonbe_yearly") 
function read_norcpm_forecast_members_var_ts_season_latbe_lonbe_yearly(forecastdir[1],component,varname,months,latbe,lonbe,ocngridfile)
begin
    ;; read time series
    ts_mon = read_norcpm_forecast_members_var_ts_season_latbe_lonbe(forecastdir,component,varname,months,latbe,lonbe,ocngridfile)
    nm = dimsizes(months)
    if(nm.eq.1)then
        return ts_mon
    end if

    dims = dimsizes(ts_mon)
    nt = dims(1)
    if(nt%nm .ne.0)then
        print("read_norcpm_forecast_members_var_ts_season_latbe_lonbe_yearly(): something wrong, must check it")
        exit
    end if

    ny = nt/nm
    yrts = new((/dims(0),ny/),typeof(ts_mon))
    time = ts_mon&time
    yrtime = time(::nm)
    do mem = 0, dims(0)-1
    do y = 0,ny-1
        yrts(mem,y) = avg(ts_mon(mem,y*nm:y*nm+nm-1)) ;; unweight averaging
    end do
    end do
    copy_VarAtts(ts_mon,yrts)
    yrts!1 = "time"
    yrts&time = yrtime
    
    return yrts
end

undef("read_norcpm_forecast_members_var")
function read_norcpm_forecast_members_var(forecastdir[1],component,varname,ocngridfile)
begin
    ;; read members in forecastdir
    memberdirs = systemfunc("ls -d "+forecastdir+"/*mem??")
    nmember = dimsizes(memberdirs)
    fns = ls_monthly_nc_files(memberdirs(0),component)
    fs = addfiles(fns,"r")
    var1m = fs[:]->$varname$
    if(typeof(var1m).eq."short")then
        var1mf = short2flt(var1m) ;; apply add_offset and scale_factor
        delete(var1m)
        var1m = var1mf
        delete(var1mf)
        delete(var1m@valid_range)
        ;delete(var1m@actural_range)
    end if
    dim1m = dimsizes(var1m)
    ndim1 = dimsizes(dim1m)

    varall = conform_dims(array_append_record(nmember,dim1m,0),var1m,ispan(1,ndim1,1))
    delete(fns)
    delete(var1m)
    delete(fs)

    ;; read other members
    do i = 1, nmember-1
        fns = ls_monthly_nc_files(memberdirs(i),component)
        if(any(ismissing(fns)))then
            print("read_all_forecast_members_var(): no data file in "+memberdirs(i))
            exit
        end if

        fs = addfiles(fns,"r")
        var1m = fs[:]->$varname$
        if(typeof(var1m).eq."short")then
            var1mf = short2flt(var1m) ;; apply add_offset and scale_factor
            delete(var1m)
            var1m = var1mf
            delete(var1mf)
            delete(var1m@valid_range)
            ;delete(var1m@actural_range)
        end if
        if(any(dim1m.ne.dimsizes(var1m)))then
            print("dims mismatch in "+memberdirs(i))
            print("varall: "+str_join(dimsizes(varall),","))
            print("var1m: "+str_join(dimsizes(var1m),","))
        end if

        if(ndim1.eq.3)then ;; t,y,x
            varall(i,:,:,:) = var1m
        end if
        if(ndim1.eq.4)then ;; time,lev,y,x
            varall(i,:,:,:,:) = var1m
        end if

        delete(fns)
        delete(var1m)
    end do

    return varall
end
undef("read_norcpm_forecasts_members_var")
function read_norcpm_forecasts_members_var(forecastdirs,component,varname,ocngridfile)
begin
    ;; read all forecasts and members
    ;; 
    ncast = dimsizes(forecastdirs)
    
    ;; read 1st members for dims
    fore1 = read_norcpm_forecast_members_var(forecastdirs(0),component,varname,ocngridfile)
    dims1 = dimsizes(fore1) ;; member,y,x or member,lev,y,x
    ndim1 = dimsizes(dims1)
    if(.not.any(ndim1.eq.(/4,5/)))then
        print("read_norcpm_forecasts_members_var(): ndim1 is not support: "+ndim1)
        print("forecastdirs(0): "+forecastdirs(0))
        exit
    end if

    varall = conform_dims(array_append_record(ncast,dims1,0),fore1,ispan(1,ndim1,1))
    delete(fore1)

    ;; read other forecasts
    do i = 1, ncast-1
        fore1 = read_norcpm_forecast_members_var(forecastdirs(i),component,varname,ocngridfile)
        if(ndim1.eq.4)then ;; forecast,members,time,y,x
            varall(i,:,:,:,:) = fore1
        end if
        if(ndim1.eq.5)then ;; forecast,members,time,lev,y,x
            varall(i,:,:,:,:,:) = fore1
        end if

        delete(fore1)
    end do

    if(component.eq."ocn")then
        assign_ocn_grid(varall,ocngridfile)
    end if
    return varall
end

undef("mod_date_and_to_cd_")
function mod_date_and_to_cd_(time,component,opt)
begin
    ;; since atm save monthly hist data at next month 
    ;;  ie. time coordinate is 1990-02-01-0000 in 1990-01 file
    tt = time
    if(component.eq."atm")then
        tt = time-1
    end if
    return cd_calendar(tt,opt)
end
undef("read_noresm_members_filevar_latlon_leadmonths")
function read_noresm_members_filevar_latlon_leadmonths(dirs,component,vn,lead_months,latbe,lonbe,ocngridfile)
begin
    ;; dirs is memberdirs
    ;; read var in member dirs with lead_months and latlon box
    ;; return varall(members, months,lev,y,x)

    ;; lead_months=1 .and. start_ym=198610 => read months=198611
    ;;                                        dmonths    =    +1
    ;; lead_months=4 .and. start_ym=198610 => read months=198702
    ;;                                        dmonths    =    +4
    ;; lead_months=0 .and. start_ym=198610 => read months=198610
    ;;                                        dmonths    =    +0
    ;; assume one time per file
    if(any(ismissing(dirs)))then
        print("read_noresm_members_filevar_latlon_leadmonths(): dir is missing")
        return
    end if
    nmember = dimsizes(dirs)

    monfix=""
    if(component.eq."ocn")then
        monfix="hm"
    end if
    if(component.eq."atm")then
        monfix="h0"
    end if


    ;; check first data file name in all memebers
    if (False)then ;; bad idea, obsolated
        fn = systemfunc("ls "+dirs(0)+"/"+component+"/hist/*"+monfix+"*.nc|sort|head -n1")
        if(ismissing(fn))then
            print("read_noresm_members_filevar_latlon_leadmonths(): no file in "+dirs(0))
            print("cmd: ls "+dirs(0)+"/"+component+"/hist/*"+monfix+"*.nc|sort|head -n1")
        end if
        f = addfile(fn,"r")
        t0 = f->time
        t0a = mod_date_and_to_cd_(t0,component,0) ;; should be only one value in monthly data
        t0units = t0@units
        delete(f)
    end if
    ;; get start date from dirname
    fn = get_start_date_ncfn_from_dirname(dirs(0),component)
    f = addfile(fn,"r")
    t0 = f->time
    t0a = mod_date_and_to_cd_(t0,component,0) ;; should be only one value in monthly data
    t0units = t0@units
    delete(f)

    ;; get 2d mask
    varatts  = get_file_latlon2d(fn,vn,ocngridfile)
    l2dmask = mask_with_latbe_lonbe(varatts@lat2d,varatts@lon2d,latbe,lonbe)

    t0change = False
    do i = 1,nmember-1
        fn = get_start_date_ncfn_from_dirname(dirs(i),component)
        if(ismissing(fn))then
            print("read_noresm_members_filevar_latlon_leadmonths(): file missing at "+dirs(i)+" "+component)
            exit
        end if
        f = addfile(fn,"r")
        if(.not.all(t0a.eq.mod_date_and_to_cd_(f->time,component,0)))then
            newt0 = f->time
            if(t0 .lt. newt0)then
                t0change = True
                t0 := newt0
                t0a = mod_date_and_to_cd_(t0,component,0)
            end if
        end if
        delete(f)
    end do
    if(t0change)then
        t0s= t0a(0,0)+"-"+t0a(0,1)
        print("time not contsisant: "+fn)
        print("use "+t0s+" as first month")
    end if

    ;; comfirm  model time to read
    ndmon = dimsizes(lead_months)
    needMM = toint(t0a(0,1))+lead_months
    needYY = needMM*0+toint(t0a(0,0))  ;; create array
    align_years_months(needYY,needMM)
    needYYMMs = needYY+"-"+sprinti("%2.2d",needMM)
    ;print("first member: "+dirs(0)+", total "+nmember)
    ;print("    reading "+needYYMMs)

    
    readTime = new((/nmember,ndmon/),typeof(t0))
    do m = 0, nmember-1
        fns := (/""/)
        do t = 0, ndmon-1
            fns  := array_append_record(fns,systemfunc("ls "+dirs(m)+"/"+component+"/hist/*"+monfix+"."+needYYMMs(t)+".nc"),0)
        end do
        fs = addfiles(fns(1:),"r")
        var1 = read_partial_file_by_2dmask(fs,vn,l2dmask)
        readTime(m,:) = cd_convert(fs[:]->time,t0units)
        if(.not.isvar("varall"))then
            dims1 = dimsizes(var1)
            ndim1 = dimsizes(dims1)
            varall = new(array_append_record(nmember,dims1,0),typeof(var1))
        end if
        if(ndim1.eq.2)then ;; 
            varall(m,:,:) = var1
        end if
        if(ndim1.eq.3)then
            varall(m,:,:,:) = var1
        end if
        if(ndim1.eq.4)then
            varall(m,:,:,:,:) = var1
        end if
        if(ndim1.eq.5)then
            varall(m,:,:,:,:,:) = var1
        end if
        delete(var1)
    end do

    ;; check read time
    do t = 0, ndmon-1
        if (.not. all(readTime(:,t).eq.readTime(0,t)))then
            print("read_noresm_members_leadseason(): read time wrong")
            ;print(readTime)
            do m = 0, nmember-1
                fn := systemfunc("ls "+dirs(m)+"/"+component+"/hist/*"+monfix+"."+needYYMMs(t)+".nc")
                print(""+fn)
            end do
        end if
    end do

    ;; assign coordinate
    varall!0 = "member"
    varall&member = ispan(1,nmember,1)
    varall!1 = "time"
    varall&time = readTime(0,:)
    varall@t0 = t0
    varall@t0units = varall&time@units
    varall@readMM = needMM
    varall@readYY = needYY
    ;; assign grid if ocn grid
    varall@mask2d = l2dmask
    assign_ocn_grid(varall,ocngridfile)
    
    return varall
end
load "/tos-project4/SCRATCH/pgchiu/diag_norcpm/Codes/func_ohc_integrate.ncl" ;; bad idea, need modify
undef("read_noresm_members_latlon_leadmonths")
function read_noresm_members_latlon_leadmonths(forecastDirs,component,vn,lead_months,latbe,lonbe,ocngridfile)
begin
    ;;  frontend of read_noresm_members_filevar_latlon_leadmonths(),
    ;;      used to insert varnames which need to calcute, not just in file
    if(vn.eq."ohc")then ;; for ocean heat content
        ;; read templvl and salnlvl
        templvl = read_noresm_members_filevar_latlon_leadmonths(forecastDirs,component,"templvl",lead_months,latbe,lonbe,ocngridfile)
        salnlvl = read_noresm_members_filevar_latlon_leadmonths(forecastDirs,component,"salnlvl",lead_months,latbe,lonbe,ocngridfile)
        return cal_ohc_with_temp_salinity_MTZLL(templvl,salnlvl,100)
    end if

    a = read_noresm_members_filevar_latlon_leadmonths(forecastDirs,component,vn,lead_months,latbe,lonbe,ocngridfile)
    return a
end
undef("read_noresm_members_leadseason")
function read_noresm_members_latlon_leadseason(dirs,component,vn,lead_season,latbe,lonbe,ocngridfile)
begin
    ;; read var in member dirs with lead_season
    ;; return varall(members, months,lev,y,x)

    ;; lead_season=1 .and. start_ym=198610 => read months=198611,198612,198701
    ;;                                        dmonths    =    +1     +2     +3
    ;; lead_season=2 .and. start_ym=198610 => read months=198702,198703,198704
    ;;                                        dmonths    =    +4     +5     +6
    ;; assume one time per file

    dmonths  = (/1,2,3/) +((lead_season-1)*3)
    return read_noresm_members_latlon_leadmonths(dirs,component,vn,dmonths,latbe,lonbe,ocngridfile)
end

undef("read_noresm_forecasts_members_latlon_leadmonths")
function read_noresm_forecasts_members_latlon_leadmonths(forecastDirs,component,vn,lead_months,latbe,lonbe,ocngridfile)
begin
    ;; read forecasts in noresm forecast members
    ;; forecastDirs are directories contain forecast members subdir
    ;; ex. forecastDirs(0)+"/"+memberDirs(0)+"/ocn/hist/"+ncfile

    ;; debug check
    if(isatt(forecastDirs,"check_month"))then
        checkMonth = forecastDirs@check_month
    else
        checkMonth = True
    end if
    ;; read data
    nforecast = dimsizes(forecastDirs)
    ;;;; 1st forecast
    memDirs = systemfunc("ls -d "+forecastDirs(0)+"/*")
    if(any(ismissing(memDirs)))then
        print("read_noresm_forecasts_members_latlon_leadmonths(): memDirs missing")
        print("cmd: "+"ls -d "+forecastDirs(0)+"/*")
        return
    end if
    ;;;; check memDirs (TBD)
    ;;;; read first forecast
    varF1 = read_noresm_members_latlon_leadmonths(memDirs,component,vn,lead_months,latbe,lonbe,ocngridfile)
    t0all = varF1@t0
    t0all@units = varF1@t0units
    dims1 = dimsizes(varF1)
    dims = array_append_record(nforecast,dims1,0) 
    ndim = dimsizes(dims)
    varall = conform_dims(dims,varF1,ispan(1,ndim-1,1)) ;; f,m,dmon,z,y,x or f,m,dmon,y,x
    varall(0,:,:,:,:) = varF1
    readMM = varF1@readMM ;; the read months of var
    sameReadMM = True

    copy_VarAtts(varF1,varall)
    delete(varF1)
    delete(memDirs)
    
    ;actual_range = varall@actual_range
    ;vaild_range = varall@vaild_range
    do f = 1,nforecast-1
        memDirs = systemfunc("ls -d "+forecastDirs(f)+"/*")
        varF1 = read_noresm_members_latlon_leadmonths(memDirs,component,vn,lead_months,latbe,lonbe,ocngridfile)
        ;; check read months
        if(checkMonth .and. any(readMM.ne.varF1@readMM))then
            print("readMM is not consistant, maybe t0 is not at same month?")
            print("1st  readMM: "+str_join(readMM,","))
            print("this readMM: "+str_join(varF1@readMM,","))
            sameReadMM = False
        end if
        dims1 := dimsizes(varF1)
        if(dims1(0) .ne. dims(1))then
            print("read_noresm_forecasts_members_latlon_leadmonths(): member number is not consistant at "+forecastDirs(f))
            print("    use first "+dims(1)+" members.")
        end if
            ;; actural_range and valid_range
            ;if(isatt(varF1,"actual_range"))then
            ;    actual_range(0) := min((/varF1@actual_range(0),actual_range(0)/))
            ;    actual_range(1) := max((/varF1@actual_range(1),actual_range(1)/))
            ;end if
            ;if(isatt(varF1,"valid_range"))then
            ;    valid_range(0) := min((/varF1@valid_range(0),valid_range(0)/))
            ;    valid_range(1) := max((/varF1@valid_range(1),valid_range(1)/))
            ;end if
        if(ndim.eq.6);then
            varall(f,:,:,:,:,:) = varF1(:dims(1)-1,:,:,:,:)
        end if
        if(ndim.eq.5);then
            varall(f,:,:,:,:) = varF1(:dims(1)-1,:,:,:) ;; if member number is not consistant
        end if
        if(ndim.eq.4);then
            varall(f,:,:,:) = varF1(:dims(1)-1,:,:)
        end if
        t0all := array_append_record(t0all,varF1@t0,0)
        delete(varF1)
        delete(memDirs)
    end do
    t0all@calendar = "noleap"
    varall!0 = "forecast"
    varall&forecast = t0all
    if(sameReadMM)then
        varall@readMM = readMM
    else
        delete(varall@readMM)
    end if
    delete(varall@readYY)
    delete(varall@t0)
    delete(varall@t0units)

    ;varall@actural_range = actural_range
    ;varall@valid_range = valid_range
    return varall
end


undef("read_noresm_forecasts_ens_latlon_leadmonths")
function read_noresm_forecasts_ens_latlon_leadmonths(forecastDirs,component,vn,lead_months,latbe,lonbe,ocngridfile)
begin
    ;; read ensemble mean
    ;; smaller memory usage
    nm = dimsizes(lead_months)
    var1m = read_noresm_forecasts_members_latlon_leadmonths(forecastDirs,component,vn,lead_months(0),latbe,lonbe,ocngridfile)
        ;; forecast, member, time, [lev,] lat, lon
    varens1m = dim_avg_n_Wrap(var1m,1)
    dims = dimsizes(varens1m)
    dims(1) = nm ;; num of lead months
    ;ensall = conform_dims(dims,varens1m,(/0,2,3/)) ;; assume [forecast, time, lat, lon]
    ;printVarSummary(varens1m)
    ensall = new(dims,typeof(varens1m))
    ensall(:,0,:,:) = varens1m
    delete(var1m)
    delete(varens1m)
    do m = 1, nm-1
        var1m = read_noresm_forecasts_members_latlon_leadmonths(forecastDirs,component,vn,lead_months(m),latbe,lonbe,ocngridfile)
        varens1m = dim_avg_n_Wrap(var1m,1)
        ensall(:,m,:,:) = varens1m ;; assume [forecast, time, lat, lon]
        delete(var1m)
        delete(varens1m)
    end do
    if(isatt(ensall,"valid_range"))then
        delete(ensall@valid_range)
    end if
    if(isatt(ensall,"actural_range"))then
        delete(ensall@actural_range)
    end if
    return ensall
end


    undef("obsolete_read_noresm_forecasts_members_leadseason") ;; wait to be obsoleted using read_noresm_forecasts_members_leadmonths()
    function obsolete_read_noresm_forecasts_members_leadseason(forecastDirs,component,vn,lead_season,ocngridfile)
    begin
        ;; read forecasts in noresm forecast members
        ;; forecastDirs are directories contain forecast members subdir
        ;; ex. forecastDirs(0)+"/"+memberDirs(0)+"/ocn/hist/"+ncfile

        lead_months = (lead_season-1)*3 +(/1,2,3/)
        return read_noresm_forecasts_members_leadmonths(forecastDirs,component,vn,lead_months,ocngridfile)
        if(False)then ;; obsolete
            ;; read data
            nforecast = dimsizes(forecastDirs)
            ;;;; 1st forecast
            memDirs = systemfunc("ls -d "+forecastDirs(0)+"/*")
            ;;;; check memDirs (TBD)
            ;;;; read first forecast
            varF1 = read_noresm_members_leadseason(memDirs,component,vn,lead_season,ocngridfile)
            t0all = varF1@t0
            t0all@units = varF1@t0units
            dims1 = dimsizes(varF1)
            dims = array_append_record(nforecast,dims1,0) 
            ndim = dimsizes(dims)
            varall = conform_dims(dims,varF1,ispan(1,ndim-1,1)) ;; f,m,dmon,z,y,x or f,m,dmon,y,x
            readMM = varF1@readMM ;; the read months of var
            sameReadMM = True

            delete(varF1)
            delete(memDirs)
            
            ;actual_range = varall@actual_range
            ;vaild_range = varall@vaild_range
            do f = 1,nforecast-1
                memDirs = systemfunc("ls -d "+forecastDirs(f)+"/*")
                varF1 = read_noresm_members_leadseason(memDirs,component,vn,lead_season,ocngridfile)
                ;; check read months
                if(any(readMM.ne.varF1@readMM))then
                    print("readMM is not consistant, maybe t0 is not at same month?")
                    print("1st  readMM: "+str_join(readMM,","))
                    print("this readMM: "+str_join(varF1@readMM,","))
                    sameReadMM = False
                end if
                ;if(isatt(varF1,"actual_range"))then
                ;    actual_range(0) := min((/varF1@actual_range(0),actual_range(0)/))
                ;    actual_range(1) := max((/varF1@actual_range(1),actual_range(1)/))
                ;end if
                ;if(isatt(varF1,"valid_range"))then
                ;    valid_range(0) := min((/varF1@valid_range(0),valid_range(0)/))
                ;    valid_range(1) := max((/varF1@valid_range(1),valid_range(1)/))
                ;end if
                if(ndim.eq.6);then
                    varall(f,:,:,:,:,:) = varF1
                end if
                if(ndim.eq.5);then
                    varall(f,:,:,:,:) = varF1
                end if
                t0all := array_append_record(t0all,varF1@t0,0)
                delete(varF1)
                delete(memDirs)
            end do
            t0all@calendar = "noleap"
            varall!0 = "forecast"
            varall&forecast = t0all
            if(sameReadMM)then
                varall@readMM = readMM
            else
                delete(varall@readMM)
            end if
            delete(varall@readYY)
            delete(varall@t0)
            delete(varall@t0units)

            ;varall@actural_range = actural_range
            ;varall@valid_range = valid_range
            return varall
        end if
    end


    undef("obsolete_read_noresm_members_leadseason") ;; replaced since read_noresm_members_leadmonths() applied
    function obsolete_read_noresm_members_leadseason(dirs,component,vn,lead_season,ocngridfile)
    begin 
        ;; read var in member dirs with lead_season
        ;; return varall(members, months,lev,y,x)

        ;; lead_season=1 .and. start_ym=198610 => read months=198611,198612,198701
        ;;                                        dmonths    =    +1     +2     +3
        ;; lead_season=2 .and. start_ym=198610 => read months=198702,198703,198704
        ;;                                        dmonths    =    +4     +5     +6
        ;; assume one time per file

        nmember = dimsizes(dirs)

        monfix=""
        if(component.eq."ocn")then
            monfix="hm"
        end if
        if(component.eq."atm")then
            monfix="h0"
        end if

        ;; check first data file name in all memebers
        if(False)then ;; bad idea, obsolete
            fn = systemfunc("ls "+dirs(0)+"/"+component+"/hist/*"+monfix+"*.nc|sort|head -n1")
            if(ismissing(fn))then
                print("read_noresm_members_leadseason(): no file in "+dirs(0))
                print("cmd: ls "+dirs(0)+"/"+component+"/hist/*"+monfix+"*.nc|sort|head -n1")
            end if
            f = addfile(fn,"r")
            t0 = f->time
            t0a = mod_date_and_to_cd_(t0,component,0) ;; should be only one value in monthly data
            delete(f)
        end if
        print(dirs(0))
        print("see func_read_all_members.ncl about line 882")
        exit

        t0change = False
        do i = 1,nmember-1
            fn = systemfunc("ls "+dirs(i)+"/"+component+"/hist/*"+monfix+"*.nc|sort|head -n1")
            f = addfile(fn,"r")
            if(.not.all(t0a.eq.mod_date_and_to_cd_(f->time,component,0)))then
                newt0 = f->time
                if(t0 .lt. newt0)then
                    t0change = True
                    t0 := newt0
                    t0a = mod_date_and_to_cd_(t0,component,0)
                end if
            end if
            delete(f)
        end do
        if(t0change)then
            t0s= t0a(0,0)+"-"+t0a(0,1)
            print("time not contsisant: "+fn)
            print("use "+t0s+" as first month")
        end if

        ;; parse forecast months(season) to read
        dmonths  = (/1,2,3/) +((lead_season-1)*3)
        if(component.eq."atm")then ;; wired time coordinate in atm(month+1)
            if(t0a(0,2).eq.1 .and.t0a(0,3).eq.0.and.t0a(0,4).eq.0)then
                dmonths = dmonths-1
            else
                print("check time coordinate in "+dir(0))
            end if
        end if
        ndmon = dimsizes(dmonths)
        needMM = toint(t0a(0,1))+dmonths
        needYY = needMM*0+toint(t0a(0,0))
        needYY = where(needMM.gt.12,needYY+1,needYY)
        needMM = where(needMM.gt.12,needMM-12,needMM)
        needYYMMs = needYY+"-"+sprinti("%2.2d",needMM)
        delete(dmonths)
        
        ;; create var for all members
        fn = systemfunc("ls "+dirs(0)+"/"+component+"/hist/*"+monfix+"."+needYYMMs(0)+".nc")
        f = addfile(fn,"r")
        vartype = getfilevartypes(f,vn)
        dims1 = getfilevardimsizes(f,vn)

        dims1(0) = ndmon ;; set t as dmonth
        varall = new(array_append_record(nmember,dims1,0),where(vartype.eq."short","float",vartype))
        ndim = dimsizes(dims1) +1 ;; ndim of varall

        readTime = new((/nmember,ndmon/),typeof(t0))
        ;; read data
        do m = 0, nmember-1
        do t = 0, ndmon-1
            fn = systemfunc("ls "+dirs(m)+"/"+component+"/hist/*"+monfix+"."+needYYMMs(t)+".nc")
            f = addfile(fn,"r")
            readTime(m,t) = f->time
            if(vartype.eq."short")then
                var1 = short2flt(f->$vn$)
            else
                var1 = f->$vn$
            end if

            if(ndim.eq.5)then ;; member,t=dmonth,z,y,x
                varall(m,t,:,:,:) = var1(0,:,:,:) ;; one time per file
            end if
            if(ndim.eq.4)then ;; member,t=dmonth,y,x
                varall(m,t,:,:) = var1(0,:,:) ;; one time per file
            end if
            delete(f)
            delete(var1)
        end do
        end do

        ;; check read time
        do t = 0, ndmon-1
            if (.not. all(readTime(:,t).eq.readTime(0,t)))then
                print("read_noresm_members_leadseason(): read time wrong")
                print(readTime)
            end if
        end do

        ;; assign coordinate
        varall!0 = "member"
        varall&member = ispan(1,nmember,1)
        varall!1 = "time"
        varall&time = readTime(0,:)
        varall@t0 = t0
        varall@t0units = varall&time@units
        varall@readMM = needMM
        varall@readYY = needYY
        ;; assign grid if ocn grid
        assign_ocn_grid(varall,ocngridfile)
        
        return varall
    end

ocngridfile = "~/scratch/diag_norcpm/Data/grid.nc"
fds = systemfunc("ls -d /tos-project4/NS9039K/shared/norcpm/cases/NorCPM/NorCPM_V1c/ana_19800115_me_hindcasts/ana_19800115_me_dec_*")
fd = "/tos-project4/NS9039K/shared/norcpm/cases/NorCPM/NorCPM_V1c/ana_19800115_me_hindcasts/ana_19800115_me_dec_20151015"
mds = systemfunc("ls -d /tos-project4/NS9039K/shared/norcpm/cases/NorCPM/NorCPM_V1c/ana_19800115_me_hindcasts/ana_19800115_me_dec_20151015/ana_19800115_me_dec_20151015_mem*")
;a = read_norcpm_forecast_members_var_ts_latbe_lonbe(fd,"ocn","sst",(/-5,5/),(/-150,-90/),ocngridfile)
;a = read_norcpm_forecast_members_var_season_latbe_lonbe(fd,"ocn","sst",(/6,7,8/),(/-5,5/),(/-150,-90/),ocngridfile)
;a = read_norcpm_forecast_members_var_season_latbe_lonbe(fd,"ocn","sst",(/12,13,14/),(/-5,5/),(/-150,-90/),ocngridfile)
;a = read_norcpm_forecast_members_var_ts_season_latbe_lonbe_yearly(fd,"ocn","sst",(/12,13,14/),(/-5,5/),(/-150,-90/),ocngridfile)
;print(cd_calendar(a&time,-2))
;a = read_noresm_members_filevar_latlon_leadmonths(mds,"ocn","sst",(/1,2,3,4/),(/-5,5/),(/-150,-90/),ocngridfile)
;a = read_noresm_forecasts_ens_latlon_leadmonths(fds,"ocn","sst",(/1,2,3,4/),(/-5,5/),(/-150,-90/),ocngridfile)

;printVarSummary(a)
