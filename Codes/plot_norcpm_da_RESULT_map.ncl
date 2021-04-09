;; plot_norcpm_da_RESULT_map.ncl
;; plot RESULT from NorCPM run directory

;;DIAG_NORCPM; MINLAT: -90.
;;DIAG_NORCPM; MAXLAT:  90.
;;DIAG_NORCPM; MINLON:   0.
;;DIAG_NORCPM; MAXLON: 360.
;;DIAG_NORCPM; OCNGRIDFILE: ../../Data/grid.nc
;;DIAG_NORCPM; FIGFILENAME: fig
;;DIAG_NORCPM; PROJECTION: CylindricalEquidistant
;;DIAG_NORCPM; BEFOREPLOT: 
    ;; modify figure from recipt
;;DIAG_NORCPM; STD_DOTSHADELOWER: .2
    ;; stddev lower than this will shaded by dot
;;DIAG_NORCPM; STD_LINESHADEHIGHER: 2
    ;; stddev higher than this will shaded by vertical lines
;;DIAG_NORCPM; SHADEHIGH: 2
    ;; higher shade pattern, =2 means vertical lines
;;DIAG_NORCPM; SHADELOW: 17
    ;; lower shade pattern, =17 means dots


load "CODEDIR/func_read_all_members.ncl"

function read_RESULTs(dirs[*]:string,varname[1]:string)
begin
    ;; read data from RESULT dir of NorCPM

    datafn = "observations-SST.nc"
    enkffn = "enkf_diag_1.nc"
    nt = dimsizes(dirs)  ;; one time per dir
    if (nt.eq.1)then  ;; assign first dir
        dir0 = dirs
    else
        dir0 = dirs(0)
    end if

    ;; Get the dimension size from enkf_diag_1.nc in dir0
    f0 = addfile(dir0+"/"+datafn,"r")
    enkff = addfile(dir0+"/"+enkffn,"r")
    dims = array_append_record(nt,getfiledimsizes(enkff),0)

    var = new(dims,"float")  ;; set to float...

    ;; fill the data array
    do t = 0, nt-1
        dataf = addfile(dirs(t)+"/"+datafn,"r")
        ipiv = dataf->ipiv
        jpiv = dataf->jpiv
        var1d = dataf->$varname$
        do n = 0, dimsizes(var1d)-1
            var(t,jpiv(n),ipiv(n)) =  tofloat(var1d(n))
        end do

        delete(dataf)
        delete(ipiv)
        delete(jpiv)
    end do

    return var
    
end

begin
    ;; RESULT directory: path/to/noresm/run/dir/RESULT/1980_01/observations-SST.nc
    ;; Plot innovation first.

    ;; Get dirs
    result_dirs = systemfunc("ls -d RESULTDIRS")

    fns = systemfunc("ls INPUTFILES")
    varname = "VARIABLE"
    component = "COMPONENT"
    outfig = "FIGFILENAME"
    obsdir = "OBSDIR"
    ocngridfile = "OCNGRIDFILE"
    projection = "PROJECTION"

    std_lower = STD_DOTSHADELOWER
    std_higher= STD_LINESHADEHIGHER

    nmem = dimsizes(fns)

    ;; read all (member,t,y,x)
    var_mems = read_all_files_var(fns,varname,ocngridfile)

    ;; ens mean (t,y,x)
    var_ensavg  = dim_avg_n_Wrap(var_mems,0)
    var_ensstd  = dim_stddev_n_Wrap(var_mems,0)

    dims = dimsizes(var_ensavg)
    nt = dims(0)
    
    res = True
        res@mpMinLatF = MINLAT
        res@mpMaxLatF = MAXLAT
        res@mpMinLonF = MINLON
        res@mpMaxLonF = MAXLON
        res@mpProjection = projection
        if(res@mpProjection .eq. "LambertConformal")then
            res@gsnMaskLambertConformal = True
        end if

        res@gsnDraw     = False
        res@gsnFrame    = False
        res@cnFillOn    = True
        ;res@cnFillMode  = "CellFill"
        res@cnLinesOn   = False
        res@lbOrientation     = "Horizontal"
        res@gsnAddCyclic = True
        
    res2 = True ;; for shade on filled contour
        res2@cnLinesOn = False
        res2@cnLineLabelsOn = False
        res2@gsnDraw = False
        res2@gsnFrame = False
        res2@gsnLeftString = ""
        res2@gsnRightString = ""
        
    resShade = True
        resShade@gsnShadeFillType = "pattern"
        resShade@gsnShadeHigh   = SHADEHIGH
        resShade@gsnShadeLow = SHADELOW
    BEFOREPLOT

    wks = gsn_open_wks("ps","FIGFILENAME")
    do i = 0,nt-1
        plot_fill = gsn_csm_contour_map(wks,var_ensavg(i,:,:),res)

        plot_shade = gsn_csm_contour(wks,var_ensstd(i,:,:),res2)
        plot_shade = gsn_contour_shade(plot_shade,std_lower,std_higher,resShade)
        overlay(plot_fill,plot_shade)
        draw(plot_fill)
        frame(wks)
    end do
end
