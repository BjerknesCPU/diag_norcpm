function regline_stats_T_TLL(x[*],y[*][*][*])
begin
    ;; frontend of regline_ststs()
    ;; 
    ;; see https://www.ncl.ucar.edu/Document/Functions/Contributed/regline_stats.shtml

    nt = dimsizes(x)
    ydims = dimsizes(y)
    if(nt.ne.ydims(0))then
        print("regline_stats_T_TLL(): time dimensions are not match.")
        print("regline_stats_T_TLL(): "+nt+", "+ydims(0))
        exit
    end if

    ;; just for convinent
    y2dims = ydims
    y2dims(0) = 2

    regmap = new(ydims(1:),typeof(y))
    ;; all statistical info
    bstd = new(ydims(1:),typeof(y))
    SST = new(ydims(1:),typeof(y))
    SSE = new(ydims(1:),typeof(y))
    SSR = new(ydims(1:),typeof(y))
    MST = new(ydims(1:),typeof(y))
    MSE = new(ydims(1:),typeof(y))
    MSE_dof = new(ydims(1:),typeof(y))
    MSR = new(ydims(1:),typeof(y))
    RSE = new(ydims(1:),typeof(y))
    RES_dof = new(ydims(1:),typeof(y))
    F = new(ydims(1:),typeof(y))
    F_dof = new(ydims(1:),typeof(y))
    F_pval = new(ydims(1:),typeof(y))
    r2 = new(ydims(1:),typeof(y))
    r = new(ydims(1:),typeof(y))
    r2a = new(ydims(1:),typeof(y))
    fuv = new(ydims(1:),typeof(y))
    Yest = new(ydims,typeof(y))
    Yavg = new(ydims(1:),typeof(y))
    Ystd = new(ydims(1:),typeof(y))
    Xavg = new(ydims(1:),typeof(y))
    Xstd = new(ydims(1:),typeof(y))
    stderr = new(y2dims,typeof(y))
    tval = new(y2dims,typeof(y))
    pval = new(y2dims,typeof(y))
    b95 = new(y2dims,typeof(y))
    y95 = new(y2dims,typeof(y))
    YMR025 = new(ydims,typeof(y))
    YMR975 = new(ydims,typeof(y))
    YPI025 = new(ydims,typeof(y))
    YPI975 = new(ydims,typeof(y))

    do j = 0,ydims(1)-1
    do i = 0,ydims(2)-1
        e = regline_stats(x,y(:,j,i))
        regmap(j,i) = (/e/)

        bstd(j,i) = e@bstd(1)
        SST(j,i) = e@SST
        SSE(j,i) = e@SSE
        SSR(j,i) = e@SSR
        MST(j,i) = e@MST
        MSE(j,i) = e@MSE
        MSE_dof(j,i) = e@MSE_dof
        MSR(j,i) = e@MSR
        RSE(j,i) = e@RSE
        RSE_dof(j,i) = e@RSE_dof
        F(j,i) = e@F
        F_dof(j,i) = e@F_dof(1)
        F_pval(j,i) = e@F_pval
        r2(j,i) = e@r2
        r(j,i) = e@r
        fuv(j,i) = e@fuv
        Yest(j,i) = e@Yest
        Yavg(j,i) = e@Yavg
        Ystd(j,i) = e@Ystd
        Xavg(j,i) = e@Xavg
        Xstd(j,i) = e@Xstd
        stderr(j,i) = e@stderr
        tval(j,i) = e@tval
        pval(j,i) = e@pval
        b95(j,i) = e@b95
        y95(j,i) = e@y95
        YMR025(j,i) = e@YMR025
        YMR975(j,i) = e@YMR975
        YPI025(j,i) = e@YPI025
        YPI975(j,i) = e@YPI975

        delete(e)
    end do
    end do

    ;; assign as attitude
        regmap@bstd = bstd
        regmap@SST = SST
        regmap@SSE = SSE
        regmap@SSR = SSR
        regmap@MST = MST
        regmap@MSE = MSE
        regmap@MSE_dof = MSE_dof
        regmap@MSR = MSR
        regmap@RSE = RSE
        regmap@RSE_dof = RSE_dof
        regmap@F = F
        regmap@F_dof = F_dof
        regmap@F_pval = F_pval
        regmap@r2 = r2
        regmap@r = r
        regmap@fuv = fuv
        regmap@Yest = Yest
        regmap@Yavg = Yavg
        regmap@Ystd = Ystd
        regmap@Xavg = Xavg
        regmap@Xstd = Xstd
        regmap@stderr = stderr
        regmap@tval = tval
        regmap@pval = pval
        regmap@b95 = b95
        regmap@y95 = y95
        regmap@YMR025 = YMR025
        regmap@YMR975 = YMR975
        regmap@YPI025 = YPI025
        regmap@YPI975 = YPI975

    return regmap
end
