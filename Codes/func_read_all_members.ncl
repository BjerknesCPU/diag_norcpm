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
        var@lat2d = lat
        var@lon2d = lon
        var@area2d = area
    end if
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
    var = getfilevaratts(f,varname)
    if(isatt(var,"coordinates"))then ;; ocn data
        assign_ocn_grid(var,ocngridfile)
        return var
    end if
    ;; atm data, lat/lon
    lat = f->lat
    lon = f->lon
    dims = getfilevardimsizes(f,varname)
    ndim = dimsizes(dims)
    lat2d = conform_dims(dims,lat,ndim-2)
    lon2d = conform_dims(dims,lon,ndim-1)
    var@lat2d = lat2d
    var@lon2d = lon2d
    return var
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

undef("ls_monthly_nc_files")
function ls_monthly_nc_files(path,component)
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

    ;; normally the data is not gzipped or postprocessed
    fns = systemfunc("ls "+path+"/"+component+"/hist/*"+monfix+"*.nc|sort|head -n13") ;; only 13 month data, bad idea
    if(.not.any(ismissing(fns)))then
        return fns
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

undef("read_partial_file_list_by_2dmask")
function read_partial_file_list_by_2dmask(f,varname[1]:string,i2dmask[*][*])
local i
begin
    ;; read only part of variable from file list

    if(isnumeric(i2dmask))then
        l2dmask = i2dmask .ge.1
    end if
    if(islogical(i2dmask))then
        l2dmask = i2dmask
    end if

    dims = getfilevardimsizes(f[0],varname)
    ndim = dimsizes(dims)
    if(dims(ndim-2:).ne.dimsizes(l2dmask))then
        print("read_partial_file_list_by_2dmask(): i2dmask is not match to file "+varname)
        exit
    end if

    ;; get minium square of l2dmask
    i = ind_resolve(ind(l2dmask),dimsizes(l2dmask))
    bs = min(i(:,0))
    bn = max(i(:,0))
    bw = min(i(:,1))
    be = max(i(:,1))

    ;; read data from file
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

    ;; mask out the other than needs
    var = where(conform(var,l2dmask(bs:bn,bw:be),(/ndim-2,ndim-1/)),var,var@_FillValue)
    ;; lat2d and lon2d
    return var
end

undef("read_all_files_var")
function read_all_files_var(fns[*]:string,varname[1]:string,ocngridfile[1]:string)
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

