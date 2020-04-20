#!/bin/bash
#################################################################################
##  diag_norcpm
##      This package is used to plot figures for ensembled seasonal prediction.
##      Development for NorCPM.
##          
##                                            by Ping-Gin Chiu, start at 28Feb2019
##                                                                v2  at 23Apr2019
#################################################################################

#--------------------------- get data dir from argument -----------------------
## dirs as arguments, plot all figures
##      each dir in BASEDIR should contain members of simulation
##      if the member path: 
##              /path/to/model_ver/ana_19800115_me_hindcasts/ana_19800115_me_20090115/ana_19800115_me_20090115_mem09/atm/hist/
##      then the arguments should be:
##             /path/to/model_ver/ana_19800115_me_hindcasts
BASEDIR="${1}"
if [ -z "${BASEDIR}" ];then
    echo "$0 <hindcasts_dir>"
    exit
fi
BASEDIR="$(readlink -f ${BASEDIR}|head -n1)" ## make sure it is absolute path

#--------------------------- case settings begin -----------------------
# plotCase: name of this plot, get upper dirname
Dir=$(basename ${BASEDIR})
plotCase=$(basename $(dirname ${BASEDIR}))-${Dir} ## {model_ver}_{hindcasts}

# prefixRun: ana_19800115_me_  # 
RUNPRE=${Dir%hindcasts} # remove "hindcast" string
if [ -z "$(ls $BASEDIR/$RUNPRE* 2>/dev/null)" ]; then # if not, take first forecast run and remove tailling date
    RUNPRE=$(ls -d $BASEDIR/*_???????{0..9} 2>/dev/null |head -n1 )
    RUNPRE=$(basename $RUNPRE 2>/dev/null | sed "s/[0-9]\{8\}$//")
fi
if [ ! -z "$(ls $BASEDIR/$RUNPRE_* 2>/dev/null)" ]; then # if not, take first forecast run and remove tailling date
    RUNPRE=$(ls -d $BASEDIR/*_???????{0..9} 2>/dev/null |head -n1 )
    RUNPRE=$(basename $RUNPRE 2>/dev/null | sed "s/[0-9]\{8\}$//")
fi

# plotRecipes: figures you want to plot, if none or empty means *.yml in Recipes/, Split with comma
plotRecipes='mpiexm/A01_mpiexm_annualvar.yml'
plotRecipes='16_AnoCor_seaice_frac.yml'
plotRecipes='testing/14_AtlNino_predic_skill.yml'
plotRecipes='17_AnoCor_sst_alllead.yml,18_AnoCor_prec.yml,19_AnoCor_sst_obs.yml'
plotRecipes='mpiexm/A01_mpiexm_annualvar.yml,mpiexm/A03_dif_tsurf.yml'
plotRecipes='mpiexm/A01_mpiexm_annualvar.yml'
plotRecipes='mpiexm/A04_annualvar_global.yml'
plotRecipes='mpiexm/A05_dif_sst.yml,mpiexm/A06_dif_sst_NAtl.yml'
plotRecipes='mpiexm/A03_dif_tsurf.yml'
plotRecipes='testing/14_AtlNino_predic_skill.yml'
plotRecipes='mpiexm/A01_mpiexm_annualvar.yml,mpiexm/A03_dif_tsurf.yml'
plotRecipes='mpiexm/A01_mpiexm_annualvar.yml'
plotRecipes='mpiexm/A04_annualvar_global.yml'
plotRecipes='20_rank_histogram.yml,21_rank_histogram_obs.yml,22_rank_histogram_ano_obs.yml'
plotRecipes='testing/T01_topic.yml' # testing topical recipe
plotRecipes='17_AnoCor_sst_alllead.yml,18_AnoCor_prec.yml,14_AnoCor_sst_obs.yml'
plotRecipes='23_rank_histo_ts_ano.yml'
plotRecipes='1A_AnoCor_z700_obs.yml'
plotRecipes='mpiexm/A04_annualvar_global.yml'
plotRecipes='mpiexm/A04b_ctl_annualvar_global.yml'
plotRecipes='mpiexm/A04a_ctl_annualvar_global.yml'
plotRecipes='mpiexm/A04c_ctl_annualvar_global.yml'
plotRecipes='24_rank_histo_z700_ano.yml'
plotRecipes='19_AnoCor_tsfc_obs.yml'
plotRecipes='16_AnoCor_ohc_obs.yml'
plotRecipes='13_nino34_predic_skill.yml' # take ~1hr
plotRecipes='14_AnoCor_sst_obs.yml,15_AnoCor_prec_obs.yml'
plotRecipes='20_rank_histogram.yml'
plotRecipes=''
plotRecipes='mpiexm/A04d_ctl_annualvar_global.yml'
plotRecipes='mpiexm/A05d_dif_sst.yml'
plotRecipes='mpiexm/A10_clidif_zmld.yml'
plotRecipes='mpiexm/A20_varvar_zmld.yml'
plotRecipes='mpiexm/A10NAtl_clidif_zmld.yml,mpiexm/A20NAtl_varvar_zmld.yml'
plotRecipes='mpiexm/A05d_dif_sst.yml,mpiexm/A10_clidif_zmld.yml,mpiexm/A10NAtl_clidif_zmld.yml,mpiexm/A20NAtl_varvar_zmld.yml,mpiexm/A04d_ctl_annualvar_NAtl.yml,mpiexm/A06d_dif_sst_NAtl.yml'
plotRecipes='mpiexm/A11_clidif_amld.yml,mpiexm/A11NAtl_clidif_amld.yml,mpiexm/A21NAtl_varvar_amld.yml,mpiexm/A21_varvar_amld.yml,mpiexm/A20_varvar_zmld.yml'
plotRecipes='mpiexm/A20NAtl_varvar_zmld.yml'
plotRecipes='mpiexm/A12_clidif_amld_var.yml,mpiexm/A12NAtl_clidif_amld_var.yml'
plotRecipes='mpiexm/A13_clidif_ohc.yml,mpiexm/A13NAtl_clidif_ohc.yml'
plotRecipes='mpiexm/A13NAtl_clidif_ohc.yml'
plotRecipes='mpiexm/A05d_dif_sst.yml,mpiexm/A06d_dif_sst_NAtl.yml'
plotRecipes='mpiexm/A06d_dif_sst_NAtl.yml'
plotRecipes='mpiexm/A14_clidif_ohc200.yml,mpiexm/A15_clidif_ohc500.yml'
plotRecipes='mpiexm/A04d_ctl_annualvar_NAtl.yml'
plotRecipes='mpiexm/A23_varvar_ohc.yml,mpiexm/A24_varvar_ohc200.yml,mpiexm/A25_varvar_ohc500.yml,mpiexm/A16_clidif_ohc1000.yml,mpiexm/A04d_ctl_annualvar_global.yml,mpiexm/A04d_ctl_annualvar_NAtl.yml'
plotRecipes='mpiexm/A16_clidif_ohc1000.yml,mpiexm/A04d_ctl_annualvar_global.yml,mpiexm/A04d_ctl_annualvar_NAtl.yml,mpiexm/A20NAtl_varvar_zmld.yml,mpiexm/A20_varvar_zmld.yml,mpiexm/A21NAtl_varvar_amld.yml,mpiexm/A21_varvar_amld.yml'
plotRecipes='mpiexm/A06d_dif_sst_NAtl.yml,mpiexm/A10NAtl_clidif_zmld.yml,mpiexm/A11_clidif_amld.yml,mpiexm/A11NAtl_clidif_amld.yml,mpiexm/A12_clidif_amld_var.yml,mpiexm/A12NAtl_clidif_amld_var.yml,mpiexm/A13NAtl_clidif_ohc.yml,mpiexm/A20NAtl_varvar_zmld.yml,mpiexm/A21NAtl_varvar_amld.yml,mpiexm/A14NAtl_clidif_ohc200.yml,mpiexm/A15NAtl_clidif_ohc500.yml'
plotRecipes='mpiexm/A23_varvar_ohc.yml,mpiexm/A24_varvar_ohc200.yml,mpiexm/A25_varvar_ohc500.yml,mpiexm/A16_clidif_ohc1000.yml'
plotRecipes='mpiexm/A04d_ctlOnly_annualvar_global.yml,mpiexm/A05d_ctlOnly_dif_sst.yml'
plotRecipes='mpiexm/A99/A99E_f08_5AGCMs_NASPG_average_daily_weather_1180_08.yml'
plotRecipes='mpiexm/A99_plot_1day_weather.yml'
plotRecipes='mpiexm/A05d_ctlOnly_dif_sst.yml'
plotRecipes='mpiexm/A17_clidif_prec.yml,mpiexm/A04d_ctlOnly_annualvar_global.yml'
plotRecipes='mpiexm/A17NAtl_clidif_prec.yml'
plotRecipes='mpiexm/A17_clidif_prec.yml'
plotRecipes='mpiexm/A18_clidif_amoc.yml,mpiexm/A10NAtl_clidif_zmld.yml,mpiexm/A11NAtl_clidif_amld.yml'
plotRecipes='mpiexm/A18_clidif_amoc.yml'
plotRecipes='mpiexm/A99/A99E_f08_5AGCMs_NASPG_average_daily_weather_1180_01.yml'
plotRecipes='mpiexm/A30_daily_spect_sst.yml,mpiexm/A30subP_daily_spect_sst.yml,mpiexm/A31_daily_spect_abswind.yml,mpiexm/A31subP_daily_spect_abswind.yml,mpiexm/A32_daily_spect_qflux.yml,mpiexm/A32subP_daily_spect_qflux.yml'
plotRecipes='mpiexm/A30nino34_daily_spect_sst.yml'
plotRecipes='14_AnoCor_sst_obs.yml,22_rank_histogram_ano_obs.yml'
plotRecipes='mpiexm/A33_daily_spect_amld.yml,mpiexm/A33subP_daily_spect_amld.yml'
plotRecipes='mpiexm/A40_spect_ratio_sst_qflux.yml'
plotRecipes='mpiexm/A41_spect_ratio_amld_abswind.yml'
plotRecipes='90_ocnonly_with_obs.yml'
plotRecipes='91_AnoCor_all.yml'
#--------------------------- case settings end -------------------------


# Machine related settings 
#--------------------------- machine settings begin -----------------------
## figures and webpages output directory, default is "$(pwd)/${plotCase}"
outputDir="$(pwd)/${plotCase}"

## observation or reanalysis data to compare, not done yet, heavily depends on machine
#### set OBSDIR in Defaults.yml
####obsDataDir='/cluster/projects/nn9039k/NorCPM/Obs'


## root directory of this package, sould contain doplot.py
diag_norcpm_Root="${HOME}/scratch/diag_norcpm"

## root directory of this package, sould contain doplot.py
defaultRecipe="${diag_norcpm_Root}/Defaults.yml"

## python used to run doplot.py, develop with python3.4, but other version should ok.
if [[ $(hostname) =~ .*fram.sigma2.no ]] ; then ## Fram
    module -q purge
    module -q load NCO/4.7.2-intel-2018a
    module -q load CDO/1.9.3-intel-2018a
    module -q load NCL/6.5.0-intel-2018a
    module -q unload LibTIFF/4.0.9/GCCcore-6.4.0
    module -q load Python/3.6.4-intel-2018a
fi

PYTHON=$(which python)
NCL=$(which ncl)
#--------------------------- machine settings end -----------------------

# do plot
export plotCase BASEDIR plotRecipes RUNPRE
export outputDir diag_norcpm_Root defaultRecipe
export PYTHON NCL
echo '================================= diag settings:'
echo "plotCase:    ${plotCase}"
echo "Data dir:    ${BASEDIR}"
echo "Case prefix: ${RUNPRE}"
echo "outputDir:   ${outputDir}"
echo '================================= '

"$PYTHON" "${diag_norcpm_Root}/doplot.py"