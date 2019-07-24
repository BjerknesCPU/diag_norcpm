procedure reorder_dim_var(var)
begin
    ;; assume time, lat,lon
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

    if (isatt(var,"actual_range"))then ;; actual_range is defined by file
        delete(var@actual_range)
    end if
end

function read_nn9039k_obs_months(obsdir[1]:string,idatadir[1]:string,varname[1]:string,years[*]:integer,months[*]:integer)
begin
    ;; read months of years, ex. y1m1, y2m2, y3m3, y4m4
    ;; obsdir: /cluster/projects/nn9039k/NorCPM/Obs
    ;;  which sould be defined in Defaults.yml
    ;; datadir: SST/HADISST or SST/NOAA ...etc
    ;;  is the relative link to data files

    ;; read monthly sst/sic data on fram
    ;; datadir/YYYY_MM.nc
    ;; ex.
    ;;      /cluster/projects/nn9039k/NorCPM/Obs/SST/NOAA/1981_12.nc
    ;;      /cluster/projects/nn9039k/NorCPM/Obs/SST/HADISST/1870_01.nc
    ;;      /cluster/projects/nn9039k/NorCPM/Obs/SST/HADISST2-1850-2010/2006.nc , ensemble
    ;;
    ny = dimsizes(years)
    nm = dimsizes(months)
    if(ny.ne.nm)then
        print("read_nn9039k_obs_months(): number of years and months should be same. ny/nm: "+ny+"/"+nm)
        exit
    end if

    datadir = obsdir+"/"+idatadir

    ;; check datadir
    ;if(.not. isfilepresent(datadir+"/"+years(0)+"_01.nc"))
    ;    print("read_nn9039k_obs_months(): obs data not found in "+datadir)
    ;    return False
    ;end if

    ;; check data files
    ;;;; file names
    fns = ""
    do i = 0,ny-1
        yyyy_mm = years(i)+"_"+sprinti("%2.2d",months(i))+".nc"
        fns := array_append_record(fns,yyyy_mm,0)
    end do
    fns := fns(1:)

    ;; check filename present
    missingFile = False
    do i = 0, dimsizes(fns)-1
        if(.not.isfilepresent(datadir+"/"+fns(i)))then
            print("missing data file: "+datadir+"/"+fns(i))
            missingFile = True
        end if
    end do
    if(missingFile)then
        print("data file(s) not found.")
        return False
    end if

    ;; read file
    if(.not.ismissing(str_match(datadir,"/HADISST2")))then
        print("HADISST2 not support yet, since it has multiple member")
        return False
    end if
    fs = addfiles(datadir+"/"+fns,"r")
    var = fs[:]->$varname$

    reorder_dim_var(var)
    return var
end
function read_nn9039k_obs_months_years(obsdir[1]:string,idatadir[1]:string,varname[1]:string,years[*]:integer,months[*]:integer)
begin
    ;; read months in years, ex. y1m1, y1m2, y2m1, y2m2
    ;; obsdir: /cluster/projects/nn9039k/NorCPM/Obs
    ;;  which sould be defined in Defaults.yml
    ;; datadir: SST/HADISST or SST/NOAA ...etc
    ;;  is the relative link to data files

    ;; read monthly sst/sic data on fram
    ;; datadir/YYYY_MM.nc
    ;; ex.
    ;;      /cluster/projects/nn9039k/NorCPM/Obs/SST/NOAA/1981_12.nc
    ;;      /cluster/projects/nn9039k/NorCPM/Obs/SST/HADISST/1870_01.nc
    ;;      /cluster/projects/nn9039k/NorCPM/Obs/SST/HADISST2-1850-2010/2006.nc , ensemble
    ;;
    ny = dimsizes(years)
    nm = dimsizes(months)

    datadir = obsdir+"/"+idatadir

    ;; check datadir
    if(.not. isfilepresent(datadir+"/"+min(years)+"_01.nc"))
        print("obs data not found in "+datadir)
        return False
    end if

    ;; check data files
    ;;;; file names
    fns = ""
    do y = 0,ny-1
    do m = 0,nm-1
        yyyy_mm = years(y)+"_"+sprinti("%2.2d",months(m))+".nc"
        fns := array_append_record(fns,yyyy_mm,0)
    end do
    end do
    fns := fns(1:)

    ;; check filename present
    missingFile = False
    do i = 0, dimsizes(fns)-1
        if(.not.isfilepresent(datadir+"/"+fns(i)))then
            print("missing data file: "+datadir+"/"+fns(i))
            missingFile = True
        end if
    end do
    if(missingFile)then
        print("data file(s) not found.")
        return False
    end if

    ;; read file
    if(.not.ismissing(str_match(datadir,"/HADISST2")))then
        print("HADISST2 not support yet, since it has multiple member")
        return False
    end if
    fs = addfiles(datadir+"/"+fns,"r")
    var = fs[:]->$varname$

    reorder_dim_var(var)
    return var
end

