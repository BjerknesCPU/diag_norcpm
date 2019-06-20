import re
import sys
def gen_proc_plot(template:str,recipe):
    '''
        replace template string with dict(recipe)
    '''
    diagcmd = r';DIAG_NORCPM;' # read setting from ncl comments
    needcmd = 'NeedBeReplace'  # special variable 
    OutputReplaces = False

    ## planeize the recipe
    precipe = {}
    for i in recipe.keys():
        if type(recipe[i]) is str: precipe[i] = recipe[i]
        if type(recipe[i]) is dict: 
            for j in recipe[i].keys():
                if j in precipe.keys(): print("gen_proc_plot: key confilct: "+j+' in '+str(recipe[i]))
                precipe[j] = recipe[i][j]
        if type(recipe[i]) is list: 
            precipe[i] = ",".join(['"'+j+'"' for j in recipe[i]])


    ## get necessary and default variables
    #cmds = re.match(diagcmd+r'.*',template)#.groups()
    keysinscript = dict()
    for line in template.split('\n'):
        cmdstr = re.search(diagcmd+r' *(.*)',line)
    #print(template)
        if cmdstr:
            cmd = re.search("^([^ :]*): *(.*)",cmdstr.group(1))
            if cmd:
                key = cmd.group(1)
                val = cmd.group(2)
                if val and val[0] == val[-1] and val[0] in ['"',"'"]: val = val[1:-1] ## remove ' and " if it indicate a string
                keysinscript.update({key:val})
            else:
                print('gen_proc_plot(): cannot parse: '+cmdstr.group(0))
    keysinscript.update(precipe)

    ## check necessary variables are available
    OK = True
    needvars = keysinscript.get(needcmd)
    if needvars: 
        needvars = [i.strip() for i in needvars.split(',')]
        for i in needvars:
            if not i in keysinscript:
                OK = False
                print("gen_proc_plot(): "+i+" need be set for "+str(keysinscript.get('plotScript')))
    if not OK: 
        print(keysinscript)
        sys.exit()

    ## replace keys in template
    keys = [ i for i in keysinscript.keys()]
    keys.sort(key=len,reverse=True) 
    ### print replacing strings
    if OutputReplaces:
        print('======== keys to replace with order')
        for i in keys:
            print('    '+i+': '+keysinscript[i])
        print('===================================')
    ### do replace
    out = template
    if False: # replace whole template at once
        for i in keys:
            out = re.sub("\n([^;\n]*)"+i,'\n\g<1>'+keysinscript[i],out)
    if True: # replace one by one line
        outlines = out.split("\n")
        out = ""
        for j in outlines:
            if diagcmd in j:
                out += j+'\n'
                continue
            else:
                afterstr = j
                for i in keys:
                    afterstr = re.sub(i,keysinscript[i],afterstr)
                out += afterstr+'\n'
    return out
