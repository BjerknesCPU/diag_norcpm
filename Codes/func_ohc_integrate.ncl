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

function cal_ohc_with_temp_salinity_TZLL(temp[*][*][*][*],salinity[*][*][*][*],to_depth)
begin
    return cal_ohc_sal_with_temp_salinity_TZLL(temp,salinity,to_depth,"ohc")
end
function cal_ohc_with_temp_salinity_MTZLL(temp[*][*][*][*][*],salinity[*][*][*][*][*],to_depth)
begin
    ;; for member,time,z,y,x
    dims = dimsizes(temp)
    nmember = dims(0)
    ohc = temp(:,:,0,:,:) ;; create array
    ohc = 0. ;;ohc@_FillValue
    ohc@long_name  = "Ocean heat content"
    ohc@units = "J/m2"
    ohc@thckness = to_depth
    do m = 0, nmember-1
        ohc(m,:,:,:) = cal_ohc_with_temp_salinity_TZLL(temp(m,:,:,:,:),salinity(m,:,:,:,:),to_depth)
    end do
    return ohc
end
function cal_salinity_with_temp_salinity_MTZLL(temp[*][*][*][*][*],salinity[*][*][*][*][*],to_depth)
begin
    ;; for member,time,z,y,x
    dims = dimsizes(temp)
    nmember = dims(0)
    mean_sal = temp(:,:,0,:,:) ;; create array
    mean_sal = 0. ;;ohc@_FillValue
    mean_sal@long_name  = "vertical mean salinity"
    mean_sal@units = "g/kg"
    mean_sal@thckness = to_depth
    do m = 0, nmember-1
        mean_sal(m,:,:,:) = cal_ohc_sal_with_temp_salinity_TZLL(temp(m,:,:,:,:),salinity(m,:,:,:,:),to_depth,"salinity")
    end do
    mean_sal = mean_sal/to_depth
    return mean_sal
end
