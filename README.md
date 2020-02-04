# What's it
diag_norcpm is a diagnostic package to plot the output data of NorCPM.
It do rank histogram and anomalous correction plots and generate index page with ensemble seasonal forecasts of NorCPM.

# Demo site
    http://158.39.77.150/index2.html

# Acceptable data structure and usage
example:
    if data path is 
        /path/to/model_version/["hindcast"]/runname_YYYYMMDD/ensemble_mem0-9/atm/hist/data.nc
        (["hindcast"] means the script can handle with and without "hindcast" directory)
    the command would be
        /path/to/diag_norcpm.sh  /path/to/model_version/["hindcast"]
    output figures (in each receipe sub-directory) will be
        ./model_version-runname

# Code structure
It contains a mainscript: diag_norcpm.sh
    which define the plot name and the directories of input data
    the recipe to do
    and directory to output plots.

A set of recipes: Recipes/
    contains the recipes
    recipe define the plot scripts to run and how to generate the plot script

A python script which do everything: doplot.py
    parse the recipes
    generate plot script which is assign in recipe
    run the plot script

A set of plot script: Codes/
    contain plot and proc script templates


# Process flow
```
-------------------
| diag_norcpm.sh  |  This script can be skip if plotCase.yml is present.
|   setup env.    |  (see below)
|   and variables |
-------------------
        |
        V
-------------------------------------
| doplot.py                         |
|   read and parse recipes          |
|   generate plot scripts in recipe |
|       Codes/gen_proc_plot.py      |
|   run scripts (parallelly or not) |
|   make html pages                 |
-------------------------------------
```

# plotCase.yml
    It is a yml file which contains all variables defined in diag_norcpm.sh.
    So if there is a plotCase.yml in output directory, than doplot.py can be executed directly.
    plotCase.yml will be generated automatically when running doplot.py.

    Here is an example of plotCase.yml
```
plotCase: NorCPM-Anomaly_coupled
BASEDIR: /tos-project4/NS9039K/shared/norcpm/cases/NorCPM/Anomaly_coupled
RUNPRE: acpl_19800115_me_hindcasts_
plotRecipes: 91_AnoCor_all.yml
outputDir: /nird/home/pgchiu/scratch/work/NorCPM-Anomaly_coupled
diag_norcpm_Root: /nird/home/pgchiu/scratch/diag_norcpm
DefaultYML: /nird/home/pgchiu/scratch/diag_norcpm/Defaults.yml
```

# Recipes and replace rules.
Each recipe take in charge one directory, defining how to generage plot script, and the variables for webpage. It also the minial unit of parallel processing in diag_norcpm.

The replacement will be take in place only for CAPITAL variables. Start from longest variables. Former replacement will be replace by latters. For example, in a snip of recipe:
```
NAME: sst
VARIABLE: NAME
```
Then the 'VARIABLE' will be replace to 'NAME' and then 'sst'. But if
```
THISISNAME: sst
VARIABLE: THISISNAME
```
Then the 'VARIABLE' will be 'THISISNAME' only, since it happen latter. It usually cause problem.

Another case is 
```
NAME: sst
VARIABLE: THISISNAME
```
Then the 'VARIABLE' will become 'THISISsst'. So be careful.


Multiple plotScripts can be defined in one recipe. There can be some kind of 'global variable' in recipe, and can be overide in Scripts section.

Here is an example:
    
```
Title: ENSO predictionskill  # for webpage
## following are 'global variables'
VARIABLE:  sst
REG: nino34

Scripts:  ## Scripts templates and replacements
-  
    plotScript: plot_forecast_correlation.ncl  ## define template
    FIGFILENAME: fig_cor_forecast_REG

```
The global variables are apply to all Scripts. The contain of plot_forecast_correlation.ncl will replaced with VARIABLE, FIGFILENAME and REG. The FIGFILENAME will become "fig_cor_forecast_nino34".

Special variables in recipes (TBD): Title, Description, Thumbnail(optional), Tags(optional), Depends(optional).

"Depends" is a special variable in recipe, which add additional recipes into poll and run after the additions.

Every recipe has it own work directory and an output log, shares same file name with the recipe.


# Code templates
    The code template is the manuscirpt to generate codes. All templates should be placed in Codes/ directory.
    Only NCL and bash script are accepted now.
    Templates contains all CAPTIAL variables to be replace. The replacements are defined in recipe.
    Default values can be defined in template. For a NCL example:
```
;;DIAG_NORCPM; FIGFILENAME: fig01
begin
    figfn = "FIGFILENAME"
    ....
    wks = gsn_open_wks("ps",figfn)
    ...
```
If FIGFILENAME is not set in recipe, it will be replace by 'fig01'. The key word for setting default value is ";DIAG_NORCPM; ". Here is a bash example:
```
#!/bin/bash
#;DIAG_NORCPM; HTMLFILENAME: index.html
htmlfn="HTMLFILENAME"
```

# mk_html_page.sh
This script convert postscript file to png, and generate gallery of figures with html. COLUMN defined the number and text in <table> tag.
For example, 
```
Script:
-
    plotScript: mk_html_page.sh
    FIGFILES:
        fig01
        fig02
        fig03
    COLUMN: 'Title01' 'tr' 1 'Title02' 'Title03' 'tr' 2
```
    The layout will become:
```
    Title01
    fig01
    Title02  Title03
    fig02    fig03
```


# Parallel processing 
Parallel processing is supported in doplot.py. The variable 'maxprocess' in doplot.py control the max number of recipes run at same time.
Becarefull, RLIMIT is set on some machine. If you enconter this kind of error, set maxprocess to 1.


# How it work
1. Setup run environment. Including script path and NCL (or other plotting language) environment.
2. Generate plot scripts, doplot.py replace strings in plot script template.
    The strings to be replace are defined in recipe and plot script template(as default value).
3. Run plot scripts, which produce figures, index.html and README for each receipt directories.
4. Generate index.html for each recipes.

