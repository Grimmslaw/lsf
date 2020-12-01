#!/bin/bash
DIRECTORY=$1

YEARINSECONDS=31540000

NOWSECONDS=$(echo $(date +%s))
MINSECONDS=$(($NOWSECONDS - $YEARINSECONDS))

FILTERMODE=0

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

main () {
    FILTER=$1
    # TODO: FILTERARGS={the rest of the args, if any more}
    shopt -s dotglob
    for file in "$DIRECTORY"/*; do
        ISYEAROLD=$(file_mod_year_plus "$file")
        if [[ "$ISYEAROLD" = "true"  ]]; then
            eval $(stat -s "$file")
            DTSTR=$(fmt_long_format_date $st_mtime)
            MODESTR=$(stat -f '%Sp' "$file")
            # !! OSX-specific?
            USRNAME=$(id -un -- "$st_uid")
            # !! OSX-specific
            GRPNAME=$(dscacheutil -q group -a gid $st_gid | grep "name: " | awk -F': ' '{print $2}')
            FILENAME=${file//"$DIRECTORY"\//}
            printf "%-11s %3s %-10s %-6s %6s %s %s\n" "$MODESTR" "$st_nlink" "$USRNAME" "$GRPNAME" "$st_size" "$DTSTR" "$FILENAME"
        fi
    done
}

while getopts ":hTt:" opt; do
    case $opt in
        T ) FILTERMODE=1
            ;;
        t ) FILTERMODE=2
            ;;
        h | * ) usage $programname
            ;;
    esac
done

main $FILTERMODE

