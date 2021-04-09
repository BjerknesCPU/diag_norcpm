#!/usr/bin/python3

import os,sys,re,time,traceback
import yaml
import subprocess as sp
from multiprocessing import Pool
from Codes.gen_proc_plot import gen_proc_plot
try: # use to parse index.html in recipe directories
    import bs4
    isbs4 = True
except:
    isbs4 = False
    
maxprocess = 1
dryrun = False
plotCaseYML = 'plotCase.yml'
ReadENV = True
if os.path.exists(plotCaseYML) and ReadENV: # read plotCaseYML instead of environment
    with open(plotCaseYML,'r') as j:
        try:
            plotSettings = yaml.load(j,Loader=yaml.BaseLoader)
            plotCase            = plotSettings.get('plotCase')
            BASEDIR             = plotSettings.get('BASEDIR')
            RUNPRE              = plotSettings.get('RUNPRE')
            plotRecipes         = plotSettings.get('plotRecipes')
            outputDir           = plotSettings.get('outputDir')
            diag_norcpm_Root    = plotSettings.get('diag_norcpm_Root')
            DefaultYML          = plotSettings.get('DefaultYML')
            dryrun              = plotSettings.get('Dryrun') or dryrun
            maxprocess          = plotSettings.get('Maxprocess')
            ReadENV = False
        except yaml.YAMLError as exc:
            print(exc)
else:
    plotCase            = os.environ.get('plotCase')
    BASEDIR            = os.environ.get('BASEDIR')
    RUNPRE             = os.environ.get('RUNPRE')
    plotRecipes        = os.environ.get('plotRecipes')
    outputDir           = os.environ.get('outputDir')
    diag_norcpm_Root    = os.environ.get('diag_norcpm_Root')
    DefaultYML          = os.environ.get('defaultRecipe')

    
    ymltext = ''
    ymltext += 'plotCase: '+plotCase+'\n'
    ymltext += 'BASEDIR: '+BASEDIR+'\n'
    ymltext += 'RUNPRE: '+RUNPRE+'\n'
    ymltext += 'plotRecipes: '+plotRecipes+'\n'
    ymltext += 'outputDir: '+outputDir+'\n'
    ymltext += 'diag_norcpm_Root: '+diag_norcpm_Root+'\n'
    ymltext += 'DefaultYML: '+DefaultYML+'\n'
    if not os.path.exists(outputDir): os.makedirs(outputDir)
    with open(outputDir+'/'+plotCaseYML,'w') as j:
        j.write(ymltext)

if dryrun in [False,"False",'no','NO','No']: dryrun = False
if maxprocess:
    maxprocess = int(maxprocess)
else:
    maxprocess = 1
# default directories and setting, begin -------------------------------------------------
RecipeDir      = diag_norcpm_Root+'/Recipes/'
CodeDir         = diag_norcpm_Root+'/Codes/'
# default directories and setting, end -------------------------------------------------


# checking environment variables, begin ---------------------------------------
if not plotCase:
    print("plotCase is needed.")
    sys.exit()
if not BASEDIR:
    print("BASEDIR is needed.")
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
    plotRecipes = re.split(',| ',plotRecipes)

if not plotRecipes:
    print("No recipe in "+RecipeDir+" or script")
    sys.exit()
# list Recipes, end -----------------------------------------

#### makefile and runall.sh for rerun the recipes
os.chdir(outputDir)
updateTxt  = 'cd .. \n'
updateTxt += diag_norcpm_Root+'/diag_norcpm.sh '+BASEDIR+'\n'
open('update.sh','w').write(updateTxt)
Dirname = outputDir.split('/')[-1]
makefileTxt = f'''
replot:
	time python3 {diag_norcpm_Root}/doplot.py
upload:
	cd ../ ; ~/exec/public {Dirname} ; cd -
all: replot upload
'''
if not os.path.isfile('Makefile'):
    with open('Makefile','w') as f:
        f.write(makefileTxt)