function read_nn9039k_obs_monthly(obsdir[1]:string,idatadir[1]:string,varname[1]:string,ybe[2]:integer)
begin
    ;; obsdir: /cluster/projects/nn9039k/NorCPM/Obs
    ;;  which sould be defined in Defaults.yml
    ;; datadir: SST/HADISST or SST/NOAA ...etc
    ;;  is the relative link to data files

    ;; read monthly sst/sic data on fram
    ;; datadir/YYYY_MM.nc
    ;; ex.
    ;;      /cluster/projects/nn9039k/NorCPM/Obs/SST/NOAA/1981_12.nc
    ;;      /cluster/projects/nn9039k/NorCPM/Obs/SST/HADISST/1870_01.nc
    ;;      /cluster/projects/nn9039k/NorCPM/Obs/SST/HADISST2-1850-2010/2006.nc , ensemble
    ;;

    yb = min(ybe)
    ye = max(ybe)
    years = ispan(yb,ye,1)
    ny = ye-yb+1
    datadir = obsdir+"/"+idatadir

    ;; check datadir
    if(.not. isfilepresent(datadir+"/"+min(ybe)+"_01.nc"))
        print("obs data not found in "+datadir)
        return False
    end if

    ;; check data files
    ;;;; file names
    fns = ""
    do y = 0, ny-1
    do m = 1, 12
        yyyy_mm = years(y)+"_"+sprinti("%2.2d",m)+".nc"
        fns := array_append_record(fns,yyyy_mm,0)
    end do
    end do
    fns := fns(1:)

    ;; check filename present
    missingFile = False
    do i = 0, ny*12-1
        if(.not.isfilepresent(datadir+"/"+fns(i)))then
            print("missing data file: "+datadir+"/"+fns(i))
            missingFile = True
        end if
    end do
    if(missingFile)then
        print("data file(s) not found.")
        return False
    end if

    ;; read file
    if(.not.ismissing(str_match(datadir,"/HADISST2")))then
        print("HADISST2 not support yet, since it has multiple member")
        return False
    end if
    fs = addfiles(datadir+"/"+fns,"r")
    var = fs[:]->$varname$

    reorder_dim_var(var)
    return var
end

function read_obs_monthly(obsdir[1]:string,datadir[1]:string,varname[1]:string,ybe[2]:integer)
begin
    ;; frontend of reading obs data
    hostname = systemfunc("hostname")
    ;; fram only now...
    if(.not.ismissing(str_match(hostname,"fram.sigma2.no")))then
        ;; on fram server
        return read_nn9039k_obs_monthly(obsdir,idatadir,varname,ybe)
    end if
    print("read_obs_monthly(): not sure it can be run on other server.")
    print("read_obs_monthly(): assume data directory is like this: ")
    print("read_obs_monthly(): "+obsdir+"/"+datadir+"/"+ybe(0)+"_01.nc")

    return read_nn9039k_obs_monthly(obsdir,datadir,varname,ybe)
end
function read_obs_leadmonths(obsdir[1]:string,datadir[1]:string,varname[1]:string,inityear[1]:integer,initmonth[1]:integer,leadmonths[*]:integer)
begin
    ;; read obs data with leadmonths
    hostname = systemfunc("hostname")
    ;; get read months from leadmonths
    readyears = leadmonths  ;; create array
    readmonths = leadmonths ;; create array
    readyears = inityear
    readmonths = initmonth + leadmonths
    readyears = where(readmonths .gt.12, readyears+1,readyears)
    readmonths = where(readmonths .gt.12, readmonths-12,readmonths)
    ;; on fram server
    ;if(.not.ismissing(str_match(hostname,"fram.sigma2.no")))then
        varall = read_nn9039k_obs_months(obsdir,datadir,varname,readyears,readmonths)
    ;end if
    return varall
end
function read_obs_months_years(obsdir[1]:string,idatadir[1]:string,varname[1]:string,years[*]:integer,months[*]:integer)
begin
    return read_nn9039k_obs_months_years(obsdir,idatadir,varname,years,months)
end 

function read_obs_months(obsdir[1]:string,idatadir[1]:string,varname[1]:string,iyears[*]:integer,imonths[*]:integer)
begin
    readmonths = imonths
    readyears = iyears
    readyears = where(readmonths .gt.12, readyears+1,readyears)
    readmonths = where(readmonths .gt.12, readmonths-12,readmonths)
    return read_nn9039k_obs_months(obsdir,idatadir,varname,readyears,readmonths)
end

;; test
;var = read_nn9039k_obs_monthly("/cluster/projects/nn9039k/NorCPM/Obs","SST/NOAA","sst",(/1990,1991/))
;var = read_nn9039k_obs_monthly("/cluster/projects/nn9039k/NorCPM/Obs","SST/HADISST","sst",(/1990,1991/))
;var = read_nn9039k_obs_monthly("/cluster/projects/nn9039k/NorCPM/Obs","SST/HADISST2","sst",(/1990,1991/))
;var = read_nn9039k_obs_months_years("/cluster/projects/nn9039k/NorCPM/Obs","SST/HADISST","sst",ispan(2000,2003,1),ispan(2,4,1))
;var = read_nn9039k_obs_months("/cluster/projects/nn9039k/NorCPM/Obs","SST/HADISST","sst",ispan(2000,2003,1),ispan(2,5,1))
;var = read_obs_leadmonths("/cluster/projects/nn9039k/NorCPM/Obs","SST/HADISST","sst",2000,10,ispan(0,12,1))
var = read_obs_leadmonths("~/NS9560K/shared/Obs","PRECIP/GPCP","precip",2000,10,ispan(0,12,1))
printVarSummary(var)
print(cd_calendar(var&time,-1))
