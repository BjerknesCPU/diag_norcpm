#!/bin/bash

#;DIAG_NORCPM; FIGFILES: 
    # figure files name "without suffix"
    # should be ps or png file
#;DIAG_NORCPM; HTMLFILENAME: index.html
#;DIAG_NORCPM; TITLE: TITLE here
#;DIAG_NORCPM; COMMENT: COMMENT here
#;DIAG_NORCPM; COLUMN: 1

# parameters
htmlfn="HTMLFILENAME"
comment="COMMENT"
title="TITLE"
figs="FIGFILES"
column=(COLUMN)
    ## number of figures in a row
    ## can be a array
ncolarr=${#column[*]}

export MAGICK_THREAD_LIMIT=1   ## avoid "libgomp: Thread creation failed"

# html header
text=$'\n'
text+=$'<!DOCTYPE html>\n'
text+=$'<html>\n'
text+=$'<body>\n'

# put comment on top
text+=$'<div id=comment>\n'
text+=$'<p>\n'
text+=$'<pre>\n'
text+="$comment"
text+=$'</pre>\n'
#text+=$'</p>\n'
text+=$'</div>\n'


# convert ps to png and output entry to html
pid=$$
row=1
icol=0


text+="<table>"$'\n'
text+="<tr>"$'\n'

# if column start with non integer
while [ ! -z "${column[$icol]}" ] ; do
    dst="${column[$icol]}"
    if [[ "${dst}" =~ ^[0-9]+$ ]] ; then
        break
    else
        if [ "${dst}" = 'tr' ]; then
            dst='</tr><tr>'
        fi
        if [ "${dst}" = '</tr><tr>' ]; then
            text+="${dst}"$'\n'
        else
            text+="<th>${dst}</th>"$'\n'
        fi
        icol=$(expr $icol + 1)
    fi
done

col=${column[$icol]}

## show figures with table
for i in ${figs}; do
    if [ -f "${i}.ps" ] ; then ## ps2png
        convert -density 300 "${i}.ps" ${i}.png
        gzip -f "${i}.ps"
    fi 
    if [ -f "${i}.png" ] ; then ## trim white edge and make thumbnail
        convert ${i}.png -fuzz 1% -trim +repage tmp-${i}-${pid}.png 
        mv tmp-${i}-${pid}.png ${i}.png
        ## thumbnail
        convert -thumbnail 300 "${i}.png" "${i}_thumb.png"
    fi

    ## fig entry
    text+="<th><a href='${i}.png'><img src='${i}_thumb.png'></a></th>"$'\n'
    if [ $row -ge $col ];then
        text+=$'</tr>\n'
        text+=$'<tr>\n'
        icol=$(expr $icol + 1)
        while [ ! -z "${column[$icol]}" ] ; do
            dst="${column[$icol]}"
            if [ "${dst}" = 'tr' ]; then
                dst='</tr><tr>'
            fi
            if [[ "${dst}" =~ ^[0-9]+$ ]] ; then
                break
            else
                text+="<th><b>${dst}</b></th>"$'\n'
                icol=$(expr $icol + 1)
            fi
        done
        if [ $icol -ge $ncolarr ];then
            icol=$(expr $ncolarr - 1)
        fi
        col=${dst}
        row=1
    else
        row=$(expr $row + 1)
    fi
done
text+="</tr>"$'\n'
text+="</table>"$'\n'

# html footer
text+=$'</body>\n'
text+=$'</html> \n'

# output to html file
echo "${text}" >  "${htmlfn}"