undef("read_norcpm_forecast_members_var_latbe_lonbe") 
function read_norcpm_forecast_members_var_latbe_lonbe(forecastdir[1],component,varname,latbe,lonbe,ocngridfile)
begin
    ;; read members in forecastdir
    memberdirs = systemfunc("ls -d "+forecastdir+"/*mem??")
    nmember = dimsizes(memberdirs)
    fns = ls_monthly_nc_files(memberdirs(0),component)
    varatts  = get_file_latlon2d(fns(0),varname,ocngridfile)
    l2dmask = .not.ismissing(varatts@lat2d)
    l2dmask = l2dmask .and. (varatts@lat2d .ge. min(latbe)) .and. (varatts@lat2d .le. max(latbe))
    l2dmask = l2dmask .and. (varatts@lon2d .ge. min(lonbe)) .and. (varatts@lon2d .le. max(lonbe))
    fs = addfiles(fns,"r")
    var1m = read_partial_file_by_2dmask(fs,varname,l2dmask)

    if(typeof(var1m).eq."short")then
        var1m := short2flt(var1m) ;; apply add_offset and scale_factor
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
        var1m = read_partial_file_by_2dmask(fs,varname,l2dmask)
        if(typeof(var1m).eq."short")then
            var1m := short2flt(var1m) ;; apply add_offset and scale_factor
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
    bnd = ind_resolve(ind(l2dmask),dimsizes(l2dmask))
    bs = min(bnd(:,0))
    bn = max(bnd(:,0))
    bw = min(bnd(:,1))
    be = max(bnd(:,1))
    varall@lat2d = varatts@lat2d(bs:bn,bw:be)
    varall@lon2d = varatts@lon2d(bs:bn,bw:be)

    return varall
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
        var1m := short2flt(var1m) ;; apply add_offset and scale_factor
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
            var1m := short2flt(var1m) ;; apply add_offset and scale_factor
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
undef("read_noresm_members_filevar_leadmonths")
function read_noresm_members_filevar_leadmonths(dirs,component,vn,lead_months,ocngridfile)
begin
    ;; read var in member dirs with lead_months
    ;; return varall(members, months,lev,y,x)

    ;; lead_months=1 .and. start_ym=198610 => read months=198611
    ;;                                        dmonths    =    +1
    ;; lead_months=4 .and. start_ym=198610 => read months=198702
    ;;                                        dmonths    =    +4
    ;; lead_months=0 .and. start_ym=198610 => read months=198610
    ;;                                        dmonths    =    +0
    ;; assume one time per file
    if(any(ismissing(dirs)))then
        print("read_noresm_members_filevar_leadmonths(): dir is missing")
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
    fn = systemfunc("ls "+dirs(0)+"/"+component+"/hist/*"+monfix+"*.nc|sort|head -n1")
    if(ismissing(fn))then
        print("read_noresm_members_filevar_leadmonths(): no file in "+dirs(0))
        print("cmd: ls "+dirs(0)+"/"+component+"/hist/*"+monfix+"*.nc|sort|head -n1")
    end if
    f = addfile(fn,"r")
    t0 = f->time
    t0a = mod_date_and_to_cd_(t0,component,0) ;; should be only one value in monthly data
    t0units = t0@units
    delete(f)

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

    ;; comfirm  model time to read
    ndmon = dimsizes(lead_months)
    needMM = toint(t0a(0,1))+lead_months
    needYY = needMM*0+toint(t0a(0,0))
    needYY = where(needMM.gt.12,needYY+1,needYY)
    needMM = where(needMM.gt.12,needMM-12,needMM)
    needYYMMs = needYY+"-"+sprinti("%2.2d",needMM)
    
    ;; create var for all members
    fn = systemfunc("ls "+dirs(0)+"/"+component+"/hist/*"+monfix+"."+needYYMMs(0)+".nc")
    f = addfile(fn,"r")
    vartype = getfilevartypes(f,vn)
    dims1 = getfilevardimsizes(f,vn)

    dims1(0) = ndmon ;; set t as dmonth
    ;varall = new(array_append_record(nmember,dims1,0),where(vartype.eq."short","float",vartype))
    varall = new(array_append_record(nmember,dims1,0),where(vartype.eq."short","float",vartype))
    ndim = dimsizes(dims1) +1 ;; ndim of varall

    readTime = new((/nmember,ndmon/),typeof(t0))
    ;; read data
    do m = 0, nmember-1
    do t = 0, ndmon-1
        fn := systemfunc("ls "+dirs(m)+"/"+component+"/hist/*"+monfix+"."+needYYMMs(t)+".nc")
        f = addfile(fn,"r")
        readTime(m,t) = cd_convert(f->time,t0units)
        if(vartype.eq."short")then
            var1 = short2flt(f->$vn$)
        else
            var1 = f->$vn$
        end if
        ;print("read_noresm_members_filevar_leadmonths(): reading "+vn+" in "+fn)
        ;print("    number of missing values: "+num(ismissing(var1)))

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
    assign_ocn_grid(varall,ocngridfile)
    
    return varall
