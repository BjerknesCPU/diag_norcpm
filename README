# (Name of the package)


*diag_norcpm is a package to plot the output data from NorESM members.
  -as a goal.

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


flow chart
------------------
| diag_norcpm.sh |
|   plotCase     |
|   recipe(s)    |
|   input data   |
|   output dir   |
------------------
        |
        V
-------------------------------------
| doplot.py                         |
|   read and parse recipes          |
|   generate plot scripts in recipe |
|       Codes/gen_proc_plot.py      |
|   run scripts parallelly          |
-------------------------------------


How it work:
    Generate plot scripts, doplot.py replace strings in plot script template.
    The strings to be replace are defined in recipe and plot script template(as default value).
    See Codes/gen_proc_plot.py

