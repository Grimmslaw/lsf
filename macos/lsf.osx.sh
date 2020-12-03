#!/bin/bash

TRUE="true"
FALSE="false"

yearinseconds=31540000

nowseconds=$(echo $(date +%s))
minseconds=$(($nowseconds - $yearinseconds))

filtermode=0
modearg=""
filterlinks=0
linksarg=""
filteruser=0
userarg=""
filtergroup=0
grouparg=""
filtersize=0
sizearg=""
filtertime=0
timearg=""
filtername=0
namearg=""

usage () {
    PROGRAMNAME=$1
    echo ""
    echo "Usage: $PROGRAMNAME [-m mode] [-l links] [-U | -u usernm] [-G | -g groupnm] [-b size] [-T | -t days] [-n filenm] dirname"
    echo "List all files and directories in 'dirname' that meet criteria designated by the flags provided"
    echo ""
    echo "  -h          display this help text and quit"
    echo "  -m  mode    filter based on 'mode' filemode (either numeric or textual)"
    echo "  -l  links   filter based on comparison with 'links' number of links"
    echo "  -U          filter out any files not belonging to the current user"
    echo "  -u  usernm  filter based on username"
    echo "  -G          filter out any files not belonging to the current user's group"
    echo "  -g  groupnm filter based on group name"
    echo "  -b  size    filter based on comparison with 'size' number of bytes"
    echo "  -T          filter out any files and directories modified as or more recently than 6 months ago"
    echo "  -t  days    filter based on comparison with 'days' number of days ago [that the file was modified last]"
    echo "  -n  filenm  filter based on filename"
    echo ""

    exit 1
}

# help ; mode x ; links x ; Username | username x ; Group | group x ; bytes x ; Time | time x ; name x
while getopts ":hm:l:Uu:Gg:b:Tt:n:" opt; do
    case $opt in
        m ) filtermode=1
            modearg="$OPTARG"
            ;;
        l ) filterlinks=1
            linksarg="$OPTARG"
            ;;
        u ) filteruser=1
            userarg="$OPTARG"
            ;;
        g ) filtergroup=1
            grouparg="$OPTARG"
            ;;
        b ) filtersize=1
            sizearg="$OPTARG"
            ;;
        t ) filtertime=1
            timearg="$OPTARG"
            ;;
        n ) filtername=1
            namearg="$OPTARG"
            ;;
        U ) filteruser=1
            userarg=""
            ;;
        G ) filtergroup=1
            grouparg=""
            ;;
        T ) filtertime=1
            timearg=""
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
    numseconds=$1
    if [[ $numseconds -lt $minseconds ]]; then
        echo "true"
    else
        echo "false"
    fi
}

file_mod_year_plus () {
    filename=$1
    eval $(stat -s "$filename")
    # sets st_mtime (among others)
    res=$(is_older_than_year "$st_mtime")
    echo $res
}

fmt_long_format_date () {
    # TODO figure out how to make this work in linux, too ("-d" instead of -r")
    dt=$(date -r "$1" +"%b %e %Y")
    month=$(cut -d' ' -f1 <<< "$dt")
    temp_day=$(cut -d' ' -f2 <<< "$dt")
    if [[ -z "${temp_day// }" ]]; then
        day=$(cut -d' ' -f3 <<< "$dt")
        year=$(cut -d' ' -f4 <<< "$dt")
    else
        day=$(cut -d' ' -f2 <<< "$dt")
        year=$(cut -d' ' -f3 <<< "$dt")
    fi
    STR=$(printf "%-3s%3d%6d\n" "$month" "$day" "$year")
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
    sizeexpr=$1
    actualsize=$2
    threshold="$(echo "$sizeexpr" | sed 's/[\m\=]//g')"
    if [[ "${sizeexpr:0:1}" == "=" ]] && [[ "${sizeexpr:1:1}" == "=" ]]; then
        if [[ "$actualsize" -eq "$threshold" ]]; then
            echo "$TRUE"
        else
            echo "$FALSE"
        fi
    elif [[ "${sizeexpr:0:1}" == "m" ]] && [[ "${sizeexpr:1:1}" == "=" ]]; then
        if [[ "$actualsize" -le "$threshold" ]]; then
            echo "$TRUE"
        else
            echo "$FALSE"
        fi
    elif [[ "${sizeexpr:0:1}" == "m" ]]; then
        if [[ "$actualsize" -lt "$threshold" ]]; then
            echo "$TRUE"
        else
            echo "$FALSE"
        fi
    elif [[ "${sizeexpr:1:1}" == "=" ]]; then
        if [[ "$actualsize" -ge "$threshold" ]]; then
            echo "$TRUE"
        else
            echo "$FALSE"
        fi
    else
        if [[ "$actualsize" -gt "$threshold" ]]; then
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

main () {
    directory=$1
    shopt -s dotglob
    for file in "$directory"/*; do
        shouldprint=1
        eval "$(stat -s "$file")"
        if [[ "$filtersize" -eq 1 ]]; then
            meetssize="$(meets_size_criteria "$sizearg" "$st_size")"
            if [[ "$meetssize" = "$FALSE" ]]; then
                shouldprint=0
                continue
            fi
        fi

        if [[ "$shouldprint" -eq 1 ]]; then
            dtstr="$(fmt_long_format_date "$st_mtime")"
            modestr="$(stat -f '%Sp' "$file")"
            usrname="$(id -un -- "$st_uid")"
            grpname="$(dscacheutil -q group -a gid "$st_gid" | grep "name: " | awk -F': ' '{print $2}')"
            filename="${file//"$directory"\//}"
            printf "%-11s %3s %-10s %-6s %6s %s %s\n" "$modestr" "$st_nlink" "$usrname" "$grpname" "$st_size" "$dtstr" "$filename"
        fi
    done
}

basedirname="${@:$OPTIND:1}"

main "$basedirname"