end
load "/tos-project4/SCRATCH/pgchiu/diag_norcpm/Codes/func_ohc_integrate.ncl" ;; bad idea, need modify
undef("read_noresm_members_leadmonths")
function read_noresm_members_leadmonths(forecastDirs,component,vn,lead_months,ocngridfile)
begin
    ;;  frontend of read_noresm_members_filevar_leadmonths(),
    ;;      used to insert varnames which need to calcute, not just in file
    if(vn.eq."ohc")then ;; for ocean heat content
        ;; read templvl and salnlvl
        templvl = read_noresm_members_filevar_leadmonths(forecastDirs,component,"templvl",lead_months,ocngridfile)
        salnlvl = read_noresm_members_filevar_leadmonths(forecastDirs,component,"salnlvl",lead_months,ocngridfile)
        return cal_ohc_with_temp_salinity_MTZLL(templvl,salnlvl,100)
    end if

    return read_noresm_members_filevar_leadmonths(forecastDirs,component,vn,lead_months,ocngridfile)
end
undef("read_noresm_members_leadseason")
function read_noresm_members_leadseason(dirs,component,vn,lead_season,ocngridfile)
begin
    ;; read var in member dirs with lead_season
    ;; return varall(members, months,lev,y,x)

    ;; lead_season=1 .and. start_ym=198610 => read months=198611,198612,198701
    ;;                                        dmonths    =    +1     +2     +3
    ;; lead_season=2 .and. start_ym=198610 => read months=198702,198703,198704
    ;;                                        dmonths    =    +4     +5     +6
    ;; assume one time per file

    dmonths  = (/1,2,3/) +((lead_season-1)*3)
    return read_noresm_members_leadmonths(dirs,component,vn,dmonths,ocngridfile)
end

undef("read_noresm_forecasts_members_leadmonths")
function read_noresm_forecasts_members_leadmonths(forecastDirs,component,vn,lead_months,ocngridfile)
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
        print("read_noresm_forecasts_members_leadmonths(): memDirs missing")
        print("cmd: "+"ls -d "+forecastDirs(0)+"/*")
        return
    end if
    ;;;; check memDirs (TBD)
    ;;;; read first forecast
    varF1 = read_noresm_members_leadmonths(memDirs,component,vn,lead_months,ocngridfile)
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
        varF1 = read_noresm_members_leadmonths(memDirs,component,vn,lead_months,ocngridfile)
        ;; check read months
        if(checkMonth .and. any(readMM.ne.varF1@readMM))then
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
        if(ndim.eq.4);then
            varall(f,:,:,:) = varF1
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

undef("get_var_area_wgt2d")
function get_var_area_wgt_lat_lon_2d(var,whichone)
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
            varcod := ondtond(varcod,dims(ndim-2:)) ;; assume rightmost is lat,lon
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

undef("read_noresm_forecasts_ens_leadmonths")
function read_noresm_forecasts_ens_leadmonths(forecastDirs,component,vn,lead_months,ocngridfile)
begin
    ;; read ensemble mean
    ;; smaller memory usage
    nm = dimsizes(lead_months)
    var1m = read_noresm_forecasts_members_leadmonths(forecastDirs,component,vn,lead_months(0),ocngridfile)
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
        var1m = read_noresm_forecasts_members_leadmonths(forecastDirs,component,vn,lead_months(m),ocngridfile)
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


undef("read_noresm_forecasts_members_leadseason") ;; wait to be obsoleted using read_noresm_forecasts_members_leadmonths()
function read_noresm_forecasts_members_leadseason(forecastDirs,component,vn,lead_season,ocngridfile)
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
        fn = systemfunc("ls "+dirs(0)+"/"+component+"/hist/*"+monfix+"*.nc|sort|head -n1")
        if(ismissing(fn))then
            print("read_noresm_members_leadseason(): no file in "+dirs(0))
            print("cmd: ls "+dirs(0)+"/"+component+"/hist/*"+monfix+"*.nc|sort|head -n1")
        end if
        f = addfile(fn,"r")
        t0 = f->time
        t0a = mod_date_and_to_cd_(t0,component,0) ;; should be only one value in monthly data
        delete(f)

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