# Step 1 - parse recipes, begin ------------------------------------------------
print('plot recipes: '+','.join(plotRecipes))
## parse recipes
def parseRecipes(i):
    ''' i is the filename, it may be contain path, './', or just filename
        search dir order: '.', ''(absolute path), RecipeDir
    '''
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
                traceback.print_exc()
                sys.exit()
            
        #### check data structure, should be:
        #### {title,desc,Depend,Scripts:[{script1},{script2}]}

        recipe_name = os.path.splitext(os.path.basename(i))[0]
        recipe_filename = os.path.splitext(os.path.basename(i))

        if type(recipe) == dict: ## if things look good
            pass
        elif type(recipe) == list: ## assume it just a list of plotScripts
            new_recipe = dict()
            new_recipe.update({'Title':recipe_name,'Description': recipe_name, 'Scripts': recipe})
            recipe = new_recipe

        #### add variables defined in diag_norcpm.sh
        recipeRootfn = os.path.splitext(os.path.basename(i))[0]
        recipe.update({'CODEDIR':CodeDir})
        recipe.update({'BASEDIR':BASEDIR})
        recipe.update({'RUNPRE':RUNPRE})
        recipe.update({'recipeName':recipe_name})
        recipe.update({'recipeFileName':recipe_filename})

        #### check array, change it to string
        if False : # v1 code, ensDataDirs is not used in v2
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
        return recipe

Recipes = []
for i in plotRecipes:
    Recipes.append(parseRecipes(i))

## check add dependency
recipesName = [ i.get('recipeName') for i in Recipes ]
depends = [i.get('Depends') for i in Recipes if i.get('Depends')]
didit = True
while didit: 
    didit=False
    for i in depends:
        for j in re.split(' |,',i):
            if not re.sub(".*/","",j.replace(".yml",'')) in recipesName:
                Recipes.append(parseRecipes(j))
                print("due to depends, add "+j)
                didit = True
    recipesName = [ k.get('recipeName') for k in Recipes ]
        
    

### generate run script use plotScript with variables
#### Recipes: list of recipes
#### [{title,desc,Depend,Scripts:[{script1},{script2}]},{},{}]
AllScripts = dict() ## store all generated scripts, {recipe1: [s1,s2,s3], recipe2:[r1,r2],...}
Depends = dict()
#for r in Recipes:
#    print(r.get('recipeName'))
#    print(r)
#print(type(Recipes))
#sys.exit()
for recipe in Recipes:
    title = recipe.get("Title")
    desc = recipe.get('Description')
    thumbnail = recipe.get("Thumbnail") 
    recipeName = recipe.get("recipeName")
    depends = recipe.get("Depends")
    scripts = recipe.get("Scripts")
    showinindex = recipe.get("ShowInIndex") or "Yes"
    tags = recipe.get("Tags") or "['misc']"
    AllScripts[recipeName] = list()
    if depends:
        Depends[recipeName] = re.split(' |,',depends)
    else:
        Depends[recipeName] = None

    if not os.path.exists(outputDir+'/'+recipeName): os.makedirs(outputDir+'/'+recipeName)
 
    # write README, as a description of this plot
    readmetext = 'Title: "'+title+'"\nDescription: "'+desc+'"\n'
    readmetext += 'ShowInIndex: '+showinindex+'\n'
    readmetext += 'Tags: '+str(tags)+'\n'
    if thumbnail: readmetext+='Thumbnail: "'+thumbnail+'"\n'
    with open(outputDir+'/'+recipeName+'/README',"w") as f:
        f.write(readmetext)

    # get all capital in recipe
    baseDict = dict()
    for i in  recipe.keys():
        if i.isupper(): baseDict.update({i:recipe.get(i)})

    # make scriptDict and generate plot script
    num = 0
    for script in scripts:
        scriptDict = Defaults.copy() ## apply Defaults.yml
        scriptDict.update(baseDict.copy()) ## apply recipe
        ## unpack varPack, which is an array, used to apply variable set in recipe
        if script.get('varPack'):
            vp = script.get('varPack')
            if type(vp) == type('str'):  # not an array
                vp = [ a.strip() for a in vp.split(',') ]
            for j in vp:
                for i in recipe.get(j):
                    script.update({i:recipe[j].get(i)})

        for i in  script.keys():
            if i.isupper(): scriptDict.update({i:script.get(i)})
        
        # generate script
        if not os.path.exists(CodeDir+'/'+script.get("plotScript")):
            print(CodeDir+'/'+script.get("plotScript")+" not exist, skip")
            continue
        res = gen_proc_plot(open(CodeDir+'/'+script.get("plotScript"),'r').read(),scriptDict)
        fn = str(num)+'-'+os.path.basename(script.get("plotScript"))
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
    ## remove old log
    try:
        os.remove(logfile)
    except:
        pass
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

