#!/usr/bin/python3

import os,sys,re
import yaml
import subprocess as sp
from multiprocessing import Process
from Codes.gen_proc_plot import gen_proc_plot
try: # use to parse index.html in recipe directories
    import bs4
    isbs4 = True
except:
    isbs4 = False
    

# get envrionment variables
plotCase            = os.environ.get('plotCase')
ensDataDirs         = os.environ.get('ensDataDirs').split()
plotRecipes        = os.environ.get('plotRecipes')
outputDir           = os.environ.get('outputDir')
obsDataDir          = os.environ.get('obsDataDir')
diag_norcpm_Root    = os.environ.get('diag_norcpm_Root')
DefaultYML          = os.environ.get('defaultRecipe')

# default directories and setting, begin -------------------------------------------------
RecipeDir      = diag_norcpm_Root+'/Recipes/'
CodeDir         = diag_norcpm_Root+'/Codes/'
# default directories and setting, end -------------------------------------------------


# checking environment variables, begin ---------------------------------------
if not plotCase:
    print("plotCase is needed.")
    sys.exit()
if not ensDataDirs:
    print("ensDataDirs is needed.")
    sys.exit()
if not diag_norcpm_Root:
    print("diag_norcpm_Root cannot be remove.")
    print("    which contains doplot.py and recipes directory")
    sys.exit()
# checking environment variables, end -----------------------------------------

# read Defaults, begin -----------------------------------------
with open(DefaultYML,'r') as j:
    try:
        Defaults = yaml.load(j,Loader=yaml.BaseLoader)
    except yaml.YAMLError as exc:
        print(exc)
#
# read Defaults, end -----------------------------------------

# list Recipes, begin -----------------------------------------
if not plotRecipes:
    plotRecipes = []
    files = os.listdir(RecipeDir)
    files.sort()
    for i in files:
        if re.match('.*\.(?:yml|json)$',i): plotRecipes.append(i) # accept yaml and json
else:
    plotRecipes = plotRecipes.split(',')

if not plotRecipes:
    print("No recipe in "+RecipeDir+" or script")
    sys.exit()
# list Recipes, end -----------------------------------------


# Step 1 - parse recipes, begin ------------------------------------------------
print('plot recipes: '+','.join(plotRecipes))
## before process
if not os.path.exists(outputDir): os.makedirs(outputDir)
## parse recipes
Recipes = []
for i in plotRecipes:
    # i is the filename, it may be contain path, './', or just filename
    # search dir order: '.', ''(absolute path), RecipeDir
    thedir = RecipeDir
    if os.path.isfile(i): thedir = ''
    if os.path.isfile('./'+i): thedir = './'

    with open(thedir+'/'+i,'r') as j: # open and parse recipe
        try:
            Rsuffix = os.path.splitext(i)[1]
            if Rsuffix == '.yml':
                recipe = yaml.load(j,Loader=yaml.BaseLoader)
            elif Rsuffix == '.json':
                recipe = json.load(j)
            else:
                print("doplot.py: unsupport file: "+i)
                sys.exit()

        except:
                print(exc)
                sys.exit()
            
        #### check data structure, should be:
        #### {title,desc,Depend,Scripts:[{script1},{script2}]}

        recipe_name = os.path.splitext(os.path.basename(i))[0]

        if type(recipe) == dict: ## if things look good
            pass
        elif type(recipe) == list: ## assume it just a list of plotScripts
            new_recipe = dict()
            new_recipe.update({'Title':recipe_name,'Description': recipe_name, 'Scripts': recipe})
            recipe = new_recipe

        #### add variables defined in diag_norcpm.sh
        recipeRootfn = os.path.splitext(os.path.basename(i))[0]
        recipe.update({'OBSDIR':obsDataDir})
        recipe.update({'CODEDIR':CodeDir})
        recipe.update({'INPUTDIRS':ensDataDirs})
        recipe.update({'recipeName':recipe_name})

        #### check array, change it to string
        for s in recipe.get("Scripts"): ## should be an array
            suffix = os.path.splitext(s.get("plotScript"))[1]
            for k in s.keys(): ## each key
                if type(s.get(k)) == list:
                    if suffix in ['.ncl','.py']:
                        s.update({k:",".join(['"'+i+'"' for i in ensDataDirs])})
                    elif suffix == 'sh':
                        s.update({k:" ".join([i for i in ensDataDirs])})
                    else:
                        print('not sure how to express array in '+s.get('plotScript'))
        Recipes.append(recipe)

### generate run script use plotScript with variables
#### Recipes: list of recipes
#### [{title,desc,Depend,Scripts:[{script1},{script2}]},{},{}]
AllScripts = dict() ## store all generated scripts, {recipe1: [s1,s2,s3], recipe2:[r1,r2],...}
for recipe in Recipes:
    title = recipe.get("Title")
    desc = recipe.get('Description')
    scripts = recipe.get("Scripts")
    recipeName = recipe.get("recipeName")
    AllScripts[recipeName] = list()
    if not os.path.exists(outputDir+'/'+recipeName): os.makedirs(outputDir+'/'+recipeName)
 
    # write README
    open(outputDir+'/'+recipeName+'/README',"w").write('Title: '+title+'\nDescription: '+desc+'\n')

    # get all capital in recipe
    baseDict = dict()
    for i in  recipe.keys():
        if i.isupper(): baseDict.update({i:recipe.get(i)})

    # make scriptDict
    num = 0
    for script in scripts:
        scriptDict = Defaults.copy()
        scriptDict.update(baseDict.copy())
        for i in  script.keys():
            if i.isupper(): scriptDict.update({i:script.get(i)})
        
        # generate script
        if not os.path.exists(CodeDir+'/'+script.get("plotScript")):
            print(CodeDir+'/'+script.get("plotScript")+" not exist, skip")
            continue
        res = gen_proc_plot(open(CodeDir+'/'+script.get("plotScript"),'r').read(),scriptDict)
        fn = str(num)+'-'+script.get("plotScript")
        open(outputDir+'/'+recipeName+'/'+fn,"w").write(res)
        num += 1

        AllScripts[recipeName].append(fn)
        
    


