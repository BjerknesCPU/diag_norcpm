function rank_histogram_2d(ensmem[*][*][*][*],obs[*][*][*])
begin ;; too less sample with single point
    ;; Rank histogram

    ;; assume ensmem(time,member,y,x)
    ;;        obs(time,y,x)
    ;; return rank_freq(member+1,y,x)

    dims = dimsizes(ensmem)
    nt = dims(0)
    nmem = dims(1)
    ny = dims(2)
    nx = dims(3)

    rank_freq = new((/nmem+1,ny,nx/),"float")

    do y = 0,ny-1
    do x = 0,nx-1
        if(any(ismissing(ensmem(:,:,y,x))))then ;; if any missing 
            continue
        end if
        bins1p = new((/nmem+1/),"float") ;; count of 1 grid point
        bins1p = 0.

        do t = 0,nt-1
            ;; bin boundaries
            bounds := ensmem(t,:,y,x)
            qsort(bounds) ;; small to large
            ;; put obs(t,y,x) to one of bins
            ibin = min(ind(obs(t,y,x).lt.bounds))
            ibin = where(ismissing(ibin),nmem,ibin) ;; for obs > all bounds
            bins1p(ibin) = bins1p(ibin)+1.
        end do

        ;; cal freq. of bins and put to rank_freq
        rank_freq(:,y,x) = bins1p / nt

        delete(bounds)
        delete(bins1p)
    end do
    end do

    rank_freq!0 = "bin"
    rank_freq&bin = ispan(1,nmem+1,1)
    if(isatt(ensmem,"lat2d"))then
        rank_freq@lat2d = ensmem@lat2d
        rank_freq@lon2d = ensmem@lon2d
    else
        rank_freq!1 = ensmem!2
        rank_freq&$rank_freq!1$ = ensmem&$ensmem!2$
        rank_freq!2 = ensmem!3
        rank_freq&$rank_freq!2$ = ensmem&$ensmem!3$
    end if
    rank_freq@long_name = "Rank frequency"

    return rank_freq
end

