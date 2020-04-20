undef   ("add_lc_labels")
procedure add_lc_labels(wks,map,minlat,maxlat,minlon,maxlon)
;; add lat/lon tickmarks for masked Lambert Conformal projection.
;; copy from https://www.ncl.ucar.edu/Applications/Scripts/mptick_10.ncl
    local lat_values, nlat, lat1_ndc, lat2_ndc, lon1_ndc, lon2_ndc,slope,txres, \
    lon_values, PI, RAD_TO_DEG, dum_lft, dum_rgt, dum_bot, rotate_val \
    , dlon
    begin
      PI         = 3.14159
      RAD_TO_DEG = 180./PI
      dlon = 15
      dlat = 15

    ;---Determine whether we are in northern or southern hemisphere
      if(minlat.ge.0.and.maxlat.gt.0) then
        HEMISPHERE = "NH"
      else
        HEMISPHERE = "SH"
      end if

    ;---Pick some "nice" values for the latitude labels.
      ;lat_values = ispan(toint(minlat),toint(maxlat),dlat) * 1.
      all_lat_values = ispan(-90,90,dlat)
      lat_values = all_lat_values(ind(all_lat_values.ge.minlat .and. all_lat_values.le.maxlat))
      nlat       = dimsizes(lat_values)
    ;
    ; We need to get the slope of the left and right min/max longitude lines.
    ; Use NDC coordinates to do this.
    ;
      lat1_ndc = new(1,float)
      lon1_ndc = new(1,float)
      lat2_ndc = new(1,float)
      lon2_ndc = new(1,float)
      datatondc(map,minlon,lat_values(0)*1.,lon1_ndc,lat1_ndc)
      datatondc(map,minlon,lat_values(nlat-1)*1.,lon2_ndc,lat2_ndc)
      slope_lft = (lat2_ndc-lat1_ndc)/(lon2_ndc-lon1_ndc)
      datatondc(map,maxlon,lat_values(0)*1.,lon1_ndc,lat1_ndc)
      datatondc(map,maxlon,lat_values(nlat-1)*1.,lon2_ndc,lat2_ndc)
      slope_rgt = (lat2_ndc-lat1_ndc)/(lon2_ndc-lon1_ndc)

    ;---Set some text resources
      txres               = True
      txres@txFontHeightF = 0.01
      txres@txPosXF       = 0.1
    ;
    ; Loop through lat values, and attach labels to the left and
    ; right edges of the masked LC plot.  The labels will be 
    ; rotated to fit the line better.
    ;
      dum_lft = new(nlat,graphic)    ; Dummy array to hold attached strings.
      dum_rgt = new(nlat,graphic)    ; Dummy array to hold attached strings.
      do n=0,nlat-1
    ;---Left label
        if(HEMISPHERE.eq."NH") then
          rotate_val = -90
          direction  = "N"
        else
          rotate_val = 90
          direction  = "S"
        end if

    ; Add extra white space to labels.
        lat_label_lft = abs(lat_values(n)) + "~S~o~N~" + direction + \
                        "          "   
        lat_label_rgt = "          "  + abs(lat_values(n)) + "~S~o~N~" + \
                        direction

        txres@txAngleF = RAD_TO_DEG * atan(slope_lft) + rotate_val
    if(False)then ;; turn off left label
        dum_lft(n) = gsn_add_text(wks,map,lat_label_lft,minlon,lat_values(n),txres)
    end if
    ;---Right label
        if(HEMISPHERE.eq."NH") then
          rotate_val = 90
        else
          rotate_val = -90
        end if
        txres@txAngleF = RAD_TO_DEG * atan(slope_rgt) + rotate_val
        dum_rgt(n) = gsn_add_text(wks,map,lat_label_rgt,maxlon,lat_values(n),txres)
      end do

    ;----------------------------------------------------------------------
    ; Now do longitude labels. These are harder because we're not
    ; adding them to a straight line.
    ;
    ; Loop through lon values, and attach labels to the bottom edge
    ; for northern hemisphere, or top edge for southern hemisphere.
    ;
      delete(txres@txPosXF)
      txres@txPosYF = -5.0
    ;---Pick some "nice" values for the longitude labels.
      lon_values = ispan(toint(minlon-dlon),toint(maxlon+dlon),dlon) * 1.
      lon_values = lon_values - mod(lon_values,dlon)
      nlon       = dimsizes(lon_values)
      lon_values = where(lon_values.gt.180,360-lon_values,lon_values)

      dum_bot = new(nlon,graphic)    ; Dummy array to hold attached strings.

      lon_labels = "" + lon_values
      lon_labels = where(lon_values.lt.0, abs(lon_values) + \
                        "~S~o~N~W",""+lon_labels)
      lon_labels = where(lon_values.eq.0,"0",lon_labels)
      lon_labels = where(lon_values.gt.0,lon_values + "~S~o~N~E",lon_labels)
      if(HEMISPHERE.eq."NH") then
        lon_labels = "  ~C~  ~C~" + lon_labels
        lat_val   = minlat
      else
        lon_labels = lon_labels + "~C~ ~C~ "
        lat_val    = maxlat
      end if

      do n=0,nlon-1
    ;
    ; For each longitude label, we need to figure out how much to rotate
    ; it, so get the approximate slope at that point.
    ;
        if(HEMISPHERE.eq."NH") then
    ;---Add labels to bottom of LC plot
          datatondc(map,lon_values(n)-0.25,minlat,lon1_ndc,lat1_ndc)
          datatondc(map,lon_values(n)+0.25,minlat,lon2_ndc,lat2_ndc)
        else
    ;---Add labels to top of LC plot
          datatondc(map,lon_values(n)+0.25,maxlat,lon1_ndc,lat1_ndc)
          datatondc(map,lon_values(n)-0.25,maxlat,lon2_ndc,lat2_ndc)
        end if
        slope_bot = (lat1_ndc-lat2_ndc)/(lon1_ndc-lon2_ndc)
        txres@txAngleF  = atan(slope_bot) * RAD_TO_DEG
    ;
    ; Create longitude label. Add extra carriage returns to
    ; move label away from plot.
    ;

    ;---Attach to map.
        dum_bot(n) = gsn_add_text(wks,map,lon_labels(n),lon_values(n),\
                                  lat_val,txres)
      end do
    end

undef("months_abbr")
function months_abbr(months)
begin
    ;; continous months ,ex. 6,7,8 -> JJA 
    ;; no-continous, ex. 1,3,5 -> 010305
    ;; all year -> ANN

    nm = dimsizes(months)

    ;; is annual:
    if (nm .eq. 12 .and. all(months .eq. ispan(1,12,1)))then
        return "ANN"
    end if
    ;; only one month
    if (nm .eq. 1 )then
        return sprinti("mon%2.2d",months)
    end if

    ;; is continous
    dm = months(1:) - months(:nm-2)
    if (all(dm.eq.1))then
        abbrs = (/"D","J","F","M","A","M","J","J","A","S","O","N","D","J","F","M"/)
        ;abbr = str_join(abbrs(months),"")
        ;abbr = str_sub_str(abbr," ","")
        abbr = str_concat(abbrs(months))
        return abbr
    end if

    ;; non of above
    mstr = ""
    do i = 0, nm-1
        mstr = mstr+sprinti("%2.2d",months(i))
    end do
    return mstr
