#!/bin/bash

# make json for tapdown list in index2.html
#   for 1 recipe
# input parameter:
#   F_IGURES (1d array for bash)
#   S_HAPE   (1d to nd)
#   S_ELECTS (1d array of name of selects, should be same dims of shape)
#   O_PTIONS (1d array of name of options, for all selects, should be all)
# inp_ut example:
#   F_IGURES: "fromJan_1" "fromJan_2" "fromJan_3" "fromJan_4"  "fromApr_1" "fromApr_2" "fromApr_3" "fromApr_4"  "fromJul_1" "fromJul_2" "fromJul_3" "fromJul_4"  "fromOct_1" "fromOct_2" "fromOct_3" "fromOct_4" 
#   S_HAPE: 4 4
#   S_ELECTS: initTime  leadSeason
#   O_PTIONS: "fromJan" "fromApr" "fromJul" "fromOct" 1 2 3 4
   
# output json example:
#{
#"select" : {
#        "initTime" : ["fromJan","fromApr","fromJul","fromOct"],
#        "leadSeason" : [1,2,3,4] 
#        },
#"selectOrder" : [
#        "initTime",
#        "leadSeason"
#        ],
#"figures": [
#     ["fromJan_1","fromJan_2","fromJan_3","fromJan_4"],
#     ["fromApr_1","fromApr_2","fromApr_3","fromApr_4"],
#     ["fromJul_1","fromJul_2","fromJul_3","fromJul_4"],
#     ["fromOct_1","fromOct_2","fromOct_3","fromOct_4"] 
#    ]
#}

#;DIAG_NORCPM; FIGFILES: 
    # figure files name "without suffix"
    # should be ps or png file
#;DIAG_NORCPM; TITLE: TITLE here
#;DIAG_NORCPM; COMMENT: COMMENT here
declare -a figures
declare -a shape
declare -a selects
declare -a options

## testing code
#figures=("fromJan_1" "fromJan_2" "fromJan_3" "fromJan_4"  "fromApr_1" "fromApr_2" "fromApr_3" "fromApr_4"  "fromJul_1" "fromJul_2" "fromJul_3" "fromJul_4"  "fromOct_1" "fromOct_2" "fromOct_3" "fromOct_4")
#shape=(4 2 2)
#selects=(initTime leadSeason)
#options=("fromJan" "fromApr" "fromJul" "fromOct" 1 2 3 4)

figures=(FIGURES)
shape=(SHAPE)
selects=(SELECTS)
options=(OPTIONS)
jsonfile=JSONFILE

text=$'{\n'

# select object
ishape=0
jj=0
text+=$'    "select" : {\n'
    for i in "${selects[@]}" ; do
        if [ $jj -ne 0 ];then
            text+=$',\n'
        fi
        shapem1=$((${shape[$ishape]} - 1))
        text+='        "'${i}'" : ['
        for j in $(seq $shapem1); do
            text+='"'${options[$jj]}'", '
            jj=$(($jj + 1))
        done
        text+='"'${options[$jj]}'"]'
        jj=$(($jj + 1))
        ishape=$(($ishape + 1))
    done
text+=$'\n        },\n'


# selectOrder array
jj=0
text+=$'    "selectOrder" : [\n'
for i in "${selects[@]}" ; do
    if [ $jj -ne 0 ];then
        text+=$',\n'
    fi
    text+='        "'${i}'"'
    jj=$(($jj + 1))
done

text+=$'\n        ],\n'



# figures array
## get split point
### reverse array, somewhat it more reasonable to break down figure array
declare -a revShape
for i in "${shape[@]}" ; do
    revShape=("$i" "${revShape[@]}")
done

declare -a splitShape
jj=1
for i in "${revShape[@]}" ; do
    jj=$(($jj * $i))
    splitShape+=($jj)
done

text+=$'    "figures" : '
for j in "${splitShape[@]}"; do
    text+='['
done
text+=$'\n        '

jj=0
for i in "${figures[@]}" ; do
    text+='"'${i}'"'
    splitF=0

    for j in "${splitShape[@]}"; do
        if [ $(( ($jj + 1) % $j)) == '0' ];then
            text+=$']'
            splitF=1
        fi
    done
    if [ $(($jj + 1)) -lt "${#figures[@]}" ];then
        text+=$', '
    fi
    if [ "$splitF" == '1' ] ; then
        text+=$'\n        '
    fi
    for j in "${splitShape[@]}"; do
        if [ $(( ($jj + 1) % $j)) == '0' ] && [ $(($jj + 1)) -lt "${#figures[@]}" ];then
            text+=$'['
        fi
    done
    jj=$(($jj + 1))
done

text+='        '
#for j in $(seq $((${#splitShape[@]} - 1))); do
#    text+=']'
#done
text+=$'\n'

# end of json
text+='}'


# output to json
echo "$text" > "${jsonfile}"