### output update script


### run all (parallel)
### AllScripts store all generated scripts, {recipe1: [s1,s2,s3], recipe2:[r1,r2],...}
#### function for threading
def run_seq(workdir,scripts,logfile):
    os.chdir(workdir)
    nscript = str(len(scripts))
    #print('    '+os.path.basename(workdir)+': start at ',datetime.now.strftime("%d/%m/%Y %H:%M:%S"))
    #print('    '+os.path.basename(workdir)+': start ')
    logf = open(logfile,'w')
    for fn in scripts:
        n = str(scripts.index(fn)+1)
        rootfn,suffix = os.path.splitext(fn)
        if suffix == '.ncl': 
            cmd = 'ncl -Q'
        elif suffix == '.m': 
            cmd = 'matlab'
        elif suffix == '.py': 
            cmd = 'python'
        elif suffix == '.sh': 
            cmd = 'sh'
        else: 
            cmd = 'sh'  # bad idea
        #print('    running '+cmd+' '+workdir+'/'+fn)
        print('    '+os.path.basename(workdir)+'('+n+'/'+nscript+'): '+fn)
        logf.write('>>>>>>>>>>>>>>>> running '+cmd+' '+fn+'\n')
        logf.flush()
        if dryrun:
            print("        dryrun: "+cmd+" "+fn)
        else:
            start = time.perf_counter()
            #sp.run([cmd,fn],stdout=logf,stderr=logf)
            sp.run(' '.join([cmd,fn]),shell=True,stdout=logf,stderr=logf)
            end = time.perf_counter()
            logf.write('>>>>>>>>>>>>>>>> '+cmd+' '+fn+' [done with %2.2f secs.]\n'%(end-start))
            logf.flush()
    logf.close()

#### make and run process list
###### run no depend first
pool = Pool(processes=maxprocess)
Running = list()
Waiting = list()
for r in AllScripts.keys():
    if Depends[r]: 
        Waiting.append(r)
    else:
        logfile = outputDir+'/'+r+'.log'
        workdir = outputDir+'/'+r
        p = pool.apply_async(run_seq,(workdir,AllScripts[r],logfile))
        p.name = r # dependency
        print('Pooling '+p.name)
        Running.append(p)
    
if not Running:
    print("No recipe be able to run, exit.")
    sys.exit()

###### check process end every 3 sec, bad idea 
StillWaiting = True
while StillWaiting:
    time.sleep(3)
    StillWaiting = False
    ## update RunDone
    RunDone = list()
    RunningNames = list()
    InQueue  = list()
    for p in Running:
        RunningNames.append(p.name)
        if p.ready(): 
            RunDone.append(p.name)
        else:
            InQueue.append(p.name)
    ## update Waiting.txt
    Waiting = [ i for i in Waiting if not i in RunningNames ]
    if Waiting: StillWaiting = True
    with open('Waiting.txt','w') as wf:
        wf.write('InQueue: '+str(InQueue)+'\n')
        wf.write('RunDone: '+str(RunDone)+'\n')
        wf.write('Waiting: '+str(Waiting)+'\n')

    for n in Waiting:
        DepsDone = True
        for d in Depends[n]:
            dd =  re.sub(".*/","",d.replace(".yml",''))
            if not dd in RunDone: 
                #print(d+" is not in "+str(RunDone))
                DepsDone = False
        if DepsDone:
            logfile = outputDir+'/'+n+'.log'
            workdir = outputDir+'/'+n
            p = pool.apply_async(func=run_seq,args=(workdir,AllScripts[n],logfile))
            p.name = n # dependency
            print('pooling '+p.name)
            Running.append(p)
            
#### wait all  process done
for p in Running:
    p.wait()