end

undef("cachefn")
function cachefn(case, casedir,component,varname,years,months,modeln[1],tag)
begin
    ;; assemble cache file name with variables to read
    ;; case_component_varname_min(years)-max(years)_months(abbr)_modeln.nc
    cachedir = casedir+"/cache"
    system("mkdir -p "+cachedir)

    ny = dimsizes(years)
    dy = years(1:)-years(:ny-2)
    if(any(dy.ne.1))then
        print("cachefn(): years is not continuous, need to modify cachefn()")
        exit
    end if
    fn = case+"_"+component+"_"+sprinti("%2.2d",modeln)+"_"+varname+"_"+min(years)+"-"+max(years)+"_"+months_abbr(months)+"_"+tag+".nc"

    fn = cachedir+"/"+fn
    return fn
end

undef  ("cal_ohc_sal_with_temp_salinity_TZLL")
function cal_ohc_sal_with_temp_salinity_TZLL(temp[*][*][*][*],salinity[*][*][*][*],to_depth,ohcorsal)
begin
    ;;  cal ohc with temperature(degC) and salinity(PSU or g/kg)
    ;;          or vertical integrated salinity
    ;;      cal density first: use rho_mwjf(t2d,s2d,depth) 
    ;;  to_depth: integrate from surface to depth
    ;;  return ohc(T,L,L)

    ;; assume it postive down
    datadepths = temp&$temp!1$

    datanz = dimsizes(datadepths)
    ;print("cal_ohc_with_temp_salinity_TZLL(): "+datanz+"depth levels")
    if(isatt(temp,"depth_bnds"))then
        depth_bnds = temp@depth_bnds
        if(dimsizes(dimsizes(depth_bnds)).eq.1)then
            depth_bnds := onedtond(depth_bnds,(/datanz,2/))
        end if
    else
        depth_bnds = new((/datanz,2/),typeof(datadepths))
        depth_bnds(0:datanz-2,1) = (datadepths(0:datanz-2)+datadepths(1:datanz-1))/2. ;; lower boundaries
        depth_bnds(1:datanz-1,0) = depth_bnds(0:datanz-2,1) ;; upper boundaries
        depth_bnds(0,0) = 0. ;; top boundary
        depth_bnds(datanz-1,1) = datadepths(datanz-1)+(datadepths(datanz-1)-depth_bnds(datanz-1,0)) ;; bottom boundary
    end if

    iz = min(ind(depth_bnds(:,1).gt.to_depth)) ;; cal ohc to depth above iz

    rho = temp(:,:iz,:,:)  ;; create array
    rho = rho@_FillValue
    rho@long_name = "density"
    rho@units = "kg/m3"

    ;; units
    if(min(temp).lt.100)then ;; assume temp is in degC
        tempk = temp
        tempk = temp+273.15
        tempk@units = "K"
        tempc = temp
    else  ;; assume in K
        tempk = temp
        tempc = temp 
        tempc = temp -273.15
        tempc@units = "degC"
    end if

    ;; temp should be degC, salinity should be PSU
    if(.not.any(salinity@units.eq.(/"psu","g kg-1"/)))then
        print("cal_ohc_with_temp_salinity_TZLL(): salinity should be in psu")
        print(salinity@units)
        exit
    end if

    dims := dimsizes(rho)
    nt = dims(0)
    nz = dims(1)
    ny = dims(2)
    nx = dims(3)

    ;; cal density
    do t = 0, nt-1
    do z = 0, nz-1
        rho(t,z,:,:) = rho_mwjf(tempc(t,z,:,:),salinity(t,z,:,:),tofloat(datadepths(z)))
    end do
    end do

    ;; OHC = rho * Cp * integrate(Tdz)(z1 to z2)
    ;; set Cp = 4.00000, need modify(http://web.mit.edu/seawater/)(low pr.)
    Cp = 4.00000

    ohc = temp(:,0,:,:) ;; create array, ohc or salinity
    ohc = 0. ;;ohc@_FillValue
    ohc@long_name  = "Ocean heat content"
    ohc@units = "J/m2"
    ohc@thckness = to_depth

    ;; trapecio method
    
    do z = 0, nz-1
        dz = tofloat(min((/depth_bnds(z,1),to_depth/))-depth_bnds(z,0))
        if(ohcorsal.eq."ohc")then
            ohc = ohc + rho(:,z,:,:) * Cp * tempc(:,z,:,:) * dz
        else
            ohc = ohc + rho(:,z,:,:) * salinity(:,z,:,:) * dz
        end if
    end do
    if(isatt(ohc,"actual_range"))then
        delete(ohc@actual_range)
    end if
    return ohc
end

undef("recover_nc_lat2d_lon2d")
function recover_nc_lat2d_lon2d(var)
begin
    ;; resotre lat2d and lon2d from netcdf file
    ;; since netcdf cannot save 2d attitude
        if(isatt(var,"lat2d"))then ;; netcdf cannot save 2d attitude
            dims = dimsizes(var)
            ndim = dimsizes(dims)
            dims := dims(ndim-2:)
            var@lat2d := onedtond(var@lat2d,dims)
            var@lon2d := onedtond(var@lon2d,dims)
            delete(dims)
            delete(ndim)
        end if
    return var
end

undef("remove_right_size_1_dim")
function remove_right_size_1_dim(a)
begin
    dims = dimsizes(a)
    ndim = dimsizes(dims)
    if(ndim.eq.2 .and. dims(1).eq.1)then
        b  = a(:,0)
        return b
    end if
    return a
end

undef("assign_ocn_grid")
procedure assign_ocn_grid(var,gf:file)
begin
    ;;print("assign_ocn_grid(): ")
    if (isatt(var,"lat2d"))then ;; lat is already exist
        return
    end if
    if (isatt(var,"coordinates"))then ;; assign lat/lon to ocn variables
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
        if(coords .eq. "lon lat")then ;; 
            lon = gf->lon
            lat = gf->lat
            ;area= gf->area
        end if
        if(coords .eq. "lon_2 lat_2")then ;; in 3d_dm
            lon = gf->lon_2
            lat = gf->lat_2
        end if
        if(coords .eq. "lon_3 lat_3")then ;; in 3d_dm
            lon = gf->lon_3
            lat = gf->lat_3
        end if
        if(.not.isvar("lon"))then
            print("no coordinate assigned: "+coords)
            exit
        end if
        var@lat2d = lat
        var@lon2d = lon
        ;var@area2d = area
    end if
end

undef("mask_with_latbe_lonbe")
function mask_with_latbe_lonbe(ilat2d,ilon2d,latbe,lonbe)
begin
    ;; return a logical mask inside latbe and lonbe
    ;;    dims follow lat2d and lon2d

    g_areafile = "~/scratch/diag_norcpm/Data/mpiexm_areas.nc"  ;; bad idea
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

    ;; weighting

    if(dimsizes(latdims).eq.1)then ;; incase 1d lat/lon
        wgt = where(vmask,cos(lat2d/180*get_pi("double")),0)
    end if
    ;; read area.nc, bad idea but should work, need modify
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
        print("mask_with_latbe_lonbe(): no wgt defined...")
        print(dims)
        ;print(lon2d(0,0)+" "+lon2d(0,1))
        ;print(lon2d(0,254)+" "+lon2d(0,255))
        ;print(lat2d(0,0)+" "+lat2d(0,1))
        ;print(lat2d(0,254)+" "+lat2d(0,255))
        exit
    end if
    wgt = where(vmask,wgt,0)
    vmask@wgt = wgt

    return vmask
end
undef("mean_with_latbe_lonbe")
function mean_with_latbe_lonbe(var,latbe[2],lonbe[2])
begin
    ;; average rightmost 2 dims with latbe and lonbe
    ;; var should be large than 2 dims
    ;; var should have coordinates or lat2d/lon2d attitdue
    if(isatt(var,"lat2d"))then
        lat2d = var@lat2d
        lon2d = var@lon2d
    else
        dims = dimsizes(var)
        ndim = dimsizes(dims)
        latname = var!(ndim-2)
        lonname = var!(ndim-1)
        lat2d =  var&$latname$;; not really lat2d, but compilable with mask_with_latbe_lonbe()
        lon2d =  var&$lonname$;; not really lon2d, but compilable with mask_with_latbe_lonbe()
    end if
    lmask = mask_with_latbe_lonbe(lat2d,lon2d,latbe,lonbe)
    wgt = lmask@wgt
    varts = wgt_areaave2(var,wgt,0) ;; 0 means use non-missing value only
    if(False)then ;; debug
        system("rm -f wgt.nc")
        f = addfile("wgt.nc","c")
        f->wgt = wgt
    end if
    copy_VarCoords_2(var,varts)
    return varts
end

procedure onedto2d_grid(var)
begin
    ;; re-assign lat2d/lon2d from 1d to 2d
    if (.not.isatt(var,"coordinates"))then 
        return
    end if
    dims = dimsizes(var)
    ndim = dimsizes(dims)

    sdim = dims(ndim-2:) ;; right most 2 dim is lat/lon
    var@lat2d := onedtond(var@lat2d,sdim)
    var@lon2d := onedtond(var@lon2d,sdim)

end

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

procedure align_year_month(year,month)
begin
    ;; month = 13 -> year+1, month=1
    ;; month =  0 -> year-1, month=12
    ;; reaction sytle coding
    orig_year = year
    orig_month = month
    do i = 0, 20
        if(month.ge.1 .and. month.le.12)then
            return
        end if

        if(month.gt.12)then
            month = month-12
            year = year+1
            continue
        end if
        if(month.lt.1)then
            month = month+12
            year = year-1
            continue
        end if
    end do
    print("align_year_month(): failed to align year month, year/month = "+orig_year+"/"+orig_month)
    exit
end
function fn_mpiexm(case, casedir,component,varname,year[1],imonth[*],modeln)
begin
    ;; get data file name
    ;; very simple one, rewrite if need to expand it

    month = imonth ;; avoid warning at str_join()
    datadir = casedir+"/outdata/"+component+"/"
    if (component.eq."echam6")then ;; it's daily data, and some of them are grb file. Damn.
        yyyymm = ""
        yyyy = year
        do m = 0,dimsizes(month)-1
            mm = month(m)
            if(month(m).gt.12)then
                yyyy = year +1
                mm = month(m)-12
            end if
            if(month(m).lt.1)then
                yyyy = year -1
                mm = month(m)+12
            end if
            yyyymm := array_append_record(yyyymm,yyyy+sprinti("%2.2d",mm),0)
        end do
        yyyymm := yyyymm(1:)
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
        if(dimsizes(modeln).ne.1)then ;; get all model runs
            print("read multiple model runs is not applied here.")
            print("use read_mpiexm_season_mean_ensmean_ZLL()")
            return False
        end if
        if(modeln .eq.0)then
            dailyfn = casedir+"/outdata/"+component+"/"+case+"_"+component+where(varname.eq."slp","_slp_","_echam_")+yyyymm+".nc"
            fns = case+"_"+varname+"_"+str_sub_str(cdoop," ","_")+"_"+component+"_"+"_echam_"+yyyymm+".nc"
        else
            dailyfn = casedir+"/outdata/"+component+"/"+case+sprinti("%2.2d",modeln)+"_"+component+where(varname.eq."slp","_slp_","_echam_")+yyyymm+".nc"
            fns = case+"_"+varname+"_"+str_sub_str(cdoop," ","_")+"_"+component+"_"+sprinti("%2.2d",modeln)+"_echam_"+yyyymm+".nc"
        end if
        ;; make tmp nc file
        nf = dimsizes(dailyfn)
        system("rm -rf datatmp")
        system("mkdir -p datatmp")
        do i =0, nf-1
            if(isfilepresent(fns(i)))then
                continue
            end if
            print("cdo --silent -t echam6 -f nc "+cdoop+" -select,name="+varname+" "+dailyfn(i)+" 'datatmp/tmp_"+fns(i)+"' && mv 'datatmp/tmp_"+fns(i)+"'  'datatmp/"+fns(i)+"'")
            system("cdo --silent -t echam6 -f nc "+cdoop+" -select,name="+varname+" "+dailyfn(i)+" 'datatmp/tmp_"+fns(i)+"' && mv 'datatmp/tmp_"+fns(i)+"'  'datatmp/"+fns(i)+"'")
        end do
        fns = "datatmp/"+fns
        return fns

    end if
    if (component.eq."mpiom")then
        ;; "_data_2d_dm_", "_data_2d_mm_", "_data_3du_mm_", "_data_3dw_mm_", "_monitorig_ym_", "_timeser_dm_"
        datatypes = (/ "_data_2d_mm_", "_data_3du_mm_", "_data_3dw_mm_", "_data_2d_dm_", "_monitoring_ym_", "_timeser_dm_"/)
        do i = 0, dimsizes(datatypes)-1
            fn = case+"_"+component+datatypes(i)+year+"0101_"+year+"1231.nc"
            fullfn = casedir+"/outdata/"+component+"/"+fn
            if(.not.isfilepresent(fullfn))then
                continue
            end if
            f = addfile(fullfn,"r")
            filevns := getfilevarnames(f)
            if(any(filevns .eq. varname))then
                break
            end if
        end do

    end if

    return casedir+"/outdata/"+component+"/"+fn
end

function mpiexm_daily_fn(case, casedir,component,varname,year,month,day,modeln)
begin
    yyyy = year
    mm = month
    if(month.gt.12)then
        yyyy = year +1
        mm = month-12
    end if
    if(month.lt.1)then
        yyyy = year -1
        mm = month+12
    end if
    yyyymm = yyyy+sprinti("%2.2d",mm)
    if (component.eq."echam6")then ;; it's daily data, and some of them are grb file. Damn.
        nn = where(modeln.eq.0,"",sprinti("%2.2d",modeln))
        if(varname.eq."slp")then
            dailyfn = casedir+"/outdata/"+component+"/"+case+nn+"_"+component+"_slp_"+yyyymm+".nc"
        else
            dailyfn = casedir+"/outdata/"+component+"/"+case+nn+"_"+component+"_echam_"+yyyymm+".nc"
        end if
    end if
    if (component.eq."mpiom")then
            ;; "_data_2d_dm_", "_data_2d_mm_", "_data_3du_mm_", "_data_3dw_mm_", "_monitorig_ym_", "_timeser_dm_"
            ;;dailyfn = casedir+"/outdata/"+component+"/"+case+"_"+component+"_data_2d_dm_"+year+"0101_"+year+"1231.nc"
        dailyfn = fn_mpiexm(case, casedir,component,varname,year,month,modeln)
        dailyfn = str_sub_str(dailyfn,"data_2d_mm","data_2d_dm")
        f = addfile(dailyfn,"r")
        dims = getfilevardimsizes(f,"time")
        if(dims.eq.12 .or. dims.eq.1)then
            print("file is not daily file, check your variable.")
            print(dailyfn+" "+varname)
            print(dims)
            exit
        end if
        return dailyfn
    end if
    return dailyfn
end
function read_mpiexm_filevar_1day(case, casedir,component,ivarname,year,month,day,modeln)
begin
    varname = ivarname
    ;; read one day data
    fn = mpiexm_daily_fn(case, casedir,component,varname,year,month,day,modeln)
    print(fn+"")
    f = addfile(fn,"r")
    filevarnames = getfilevarnames(f)
    if(.not.any(filevarnames.eq.varname))then
        print(varname+" is not in "+fn)
        exit
    end if
    time = f->time
    ndim = dimsizes(getfilevardimsizes(f,varname))

    opt = 0
    if(isatt(time,"calendar"))then
        opt@calendar = time@calendar
    end if
    itime = minind(abs(time-cd_inv_calendar(year,month,day,0,0,0,time@units,opt)))
    ;;print(cd_inv_calendar(year,month,day,0,0,0,time@units,opt))
    ;;print(year+"-"+month+"-"+day)
    ;;print(fn)
    ;;print(cd_calendar(time,-3))
    ;;print(itime)

    ;; itime: index of time
    ;; ndim: number of dims of variable in file
    if(ndim.le.2)then
        var = f->$varname$
    end if
    if(ndim.eq.3)then
        var = f->$varname$(itime,:,:)
    end if
    if(ndim.eq.4)then
        var = f->$varname$(itime,:,:,:)
    end if
    if(.not.isvar("var"))then
        print("read_mpiexm_filevar_1day(): there is no "+varname+" in file:")
        print("read_mpiexm_filevar_1day(): "+fn)
        exit
    end if
    assign_ocn_grid(var,f)
    dims = dimsizes(var)
    if(dims(0).eq.1)then
        if(ndim.eq.4)then
            vartmp = var(0,:,:)
            delete(var)
            var = vartmp
        end if
    end if
    reorder_dim_var(var)
    return var
end
function read_mpiexm_var_1day(case, casedir,component,varname,year,month,day,modeln)
begin
    ;; frontend of read_mpiexm_filevar_1day()
    ;; for extended variables(daily)
    extvars = (/"Q_FLUX_SFC"/)
    if(.not.any(varname .eq.extvars))then
        return read_mpiexm_filevar_1day(case, casedir,component,varname,year,month,day,modeln)
    end if
    if(varname .eq. "Q_FLUX_SFC")then
        ;; surface heat flux, downward is negative , sum of 
            ;; surface sensible heat flux
            ;; surface latent heat flux
            ;; short wave radiation
            ;; long wave radiation
        shf = read_mpiexm_filevar_1day(case, casedir,component,"ahfs",year,month,day,modeln)
        lhf = read_mpiexm_filevar_1day(case, casedir,component,"ahfl",year,month,day,modeln)
        swr = read_mpiexm_filevar_1day(case, casedir,component,"srads",year,month,day,modeln)
        lwr = read_mpiexm_filevar_1day(case, casedir,component,"trads",year,month,day,modeln)
        qflux = shf
        qflux = shf+lhf+swr+lwr
        qflux@long_name = "net heat flux at surface"
        reorder_dim_var(qflux)
        return qflux
    end if
end
function read_mpiexm_1day_modeln(case, casedir,component,varname,year,month,day,modeln)
begin
    ;; frontend of read_mpiexm_filevar_1day()
    ;; mean it if modeln is array
    nmodel = dimsizes(modeln)
    if(nmodel .eq. 1)then
        return read_mpiexm_var_1day(case, casedir,component,varname,year,month,day,modeln)
    end if
    m = read_mpiexm_var_1day(case, casedir,component,varname,year,month,day,modeln(0))
    do i = 1,nmodel -1
        m1 = read_mpiexm_var_1day(case, casedir,component,varname,year,month,day,modeln(i))
        m = m+m1
        delete(m1)
    end do
    m = m/nmodel
    return m
end 

function get_vmask_to_ilat_ilon_1_2(ivmask)
begin
    ;; get minimum square of vmask
    vmask = ivmask
    dims = dimsizes(vmask)
    ilon1 = 9999
    ilon2 = -1 
    do j = 0,dims(0)-1
        ilon1 = min((/min(ind(vmask(j,:))),ilon1/))  ;; leftest subscript
        ilon2 = max((/max(ind(vmask(j,:))),ilon2/))  ;; rightest subscript
    end do
    ilat1 = 9999
    ilat2 = -1
    do i = 0,dims(1)-1
        ilat1 = min((/min(ind(vmask(:,i))),ilat1/))  ;; bottom most subscript, not exactly south
        ilat2 = max((/max(ind(vmask(:,i))),ilat2/))  ;; top most subscript
    end do

    vmask@ilat1 = ilat1
    vmask@ilat2 = ilat2
    vmask@ilon1 = ilon1
    vmask@ilon2 = ilon2

    return vmask
end
function read_mpiexm_filevar_mean_daily_ts_1m(case, casedir,component,varname,year,month,latbe,lonbe,modeln)
begin
    ;; read daily data 1 month
    fn = mpiexm_daily_fn(case, casedir,component,varname,year,month,1,modeln)
    f = addfile(fn,"r")
    time = f->time
    ndim = dimsizes(getfilevardimsizes(f,varname))

    opt = 0
    if(isatt(time,"calendar"))then
        opt@calendar = time@calendar
    end if
    it1 = minind(abs(time-cd_inv_calendar(year,month,1,0,0,0,time@units,opt)))
    it2 = minind(abs(time-cd_inv_calendar(year,month,days_in_month(year,month),23,59,59,time@units,opt)))

    ;; read and averaging region of var
    lat2d = f->lat
    lon2d = f->lon
    vmask = mask_with_latbe_lonbe(lat2d,lon2d,latbe,lonbe) ;; True in desire region
    wgt = vmask@wgt

    ;; find minimum square to read
    if(.not.isatt(vmask,"lat1"))then
        vmask = get_vmask_to_ilat_ilon_1_2(vmask)
    end if
    ilat1 = vmask@ilat1
    ilat2 = vmask@ilat2
    ilon1 = vmask@ilon1
    ilon2 = vmask@ilon2

    if(ndim.eq.3)then
        var = f->$varname$(it1:it2,ilat1:ilat2,ilon1:ilon2)
    end if
    if(ndim.eq.4)then
        var = f->$varname$(it1:it2,:,ilat1:ilat2,ilon1:ilon2)
    end if
    if(.not.isvar("var"))then
        print("read_mpiexm_filevar_mean_daily_ts_1m(): "+varname+" is not in "+fn)
        exit
    end if

    if (False) then ; debug
        system("rm -f tmp.nc")
        f=addfile("tmp.nc","c")
        f->vmask = where(vmask,1,0)
        f->wgt = wgt
        f->lat2d = lat2d
        f->var = var
    end if

    varts = wgt_areaave2(var,wgt(ilat1:ilat2,ilon1:ilon2),0) ;; 0 means use non-missing value only
                                    ;; since here use global values with 0 weight outside
    varts!0 = "time"
    varts&time = var&$var!0$

    delete(var)
    return varts
end
function read_mpiexm_filevar_mean_daily_region_1m(case, casedir,component,varname,year,month,vmask,modeln)
begin
    ;; read daily data 1 month with vmask region only
    fn = mpiexm_daily_fn(case, casedir,component,varname,year,month,1,modeln)
    f = addfile(fn,"r")
    time = f->time
    ndim = dimsizes(getfilevardimsizes(f,varname))

    opt = 0
    if(isatt(time,"calendar"))then
        opt@calendar = time@calendar
    end if
    it1 = minind(abs(time-cd_inv_calendar(year,month,1,0,0,0,time@units,opt)))
    it2 = minind(abs(time-cd_inv_calendar(year,month,days_in_month(year,month),23,59,59,time@units,opt)))

    ;; find minimum square to read
    if(.not.isatt(vmask,"lat1"))then
        vmask = get_vmask_to_ilat_ilon_1_2(vmask)
    end if

    ilat1 = vmask@ilat1
    ilat2 = vmask@ilat2
    ilon1 = vmask@ilon1
    ilon2 = vmask@ilon2

    if(ndim.eq.3)then
        var = f->$varname$(it1:it2,ilat1:ilat2,ilon1:ilon2)
    end if
    if(ndim.eq.4)then
        var = f->$varname$(it1:it2,:,ilat1:ilat2,ilon1:ilon2)
    end if
    if(.not.isvar("var"))then
        print("read_mpiexm_filevar_mean_daily_region_1m(): "+varname+" is not in "+fn)
        exit
    end if

    return var
end
function read_mpiexm_filevar_mean_daily_ts_seasonaly(case, casedir,component,varname,years,imonths,latbe,lonbe,modeln)
begin
    ;; frontend of read_mpiexm_filevar_mean_daily_ts_1m()
    ;; read monthly data (months) for each (years)
    ;; if imonth .eq. 0 => whole year => months = ispan(1,12,1)

    if(any(imonths.eq.0))then
        months = ispan(1,12,1)
    else
        months = imonths
    end if

    ;; if echam6, use cdo to read daily time series(quicker)
    ;; time cdo -fldmean -sellonlatbox,-57.5,-32.5,25,35 -select,name=trad0 ../f08_5AGCMs_NASPG_average/outdata/echam6/f08_5AGCMs_NASPG_average01_echam6_echam_111[100-212].nc 1.nc 
    if(component .eq. "echam6")then ;; read with cdo, use in fixed grid only
        ;; input file links in tmp dir
        ;; get latlon box and output file name
        lonlatbox=min(lonbe)+","+max(lonbe)+","+min(latbe)+","+max(latbe)
        ofn = case+"_mod"+sprinti("%2.2d",modeln)+"_"+varname+"_"+str_sub_str(lonlatbox,",","_")+".nc"

        if(isfilepresent(ofn))then
            f = addfile(ofn,"r")
            if(getfilevardimsizes(f,"time").eq.1)then
                print("cache file wrong, remove it. "+ofn)
                system("rm -f "+ofn)
            end if
        end if
        if(.not.isfilepresent(ofn))then
            tmpdatadir = "tmpdata_"+case+sprinti("%2.2d",modeln)
            system("rm -rf "+tmpdatadir) ;; must clean out data file links
            system("mkdir -p "+tmpdatadir)
            do y = 0, dimsizes(years)-1
            do m = 0, dimsizes(months)-1
                fn = mpiexm_daily_fn(case, casedir,component,varname,years(y),months(m),1,modeln)
                system("ln -sf "+fn+" "+tmpdatadir+"/")
            end do
            end do
            cmd = "cdo  -fldmean -sellonlatbox,"+lonlatbox+" -select,name="+varname+" '"+tmpdatadir+"/*' tmp_"+ofn+" && mv tmp_"+ofn+" "+ofn
            print(""+cmd)
            system("rm -f "+ofn)
            system(cmd)
        end if

        f = addfile(ofn,"r")
        varall = f->$varname$(:,0,0)
        return remove_right_size_1_dim(varall)
    end if

    print("read_mpiexm_filevar_mean_daily_ts_seasonaly(): read data with ncl")
    ;; others read with ncl
    do y = 0, dimsizes(years)-1
    do m = 0, dimsizes(months)-1
        var1 = read_mpiexm_filevar_mean_daily_ts_1m(case, casedir,component,varname,years(y),months(m),latbe,lonbe,modeln)
        if(.not.isvar("varall"))then
            varall = var1
            tunit = var1&$var1!0$@units
        else
            var1&$var1!0$ = cd_convert(var1&$var1!0$,tunit)
            varall1 = array_append_record(varall,var1,0)
            delete(varall)
            varall = varall1
            delete(varall1)
        end if
        delete(var1)
    end do
    end do
    return remove_right_size_1_dim(varall)
end
function read_mpiexm_var_mean_daily_ts_seasonaly_1model(case, casedir,component,varname,years,imonths,latbe,lonbe,modeln)
begin
    ;; frontend of read_mpiexm_filevar_mean_daily_ts_seasonaly
    ;; for extend variables
    if(any(varname .eq.(/"Q_FLUX_SFC"/)))then
        if(varname .eq. "Q_FLUX_SFC")then
            ;; surface heat flux, downward is negative , sum of 
                ;; surface sensible heat flux
                ;; surface latent heat flux
                ;; short wave radiation
                ;; long wave radiation
                print("read_mpiexm_var_mean_daily_ts_seasonaly_1model(): for Q_FLUX_SFC, reading shf(ahfs) in model "+modeln)
            shf = read_mpiexm_filevar_mean_daily_ts_seasonaly(case, casedir,component,"ahfs",years,imonths,latbe,lonbe,modeln)
                print("read_mpiexm_var_mean_daily_ts_seasonaly_1model(): for Q_FLUX_SFC, reading lhf(ahfl) in model "+modeln)
            lhf = read_mpiexm_filevar_mean_daily_ts_seasonaly(case, casedir,component,"ahfl",years,imonths,latbe,lonbe,modeln)
                print("read_mpiexm_var_mean_daily_ts_seasonaly_1model(): for Q_FLUX_SFC, reading swr(srads) in model "+modeln)
            swr = read_mpiexm_filevar_mean_daily_ts_seasonaly(case, casedir,component,"srads",years,imonths,latbe,lonbe,modeln)
                print("read_mpiexm_var_mean_daily_ts_seasonaly_1model(): for Q_FLUX_SFC, reading lwr(trads) in model "+modeln)
            lwr = read_mpiexm_filevar_mean_daily_ts_seasonaly(case, casedir,component,"trads",years,imonths,latbe,lonbe,modeln)
            qflux = shf
            qflux = shf+lhf+swr+lwr
            qflux@long_name = "net heat flux at surface"
            reorder_dim_var(qflux)
            return qflux
        end if
        print("read_mpiexm_var_mean_daily_ts_seasonaly(): "+varname+" is not support yet")
        exit
    else
        return read_mpiexm_filevar_mean_daily_ts_seasonaly(case, casedir,component,varname,years,imonths,latbe,lonbe,modeln)
    end if
end
function read_mpiexm_var_mean_daily_ts_seasonaly(case, casedir,component,varname,years,imonths,latbe,lonbe,modeln)
begin
    ;; frontend fo read_mpiexm_var_mean_daily_ts_seasonaly_1model()
    if (dimsizes(modeln).eq.1)then
        return read_mpiexm_var_mean_daily_ts_seasonaly_1model(case, casedir,component,varname,years,imonths,latbe,lonbe,modeln)
    else
        nmodel = dimsizes(modeln)
        var = read_mpiexm_var_mean_daily_ts_seasonaly(case, casedir,component,varname,years,imonths,latbe,lonbe,modeln(0))
        var = var/nmodel
        ;printVarSummary(var)
        do i = 1, nmodel-1
            var1 = (read_mpiexm_var_mean_daily_ts_seasonaly(case, casedir,component,varname,years,imonths,latbe,lonbe,modeln(i))/nmodel)
            ;print(case+" "+modeln(i)+" "+varname+" "+years)
            ;printVarSummary(var1)
            var = var + var1 
        end do
        return var
    end if
    print("read_mpiexm_var_mean_daily_ts_seasonaly(): should not be here...")
    exit
end
function read_mpiexm_filevar_daily_1m(case, casedir,component,varname,iyear,imonth,modeln)
begin
    ;; read daily data 1 month
    month = imonth
    year = iyear
    align_year_month(year,month)
    fn = mpiexm_daily_fn(case, casedir,component,varname,year,month,1,modeln)
    f = addfile(fn,"r")
    time = f->time
    ndim = dimsizes(getfilevardimsizes(f,varname))

    opt = 0
    if(isatt(time,"calendar"))then
        opt@calendar = time@calendar
    end if
    it1 = minind(abs(time-cd_inv_calendar(year,month,1,0,0,0,time@units,opt)))
    it2 = minind(abs(time-cd_inv_calendar(year,month,days_in_month(year,month),23,59,59,time@units,opt)))
    if(ndim.eq.3)then
        var = f->$varname$(it1:it2,:,:)
    end if
    if(ndim.eq.4)then
        var = f->$varname$(it1:it2,:,:,:)
    end if
    if(.not.isvar("var"))then
        print("read_mpiexm_filevar_daily_1m(): there is no "+varname+" in file:")
        print("read_mpiexm_filevar_daily_1m(): "+fn)
        exit
    end if
    assign_ocn_grid(var,f)
    return var
end
function read_mpiexm_filevar_daily_variance_1m(case, casedir,component,varname_var,year,month,modeln)
begin
    ;; cal daily variance in this month
    ;; varname should be "realvarname_var"
    ;; TBD
    varname = str_sub_str(varname_var, "_var","")
    var1m = read_mpiexm_filevar_daily_1m(case, casedir,component,varname,year,month,modeln)
    varvar = dim_variance_n_Wrap(var1m,0) ;; assume dim 0 is time(daily)
    varvar@units = "("+varvar@units+")^2"
    return varvar
end
function read_mpiexm_var_daily_1m(case, casedir,component,varname,year,month,modeln)
begin
    ;; front end for read_mpiexm_filevar_daily_1m()
    ;; process the variance of daily variable

    if(.not.ismissing(str_match_regex(varname,"_var$")))then
        return read_mpiexm_filevar_daily_variance_1m(case, casedir,component,varname,year,month,modeln)
    end if
    return read_mpiexm_filevar_daily_1m(case, casedir,component,varname,year,month,modeln)
end
function read_mpiexm_filevar_season_1y(case, casedir,component,ivarname,year,months,modeln)
begin
    ;; read months monthly data in same year
    ;; modeln: mondel number, if echam6 is more than 1 run

    ;; the variable only exist in daily file
    daily_varname = (/"amld","amld_var"/)

    varname = ivarname
    if(any(varname .eq. daily_varname))then
        var1m = dim_avg_n_Wrap(read_mpiexm_var_daily_1m(case, casedir,component,varname,year,months(0),modeln),0) ;; assume dim0 is time
        if(dimsizes(months).eq.1)then
            return var1m
        else
            nmonth = dimsizes(months)
            dims = dimsizes(var1m)
            dims := array_append_record(nmonth,dims,0)
            ndim = dimsizes(dims)
            varall = new(dims,typeof(var1m))
            if(ndim.eq.3)then
                varall(0,:,:) = var1m
            end if
            if(ndim.eq.4)then
                varall(0,:,:,:) = var1m
            end if
            delete(var1m)
            do m = 1,nmonth-1
                var1m = dim_avg_n_Wrap(read_mpiexm_var_daily_1m(case, casedir,component,varname,year,months(m),modeln),0) 
                if(ndim.eq.3)then
                    varall(m,:,:) = var1m
                end if
                if(ndim.eq.4)then
                    varall(m,:,:,:) = var1m
                end if
                delete(var1m)      
            end do
            varall!0 = "month"
            varall&month = months
            return varall
        end if 
    end if
    if(component.eq."echam6")then ;; monthly file
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
        if(any(months.gt.12 .or. months.lt.1))then ;; next or prev year
            nmonth = dimsizes(months)
            do m = 0, nmonth-1
                ryear = year
                rmonth = months(m)
                align_year_month(ryear,rmonth)
                fn = fn_mpiexm(case, casedir,component,varname,ryear,0,modeln)
                f = addfile(fn,"r")
                var = f->$varname$(rmonth-1,:,:,:)
                if(isvar("var1"))then
                    var1(m,:,:,:) = var
                    time := array_append_record(time,cd_convert(f->time(rmonth-1),time@units),0)
                    delete(var)
                    continue
                end if
                dims = dimsizes(var)
                dims := array_append_record(nmonth,dims,0)
                var1 = new(dims,typeof(var))
                var1(m,:,:,:) = var
                time = f->time(rmonth-1)
                if(isatt(var,"coordinates").and.var@coordinates .eq. "lon lat")then
                    var1@lat2d = f->lat
                    var1@lon2d = f->lon
                end if

            end do
            return var1
        end if
        fn = fn_mpiexm(case, casedir,component,varname,year,0,modeln)
        f = addfile(fn,"r")
        var = f->$varname$
        if(isatt(var,"coordinates").and.var@coordinates .eq. "lon lat")then
            var@lat2d = f->lat
            var@lon2d = f->lon
        end if
        dims = dimsizes(var)
        if(dims(0).eq.12)then
            var1 = var(months-1,:,:,:)
        else
            var1 = var
        end if
        if(dims(0) .gt.12)then
            print("read_mpiexm_filevar_season_1y(): unexpected daily data")
            print("read_mpiexm_filevar_season_1y(): ERROR? exit...")
            exit
        end if
        delete(var)
        return var1
    end if
    print("read_mpiexm_filevar_season_1y(): unknown component: "+component)
    exit
end
function read_mpiexm_extvar_season_1y(case, casedir,component,varname,year,month,modeln)
begin
    ;; calculate extended variable from file variables
    ;; modify the list in function read_mpiexm_season_1y()

    ;; split variable name and lev(number), ex. "OHC-100" -> OHC , 100
    if(.not.ismissing(str_match(varname,"-")))then
        vararray = str_split_csv(varname,"-",3)
        vn = vararray(0,0)
        opt = vararray(0,1)
    else 
        vn = varname
        opt = 0
    end if
    ;; for OHC
    if(vn .eq. "OHC")then
        ;; need temperature, salinity,
        temp = read_mpiexm_filevar_season_1y(case, casedir,component,"tho",year,month,modeln)
        salinity = read_mpiexm_filevar_season_1y(case, casedir,component,"sao",year,month,modeln)
        to_depth = stringtointeger(opt)
        ohc =  cal_ohc_sal_with_temp_salinity_TZLL(temp,salinity,to_depth,"ohc")

        delete(temp)
        delete(salinity)
        ohc@standar_name = "Ocean heat content "+to_depth+" m"
        return ohc
    end if
    ;; SST, just in degC
    if(vn .eq. "SSTC")then
        sstk = read_mpiexm_filevar_season_1y(case, casedir,component,"sst",year,month,modeln)
        sstc = sstk
        sstc = sstk - 273.15
        sstc@units = "degC"
        return sstc
    end if
    ;; precipitaion = convective + stra.
    if(vn .eq. "PREC")then
        aprl = read_mpiexm_filevar_season_1y(case, casedir,component,"aprl",year,month,modeln)
        aprc = read_mpiexm_filevar_season_1y(case, casedir,component,"aprc",year,month,modeln)
        prec = aprl 
        prec = aprl + aprc
        prec@long_name = "total precipitation (aprl + aprc)"
        ;; W/m2s2 => mm/day
        prec = prec * 86400
        prec@units = "mm/day"

        return prec
    end if
    ;; 90 percentile of daily rainfall
    ;;      not start yet
    ;;if(vn .eq. "PRECP90")then
    ;;end if
end


function read_mpiexm_season_1y(case, casedir,component,varname,year,months,modeln)
begin
    ext_varnames = (/"OHC","SSTC","HEATFLUX","PREC"/)
    isextvar = False
    do i = 0, dimsizes(ext_varnames)-1
        if(.not.ismissing(str_match_regex(varname,"^"+ext_varnames(i))))then
            isextvar = True
            break
        end if
    end do
    if(isextvar)then
        return read_mpiexm_extvar_season_1y(case, casedir,component,varname,year,months,modeln)
    end if
    return read_mpiexm_filevar_season_1y(case, casedir,component,varname,year,months,modeln)
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

function read_mpiexm_season_YZLL(case, casedir,component,varname,years,imonths,modeln[1])
begin
    ;; frontend of read_mpiexm_12m(), read yearly average
    ;; output var in year,(lev,),y,x

    if(any(imonths .eq.0))then
        months = ispan(1,12,1)
    else
        months = imonths
    end if

    ;; check cache
    cache = cachefn(case, casedir,component,varname,years,months,modeln,"season_YZLL")
    if(isfilepresent(cache))then
        f = addfile(cache,"r")
        var = f->$varname$
        if(isatt(var,"lat2d"))then
            dims = dimsizes(var)
            ndim = dimsizes(dims)
            var@lat2d := onedtond(var@lat2d,dims(ndim-2:))
            var@lon2d := onedtond(var@lon2d,dims(ndim-2:))
        end if
        return var
    end if

    ny = dimsizes(years)
    nmonth = dimsizes(months)
    var1y = dim_avg_n_Wrap(read_mpiexm_season_1y(case,casedir,component,varname,years(0),months,modeln),0)
    dims1y = dimsizes(var1y)
    dims = array_append_record(ny,dims1y,0)
    ndim = dimsizes(dims)
    varyr = new(dims,typeof(var1y))
    if(ndim.eq.3)then
        varyr(0,:,:) = var1y
    end if
    if(ndim.eq.4)then
        varyr(0,:,:,:) = var1y
    end if

    delete(var1y)
    do y =  1,ny-1
        ;;print("read_mpiexm_season_YZLL(): reading "+years(y))
        var1y = dim_avg_n_Wrap(read_mpiexm_season_1y(case,casedir,component,varname,years(y),months,modeln),0)
        if(ndim.eq.3)then
            varyr(y,:,:) = var1y
        end if
        if(ndim.eq.4)then
            varyr(y,:,:,:) = var1y
        end if
        delete(var1y)
    end do
    varyr!0 = "year"
    varyr&year = years
    varyr@months = months

    ;; assign grid
    if(component.eq."mpiom")then
        fn = fn_mpiexm(case, casedir,component,varname,years(0),1,modeln)
        assign_ocn_grid(varyr,addfile(fn,"r"))
    end if

    ;; save cache 
    f = addfile(cache,"c")
    f->$varname$ = varyr

    return varyr
end
function read_mpiexm_YZLL(case, casedir,component,varname,years,modeln)
begin
    return read_mpiexm_season_YZLL(case, casedir,component,varname,years,ispan(1,12,1),modeln)
end
function read_mpiexm_season_ensmean_YZLL(case, casedir,component,varname,years,imonths,modeln)
begin
    ;; frontend of read_mpiexm_season_YZLL(), return ensemble mean
    nmodel = dimsizes(modeln)
    if(nmodel.eq.1)then
        return read_mpiexm_season_YZLL(case, casedir,component,varname,years,imonths,modeln)
    end if

    m1 = read_mpiexm_season_YZLL(case, casedir,component,varname,years,imonths,modeln(0))
    m1 = m1/nmodel
    do i = 1, nmodel-1
        m1 = m1+ (read_mpiexm_season_YZLL(case, casedir,component,varname,years,imonths,modeln(i))/nmodel)
    end do
    m1@modeln = modeln
    return m1
end 
function read_mpiexm_season_MYZLL(case, casedir,component,varname,years,imonths,modeln)
begin
    ;; frontend of read_mpiexm_season_YZLL(), read multiple models
    nmodel = dimsizes(modeln)
    if(nmodel.eq.1)then
        return read_mpiexm_season_YZLL(case, casedir,component,varname,years,imonths,modeln)
    end if

    m1 = read_mpiexm_season_YZLL(case, casedir,component,varname,years,imonths,modeln(0))
    mall = new(array_append_record(nmodel,dimsizes(m1),0),typeof(m1))
    mall(0,:,:,:,:) = m1
    delete(m1)
    do i = 1, nmodel-1
        mall(i,:,:,:,:) = read_mpiexm_season_YZLL(case, casedir,component,varname,years,imonths,modeln(i))
    end do
    mall!0 = "modeln"
    mall&modeln = modeln
    return mall
end 

function read_mpiexm_season_ts(case, casedir,component,varname,years,months,latbe,lonbe,modeln)
begin
    ;; return time yearly(seasonal) series 
    ;; only 1 modeln
    nmod = dimsizes(modeln)
    if(nmod .eq. 1)then
        a = read_mpiexm_season_YZLL(case, casedir,component,varname,years,months,modeln)
        b = mean_with_latbe_lonbe(a,latbe,lonbe)
        b!0 = a!0
        b&$b!0$ = a&$a!0$
        return remove_right_size_1_dim(b)
    else
        a = read_mpiexm_season_YZLL(case, casedir,component,varname,years,months,modeln(0))
        b = mean_with_latbe_lonbe(a,latbe,lonbe)
        c = remove_right_size_1_dim(b)
        tsall = new(array_append_record(nmod,dimsizes(c),0),typeof(b))
        tsall!0 = "member"
        tsall&member = modeln
        tsall!1 = a!0
        tsall&$tsall!1$ = a&$a!0$
        tsall(0,:) = c
        delete(c)
        do i = 1, nmod-1
            delete(a)
            delete(b)
            a = read_mpiexm_season_YZLL(case, casedir,component,varname,years,months,modeln(0))
            b = mean_with_latbe_lonbe(a,latbe,lonbe)
            
            tsall(i,:) = remove_right_size_1_dim(b)
        end do
        return  tsall

    end if
end
function read_mpiexm_ens_season_ts(case, casedir,component,varname,years,months,latbe,lonbe,modeln)
begin
    ;; ensemble
    allts = read_mpiexm_season_ts(case, casedir,component,varname,years,months,latbe,lonbe,modeln)
    if(dimsizes(modeln).eq.1)then
        return allts
    else
        ts = dim_avg_n_Wrap(allts,0)
        return ts
    end if
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

    ;; check cache
    cache = cachefn(case, casedir,component,varname,years,months,modeln,"season_ZLL")
    if(isfilepresent(cache))then
        f = addfile(cache,"r")
        var = f->$varname$
        if(isatt(var,"lat2d"))then
            dims = dimsizes(var)
            ndim = dimsizes(dims)
            var@lat2d := onedtond(var@lat2d,dims(ndim-2:))
            var@lon2d := onedtond(var@lon2d,dims(ndim-2:))
        end if
        return var
    end if

    ny = dimsizes(years)
    nmonth = dimsizes(months)
    var1y = dim_avg_n_Wrap(read_mpiexm_season_1y(case,casedir,component,varname,years(0),months,modeln),0)
    var1y = var1y/ny

    do y =  1,ny-1
        var1y = var1y + (dim_avg_n_Wrap(read_mpiexm_season_1y(case,casedir,component,varname,years(y),months,modeln),0)/ny)
    end do
    var1y@months = months
    var1y@years = years
    ;; assign grid
    if(component.eq."mpiom")then
        fn = fn_mpiexm(case, casedir,component,varname,years(0),1,modeln)
        assign_ocn_grid(var1y,addfile(fn,"r"))
    end if

    ;; save cache 
    f = addfile(cache,"c")
    f->$varname$ = var1y


    return var1y
end
function read_mpiexm_season_mean_ensmean_ZLL(case, casedir,component,varname,years,imonths,modeln[*]:integer)
begin
    ;; frontend of read_mpiexm_season_mean_ZLL(), return ensemble mean
    nmodel = dimsizes(modeln)
    if(nmodel.eq.1)then
        return read_mpiexm_season_mean_ZLL(case, casedir,component,varname,years,imonths,modeln)
    end if

    m1 = read_mpiexm_season_mean_ZLL(case, casedir,component,varname,years,imonths,modeln(0))
    m1 = m1/nmodel
    do i = 1, nmodel-1
        m1 = m1+ (read_mpiexm_season_mean_ZLL(case, casedir,component,varname,years,imonths,modeln(i))/nmodel)
    end do

    ;; assign grid
    if(component.eq."mpiom")then
        fn = fn_mpiexm(case, casedir,component,varname,years(0),1,modeln)
        assign_ocn_grid(m1,addfile(fn,"r"))
    end if

    m1@modeln = modeln
    return m1
end

;; test
;a = read_mpiexm_season_mean_ZLL("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","echam6","aps",ispan(1060,1062,1),(/4,5,6/),1)
;a = read_mpiexm_season_YZLL("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","echam6","aps",ispan(1060,1062,1),(/12,13,14/),1)
;a = read_mpiexm_season_mean_ensmean_ZLL("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","echam6","aps",ispan(1060,1062,1),(/4,5,6/),ispan(1,5,1))
;a = mpiexm_daily_fn("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","echam6","aps",1060,1,15,1)
;a = mpiexm_daily_fn("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","mpiom","sst",1060,1,15,1)
;a = read_mpiexm_filevar_1day("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","mpiom","sst",1060,1,15,1)

;a = read_mpiexm_filevar_daily_1m("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","mpiom","amld",1061,2,1)
;a = read_mpiexm_season_mean_ZLL("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","mpiom","amld",ispan(1060,1062,1),(/8,9,10/),1)
;a = read_mpiexm_season_mean_ZLL("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","mpiom","amld_var",ispan(1060,1062,1),(/8,9,10/),1)
;a = read_mpiexm_season_mean_ZLL("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","echam6","aps",ispan(1060,1062,1),(/8,9,10/),1)
;printVarSummary(a)
;print(a)
;a = read_mpiexm_season_mean_ensmean_ZLL("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","mpiom","OHC-500",ispan(1060,1062,1),(/4,5,6/),0)
;printVarSummary(a)
;system("rm -f tmp.nc")
;f =addfile("tmp.nc","c")
;f->var = a

;a = read_mpiexm_season_mean_ensmean_ZLL("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","mpiom","atlantic_moc",(/1060,1061,1062,1063/),(/6/),0) ;; atlantic_moc in monitoring_ym, yearly, (time,depth,lat,1)
;printVarSummary(a)
;printMinMax(a,0)
;exit

;a = read_mpiexm_filevar_1day("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","mpiom","sst",1060,04,30,1)
;a = read_mpiexm_filevar_1day("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","echam6","relhums",1060,04,30,1)
;printVarSummary(a)

;a = read_mpiexm_filevar_mean_daily_ts_1m("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","mpiom","sst",1060,05,(/-30.,-40./),(/0.,10./),0)
;a = read_mpiexm_filevar_mean_daily_ts_seasonaly("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","mpiom","sst",ispan(1061,1070,1),(/1,2,3/),(/-30.,-40./),(/0.,10./),0)
;a = read_mpiexm_var_mean_daily_ts_seasonaly("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","mpiom","sst",ispan(1061,1070,1),(/1,2,3/),(/-30.,-40./),(/0.,10./),0)
;;a = read_mpiexm_season_ts("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","echam6","aps",ispan(1060,1062,1),(/12,13,14/),(/-10.,10./),(/120.,180./),1)
;;a = read_mpiexm_season_ts("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","mpiom","sst",ispan(1060,1062,1),(/10,11,12/),(/-10.,10./),(/120.,180./),1)
;;printVarSummary(a)

;a = fn_mpiexm("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","echam6","aps",1060,12,1)
;print(a)
;a = read_mpiexm_season_mean_ensmean_ZLL("f08_5AGCMs_NASPG_average","/projects//NS9207K/pgchiu/f08_5AGCMs_NASPG_average","mpiom","psitro",(/1060,1061,1062,1063/),(/6/),0) 
;printVarSummary(a)
