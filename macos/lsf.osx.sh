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
    echo "  -T          filter out any files and directories modified as or more recently than 1 year ago"
    echo "  -t  days    filter based on comparison with 'days' number of days ago [that the file was modified last]"
    echo "  -n  filenm  filter based on filename"
    echo ""

    exit 1
}

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

satisfies_number_comparison () {
    sizeexpr=$1
    actual=$2
    threshold="$(echo "$sizeexpr" | sed 's/[lgteq]*//g')"
    case "${sizeexpr:0:2}" in
        "eq")
            [[ "$actual" -eq "$threshold" ]] && echo "$TRUE" || echo "$FALSE"
            ;;
        "le")
            [[ "$actual" -le "$threshold" ]] && echo "$TRUE" || echo "$FALSE"
            ;;
        "lt")
            [[ "$actual" -lt "$threshold" ]] && echo "$TRUE" || echo "$FALSE"
            ;;
        "ge")
            [[ "$actual" -ge "$threshold" ]] && echo "$TRUE" || echo "$FALSE"
            ;;
        "gt")
            [[ "$actual" -gt "$threshold" ]] && echo "$TRUE" || echo "$FALSE"
            ;;
        *   )
            echo "Invalid comparison string: $sizeexpr." 1>&2
            exit 1
    esac
}

meets_mode_criteria () {
    # TODO: allow string (with wildcards)
    modecriteria="$1"
    actualmode="$2"
    echo "$(satisfies_number_comparison "$1" "$2")"
}

meets_user_criteria () {
    if [[ -z "$1" ]]; then
        usercriteria="$(id -u -n)"
    else
        usercriteria="$1"
    fi
    actualusernm="$2"

    # until exclusions and wildcards are supported
    if [[ "$usercriteria" == "$actualusernm" ]]; then
        echo "$TRUE"
    else
        echo "$FALSE"
    fi
}

meets_group_criteria () {
    if [[ -z "$1" ]]; then
        groupcriteria="$(id -g -n)"
    else
        groupcriteria="$1"
    fi
    actualgroupnm="$2"
    
    # until exclusions and wildcards are supported:
    if [[ "$groupcriteria" == "$actualgroupnm" ]]; then
        echo "$TRUE"
    else
        echo "$FALSE"
    fi
}

meets_time_criteria () {
    timecriteria="$1"
    actualmodtime="$2"
    if [[ -z "$timecriteria" ]]; then
        res="$(file_mod_year_plus "$2")"
    else
        # TODO
        exit 1
    fi
    echo "$res"
}

meets_name_criteria () {
    # TODO: implement glob/regex filter
    namecriteria="$1"
    actualname="$2"
    if [[ "${namecriteria:0:1}" == "!" ]]; then
        if [[ "$actualname" != "$namecriteria" ]]; then
            echo "$TRUE"
        else
            echo "$FALSE"
        fi
    else
        if [[ "$actualname" == "$namecriteria" ]]; then
            echo "$TRUE"
        else
            echo "$FALSE"
        fi
    fi
}

main () {
    directory=$1
    total=0
    shopt -s dotglob
    for file in "$directory"/*; do
        eval "$(stat -s "$file")"

        if [[ "$filtermode" -eq 1 ]]; then
            meetsmode="$(meets_mode_criteria "$modearg" "$st_mode")"
            if [[ "$meetsmode" = "$FALSE" ]]; then
                continue
            fi
        fi

        if [[ "$filterlinks" -eq 1 ]]; then
            meetslinks="$(satisfies_number_comparison "$linksarg" "$st_nlink")"
            if [[ "$meetslinks" = "$FALSE" ]]; then
                continue
            fi
        fi

        usrname="$(id -un -- "$st_uid")"
        if [[ "$filteruser" -eq 1 ]]; then
            meetsuser="$(meets_user_criteria "$userarg" "$usrname")"
            if [[ "$meetsuser" = "$FALSE" ]]; then
                continue
            fi
        fi

        grpname="$(dscacheutil -q group -a gid "$st_gid" | grep "name: " | awk -F': ' '{print $2}')"
        if [[ "$filtergroup" -eq 1 ]]; then
            meetsgroup="$(meets_group_criteria "$grouparg" "$grpname")"
            if [[ "$meetsgroup" = "$FALSE" ]]; then
                continue
            fi
        fi

        if [[ "$filtersize" -eq 1 ]]; then
            meetssize="$(satisfies_number_comparison "$sizearg" "$st_size")"
            if [[ "$meetssize" = "$FALSE" ]]; then
                continue
            fi
        fi

        if [[ "$filtertime" -eq 1 ]]; then
            meetstime="$(meets_time_criteria "$timearg" "$st_mtime")"
            if [[ "$meetstime" = "$FALSE" ]]; then
                continue
            fi
        fi

        filename="${file//"$directory"\//}"
        if [[ "$filtername" -eq 1 ]]; then
            meetsname="$(meets_name_criteria "$namearg" "$filename")"
            if [[ "$meetstime" = "$FALSE" ]]; then
                continue
            fi
        fi

        total="$((total+1))"
        dtstr="$(fmt_long_format_date "$st_mtime")"
        modestr="$(stat -f '%Sp' "$file")"
        # TODO: datestrings within 6 months should show time modified instead of year (like ls -al)
        printf "%-11s %3s %-10s %-6s %6s %s %s\n" "$modestr" "$st_nlink" "$usrname" "$grpname" "$st_size" "$dtstr" "$filename"
    done

    echo "total $total"
}

basedirname="${@:$OPTIND:1}"

main "$basedirname"