### make index.html for all directories
os.chdir(outputDir)
#### get subdirs info
recipeInfo = dict()
subdirs = [ i for i in os.listdir('.') if os.path.isdir(i)]
subdirs.sort()
for i in subdirs:
    thumbnail = ''
    description = ''
    showinindex = 'True'
    tags = ['misc']
    # try index.html
    if isbs4: # if bs4 present and there is index.html in subdir, not done yet
        indexfile =  [ j for j in os.listdir(i) if re.match(".*index..*",j) ] 
        if indexfile:
            thumbnail = ''
            description = ''

    # try README in yaml format
    try:
        with open(i+'/README','r') as j:
            readme = yaml.load(j,Loader=yaml.BaseLoader)
            if readme.get('Title'): title = readme.get('Title')
            if readme.get('Description'): description = readme.get('Description')
            if readme.get('Thumbnail'): thumbnail = readme.get('Thumbnail')
            if readme.get('ShowInIndex'): showinindex = readme.get('ShowInIndex')
            if showinindex in [False,"False",'no','NO','No']: showinindex = False
            if readme.get('Tags'): tags = readme.get('Tags')
            if type(tags) == type('str'): tags = [ tag.strip() for tag in readme.get("Tags").split(',') ]
    except:
        ## no README or not plot directory
        pass
        #continue

    # if none of above
    if not thumbnail: 
        thumbnail = [ j for j in os.listdir(i) if re.match(".*thumb.png",j) ]
        thumbnail.sort()
        if thumbnail: 
            thumbnail = thumbnail[0]
        else:
            if showinindex: print("no thumbnail in "+i)
            thumbnail = ''
    if not description:
        description = i
    if not title:
        title = i
    # store it
    recipeInfo.update({i:{
        'title': title 
        , 'thumb': thumbnail
        , 'desc': description
        , 'showinindex': showinindex
        , 'tags': tags
        }})

#### grab index.html and thumbnail in subdirectories
def mk_index_entry(Arecipe_info):
    entry_html = ''
    dirs = Arecipe_info.keys()
    sorted(dirs)
    for i in dirs:
        r = Arecipe_info[i]
        if r['showinindex'] in [False,"False",'no','NO','No']: continue
        entry_html += "<span style='display:inline-block'>"
        entry_html += '<a href="'+i+'/index.html">'
        entry_html += '<h4>'+r['title']+'</h4>'
        if r.get('thumb'): entry_html += ''+'<img  ALIGN="left" src="'+i+'/'+r['thumb']+'">'
        entry_html += '</a>\n'
        entry_html += '<pre>'+r['desc']+'</pre>'
        entry_html += '</br> \n'
        entry_html += '</span>\n'
        entry_html += '</br> \n'
        entry_html += '<hr> \n'
    return entry_html

def mk_index():
    print("All Recieps compelete, making index page...")
    #### html header
    html = ''
    html += '<!DOCTYPE html> \n'
    html += '<html> \n'
    html += '<body> \n'

    #### title
    html += '<h3>diag_norcpm:</h3><h1>'+plotCase+'</h1>\n'
    html += '<hr>\n'
    #### recipe items
    entries = mk_index_entry(recipeInfo)
    html += entries

    #### html footer
    html += '<p align="right"><small>contact: pgchiu (Ping-Gin.Chiu_at_uib.no)</small></p> \n'
    html += '</body> \n'
    html += '</html> \n'

    #### write index html
    open("index.html",'w').write(html)

mk_index()

if False: ## debug  for tags
    for i in recipeInfo.keys():
        print(i+' '+str(recipeInfo[i].get('tags')))

def mk_tag_index(Arecipe_info):
    alltags = list()
    for i in Arecipe_info.keys():
        tags = Arecipe_info[i].get('tags')
        for j in tags:
            if j not in alltags : alltags.append(j)

    for tag in alltags:
        indName = "index_"+tag+".html"
        ## filter items needed
        needitems = dict()
        for i in Arecipe_info.keys():
            if tag in Arecipe_info[i].get('tags'): needitems.update({i:Arecipe_info[i]})
        #### html header
        html = ''
        html += '<!DOCTYPE html> \n'
        html += '<html> \n'
        html += '<body> \n'

        #### title
        html += '<h3>diag_norcpm:</h3><h1>'+plotCase+' ('+tag+')</h1>\n'
        html += '<hr>\n'
        #### recipe items
        entries = mk_index_entry(needitems)
        html += entries

        #### html footer
        html += '<p align="right"><small>contact: pgchiu (Ping-Gin.Chiu_at_uib.no)</small></p> \n'
        html += '</body> \n'
        html += '</html> \n'

        #### write index html
        open(indName,'w').write(html)

mk_tag_index(recipeInfo)

print("Index page done")
