# What's it
    diag_norcpm is a diagnostic package to plot the output data of NorCPM.

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
| diag_norcpm.sh  |
|   setup env.    |
|   and variables |
-------------------
        |
        V
-------------------------------------
| doplot.py                         |
|   read and parse recipes          |
|   generate plot scripts in recipe |
|       Codes/gen_proc_plot.py      |
|   run scripts parallelly          |
|   make html pages                 |
-------------------------------------
```


# How it work
    1. Setup run environment. Including script path and NCL (or other plotting language) environment.
    2. Generate plot scripts, doplot.py replace strings in plot script template.
        The strings to be replace are defined in recipe and plot script template(as default value).
    3. Run plot scripts, which produce figures, index.html and README for each receipt directories.
    4. Generate index.html for each recipes.

