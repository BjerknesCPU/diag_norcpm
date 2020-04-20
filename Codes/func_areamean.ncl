function get_mask_lat2d_lon2d(lat2d[*][*],ilon2d[*][*],latbe[2],lonbe[2])
begin
    ;; get lat2d/lon2d mask from latbe/lonbe
    ;; return logical wgtmask(y,x)

    ;; align lon coordinate (simple version)
    if((any(lonbe.gt.180).and.any(lonbe.lt.0)).or.(any(lonbe.gt.360.) .or. any(lonbe.lt.-180.)))then
        print("get_mask_lat2d_lon2d(): lonbe should be 0-360 or -180-180 only.")
        print(lonbe)
        exit
    end if

    if(any(lonbe.lt.0))then ;; for -180 to 180
        lon2d = where(ilon2d.gt.180,ilon2d-360,ilon2d)
    else                    ;; for 0 to 360
        lon2d = where(ilon2d.lt.0,ilon2d+360,ilon2d)
    end if

    ;; make lat/lon mask
    wgtmask = .not.ismissing(lat2d)
    wgtmask = wgtmask .and. (lat2d.ge.min(latbe).and.lat2d.le.max(latbe))
    wgtmask = wgtmask .and. (lon2d.ge.min(lonbe).and.lon2d.le.max(lonbe))

    return wgtmask
end

function areamean_latbe_lonbe(var,latbe[2],lonbe[2])
begin
    ;; do var area mean with lat/lon range
    ;; var can be fix lat/lon or with lat2d/lon2d
    ;; assume var rightmost 2 dim is y,x(or lat,lon)

    dims = dimsizes(var)
    ndim = dimsizes(dims)
    ;;;; rightmost 2 dim: dims(ndim-2:ndim-1)

    ;; make weighting array
    ;wgt = new(dims(ndim-2:ndim-1),"float")

    ;;;; lat based weighting
    if(isatt(var,"lat2d"))then
        lat2d = var@lat2d
        lon2d = var@lon2d
        if(dimsizes(dimsizes(lat2d)).eq.1)then
            lat2d := onedtond(lat2d,dims(ndim-2:ndim-1))
            lon2d := onedtond(lon2d,dims(ndim-2:ndim-1))
        end if
        wgt = tofloat(NormCosWgtGlobe(lat2d))
    else ;; coordinate
        lats = var&lat ;; need modify to a more flexiable form
        lons = var&lon
        lat2d = conform_dims(dims(ndim-2:ndim-1),lats,0)
        lon2d = conform_dims(dims(ndim-2:ndim-1),lons,1)

        wgt = conform_dims(dims(ndim-2:ndim-1),NormCosWgtGlobe(lats),0)
        wgt!0 = "lat"
        wgt!1 = "lon"
        wgt&lat = lats
        wgt&lon = lons
    end if

    ;;;; apply lat/lon limit
    wgtmask = get_mask_lat2d_lon2d(lat2d,lon2d,latbe,lonbe)
        
    wgt = where(wgtmask,wgt,0)

    ;;;; normalize weighting
    wgt = wgt/sum(wgt)

    ;;;; areamean with weighting
    opt = 0 ;; use all available data
    mean = wgt_areaave2 (var,wgt,opt)
    mean!0 = var!0
    mean&$mean!0$ = var&$var!0$
    return mean
end
