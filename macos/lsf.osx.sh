#!/bin/bash

TRUE="true"
FALSE="false"

YEARINSECONDS=31540000

NOWSECONDS=$(echo $(date +%s))
MINSECONDS=$(($NOWSECONDS - $YEARINSECONDS))

FILTERMODE=0
MODEARG=""
FILTERLINKS=0
LINKSARG=""
FILTERUSER=0
USERARG=""
FILTERGROUP=0
GROUPARG=""
FILTERSIZE=0
SIZEARG=""
FILTERTIME=0
TIMEARG=""
FILTERNAME=0
NAMEARG=""

usage () {
    PROGRAMNAME=$1
    echo ""
    echo "Usage: $PROGRAMNAME [-T | -t timebefore] dirname"
    echo "List all files and directories in 'dirname' that meet criteria designated by the flags provided"
    echo ""
    echo "  -h          display this help text and quit"
    echo "  -T          filter out any files and directories modified as or more recently than 6 months ago"
    echo "  -t  days    filter out any files and directories modified as or more recently than 'days' days ago"
    echo ""

    exit 1
}

# help ; mode x ; links x ; Username | username x ; Group | group x ; bytes x ; Time | time x ; name x
while getopts ":hm:l:Uu:Gg:b:Tt:n:" opt; do
    case $opt in
        m ) FILTERMODE=1
            MODEARG="$OPTARG"
            ;;
        l ) FILTERLINKS=1
            LINKSARG="$OPTARG"
            ;;
        u ) FILTERUSER=1
            USERARG="$OPTARG"
            ;;
        g ) FILTERGROUP=1
            GROUPARG="$OPTARG"
            ;;
        b ) FILTERSIZE=1
            SIZEARG="$OPTARG"
            ;;
        t ) FILTERTIME=1
            TIMEARG="$OPTARG"
            ;;
        n ) FILTERNAME=1
            NAMEARG="$OPTARG"
            ;;
        U ) FILTERUSER=1
            USERARG=""
            ;;
        G ) FILTERGROUP=1
            GROUPARG=""
            ;;
        T ) FILTERTIME=1
            TIMEARG=""
            ;;
        \?) echo "Invalid option: -$OPTARG. Aborting." 1>&2
            exit 1
            ;;
        : ) echo "Invalid: option -$OPTARG requires an argument. Aborting." 1>&2
            exit 1
            ;;
        h | * ) usage $programname
            exit 1
            ;;
    esac
done

is_older_than_year () {
    NUMSECONDS=$1
    if [[ $NUMSECONDS -lt $MINSECONDS ]]; then
        echo "true"
    else
        echo "false"
    fi
}

file_mod_year_plus () {
    FILENAME=$1
    eval $(stat -s "$FILENAME")
    # sets st_mtime (among others)
    RES=$(is_older_than_year "$st_mtime")
    echo $RES
}

fmt_long_format_date () {
    # TODO figure out how to make this work in linux, too ("-d" instead of -r")
    DT=$(date -r "$1" +"%b %e %Y")
    MONTH=$(cut -d' ' -f1 <<< "$DT")
    TEMP_DAY=$(cut -d' ' -f2 <<< "$DT")
    if [[ -z "${TEMP_DAY// }" ]]; then
        DAY=$(cut -d' ' -f3 <<< "$DT")
        YEAR=$(cut -d' ' -f4 <<< "$DT")
    else
        DAY=$(cut -d' ' -f2 <<< "$DT")
        YEAR=$(cut -d' ' -f3 <<< "$DT")
    fi
    STR=$(printf "%-3s%3d%6d\n" "$MONTH" "$DAY" "$YEAR")
    echo "$STR"
}

meets_mode_criteria () {
    # TODO
    # TODO: allow string (with wildcards)
    return 1
}

meets_links_criteria () {
    # TODO
    return 1
}

meets_user_criteria () {
    # TODO
    return 1
}

meets_group_criteria () {
    # TODO
    return 1
}

meets_size_criteria () {
    SIZEEXPR=$1
    ACTUALSIZE=$2
    THRESHOLD="$(echo "$SIZEEXPR" | sed 's/[\m\=]//g')"
    if [[ "${SIZEEXPR:0:1}" == "m" ]] && [[ "${SIZEEXPR:1:1}" == "=" ]]; then
        if [[ "$ACTUALSIZE" -le "$THRESHOLD" ]]; then
            echo "$TRUE"
        else
            echo "$FALSE"
        fi
    elif [[ "${SIZEEXPR:0:1}" == "m" ]]; then
        if [[ "$ACTUALSIZE" -lt "$THRESHOLD" ]]; then
            echo "$TRUE"
        else
            echo "$FALSE"
        fi
    elif [[ "${SIZEEXPR:1:1}" == "=" ]]; then
        if [[ "$ACTUALSIZE" -ge "$THRESHOLD" ]]; then
            echo "$TRUE"
        else
            echo "$FALSE"
        fi
    else
        if [[ "$ACTUALSIZE" -gt "$THRESHOLD" ]]; then
            echo "$TRUE"
        else
            echo "$FALSE"
        fi
    fi
}

meets_time_criteria () {
    # TODO
    return 1
}

meets_name_criteria () {
    # TODO: implement glob/regex filter
    return 1
}

#main () {
#    DIRECTORY=$1
#    FILTER=$2
#    CRITERION=$3
#    shopt -s dotglob
#    for file in "$DIRECTORY"/*; do
#        ISYEAROLD=$(file_mod_year_plus "$file")
#        if [[ "$ISYEAROLD" = "true"  ]]; then
#            eval $(stat -s "$file")
#            DTSTR=$(fmt_long_format_date $st_mtime)
#            MODESTR=$(stat -f '%Sp' "$file")
#            # !! OSX-specific?
#            USRNAME=$(id -un -- "$st_uid")
#            # !! OSX-specific
#            GRPNAME=$(dscacheutil -q group -a gid $st_gid | grep "name: " | awk -F': ' '{print $2}')
#            FILENAME=${file//"$DIRECTORY"\//}
#            printf "%-11s %3s %-10s %-6s %6s %s %s\n" "$MODESTR" "$st_nlink" "$USRNAME" "$GRPNAME" "$st_size" "$DTSTR" "$FILENAME"
#        fi
#    done
#}

main () {
    directory=$1
    shopt -s dotglob
    for file in "$directory"/*; do
        SHOULDPRINT=1
        eval "$(stat -s "$file")"
        if [[ "$FILTERSIZE" -eq 1 ]]; then
            MEETSSIZE="$(meets_size_criteria "$SIZEARG" "$st_size")"
            if [[ "$MEETSSIZE" = "$FALSE" ]]; then
                SHOULDPRINT=0
                continue
            fi
        fi

        if [[ "$SHOULDPRINT" -eq 1 ]]; then
            DTSTR="$(fmt_long_format_date "$st_mtime")"
            MODESTR="$(stat -f '%Sp' "$file")"
            USRNAME="$(id -un -- "$st_uid")"
            GRPNAME="$(dscacheutil -q group -a gid "$st_gid" | grep "name: " | awk -F': ' '{print $2}')"
            FILENAME="${file//"$directory"\//}"
            printf "%-11s %3s %-10s %-6s %6s %s %s\n" "$MODESTR" "$st_nlink" "$USRNAME" "$GRPNAME" "$st_size" "$DTSTR" "$FILENAME"
        fi
    done
}

BASEDIRNAME="${@:$OPTIND:1}"

main "$BASEDIRNAME"