### output runall script
#### AllScripts store all generated scripts, {recipe1: [s1,s2,s3], recipe2:[s1,s2],...}
runallTxt=''
os.chdir(outputDir)
for r in AllScripts.keys():
    runallTxt += 'cd '+outputDir+'/'+r+'\n'
    runallTxt += '    echo "running plot set: '+r+'"\n'
    logfile = outputDir+'/'+r+'.log'
    for fn in AllScripts.get(r):
        rootfn,suffix = os.path.splitext(fn)
        if suffix == '.ncl': 
            cmd = 'ncl'
        elif suffix == '.m': 
            cmd = 'matlab'
        elif suffix == '.py': 
            cmd = 'python'
        elif suffix == '.sh': 
            cmd = 'sh'
        else: 
            cmd = 'sh'  # bad idea

        runallTxt += '    echo ">>>>>>>>>>>>>  running '+fn+'"\n'
        runallTxt += '    echo ">>>>>>>>>>>>>  running '+fn+'"    >> '+logfile+'\n'
        runallTxt += '    '+cmd+' '+fn+' >> '+logfile+'\n'
    runallTxt += 'cd '+outputDir+'\n'
open('runall.sh','w').write(runallTxt)

### run all (parallel)
### AllScripts store all generated scripts, {recipe1: [s1,s2,s3], recipe2:[r1,r2],...}
#### function for threading
def run_seq(workdir,scripts,logfile):
    os.chdir(workdir)
    logf = open(logfile,'w')
    for fn in scripts:
        rootfn,suffix = os.path.splitext(fn)
        if suffix == '.ncl': 
            cmd = 'ncl'
        elif suffix == '.m': 
            cmd = 'matlab'
        elif suffix == '.py': 
            cmd = 'python'
        elif suffix == '.sh': 
            cmd = 'sh'
        else: 
            cmd = 'sh'  # bad idea
        print('    running '+cmd+' '+workdir+'/'+fn)
        logf.write('>>>>>>>>>>>>>>>> running '+cmd+' '+fn+'\n')
        sp.run([cmd,fn],stdout=logf,stderr=logf)
    
#### make and run process list
procall = []
for r in AllScripts.keys():
    logfile = outputDir+'/'+r+'.log'
    workdir = outputDir+'/'+r
    p = Process(target=run_seq,args=(workdir,AllScripts[r],logfile))
    p.start()
    print('running '+r+' at pid='+str(p.pid))
    procall.append(p)
    
#### wait all  process done
for p in procall:
    p.join()

### make index.html for all directories
os.chdir(outputDir)
#### grab index.html and thumbnail in subdirectories
recipeInfo = dict()
subdirs = [ i for i in os.listdir('.') if os.path.isdir(i)]
subdirs.sort()
for i in subdirs:
    thumbnail = ''
    description = ''
    # try index.html
    if isbs4: # if bs4 present and there is index.html in subdir
        indexfile =  [ j for j in os.listdir(i) if re.match(".*index..*",j) ] [0]
        if indexfile:
            thumbnail = ''
            description = ''

    # try README in yaml format
    with open(i+'/README','r') as j:
        try:
            readme = yaml.load(j,Loader=yaml.BaseLoader)
            if readme.get('Title'): title = readme.get('Title')
            if readme.get('Description'): description = readme.get('Description')
        except:
            pass

    # if none of above
    if not thumbnail: 
        thumbnail = [ j for j in os.listdir(i) if re.match(".*thumb.png",j) ]
        if thumbnail: 
            thumbnail = thumbnail[0]
        else:
            print("no thumbnail in "+i)
            #print([ j for j in os.listdir(i) ])
            thumbnail = ''
    if not description:
        description = i
    if not title:
        title = i
    # store it
    recipeInfo.update({i:{'title': title, 'thumb': thumbnail, 'desc': description}})

#### html header
html = ''
html += '<!DOCTYPE html> \n'
html += '<html> \n'
html += '<body> \n'

#### title
html += '<h3>diag_norcpm:</h3><h1>'+plotCase+'</h1>\n'
html += '<hr>\n'
#### recipe items
dirs = recipeInfo.keys()
for i in dirs:
    r = recipeInfo[i]
    html += "<span style='display:inline-block'>"
    html += '<a href="'+i+'">'
    html += '<h4>'+r['title']+'</h4>'
    if r.get('thumb'): html += ''+'<img  ALIGN="left" src="'+i+'/'+r['thumb']+'">'
    html += '</a>\n'
    html += '<p>'+r['desc']+'</p>'
    html += '</br> \n'
    html += '</span>\n'
    html += '</br> \n'
    html += '<hr> \n'

#### html footer
html += '</body> \n'
html += '</html> \n'

#### write index html
open("index.html",'w').write(html)

