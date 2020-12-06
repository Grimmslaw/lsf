#!/bin/bash

TRUE="true"
FALSE="false"

PROGRAMNAME="$(basename "$0")"

sixmonthsseconds=15768000
nowseconds=$(echo "$(date +%s)")
minseconds=$((nowseconds - sixmonthsseconds))

isnumberpattern='^[0-9]*$'
isnumbercompstr='^\^?(ge|gt|eq|lt|le)[0-9]*\$?$'

filesonly=0
dirsonly=0
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
    echo ""
    echo "Usage: $PROGRAMNAME [-F | -D] [-m mode] [-l links] [-U | -u usernm] [-G | -g groupnm] [-b size] [-T | -t days] [-n filenm] dirname"
    echo "List all files and directories in 'dirname' that meet criteria designated by the flags provided"
    echo ""
    echo "  -h          display this help text and quit"
    echo "  -F          filter out all non-files"
    echo "  -D          filter out all non-directories"
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

while getopts ":hFDm:l:Uu:Gg:b:Tt:n:" opt; do
    case $opt in
        F ) filesonly=1
            ;;
        D ) dirsonly=1
            ;;
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
        h | * ) usage
            exit 1
            ;;
    esac
done

is_older_than_sixmos () {
    numseconds=$1
    if [[ $numseconds -lt $minseconds ]]; then
        echo "true"
    else
        echo "false"
    fi
}

format_long_fmt_dt () {
    seconds="$1"
    showyear="$2"

    dt=$(date -r "$seconds" +"%b %e %Y %H:%M")
    month="$(echo "$dt" | tr -s ' ' | cut -d' ' -f1)"
    day="$(echo "$dt" | tr -s ' ' | cut -d' ' -f2)"
    year="$(echo "$dt" | tr -s ' ' | cut -d' ' -f3)"
    time="$(echo "$dt" | tr -s ' ' | cut -d' ' -f4)"
    
    if [[ "$showyear" -eq 1 ]]; then
        str="$(printf "%-3s%3d%6d\n" "$month" "$day" "$year")"
    else
        str="$(printf "%-3s%3d%6s\n" "$month" "$day" "$time")"
    fi
    echo "$str"
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

satisfies_string_comparison () {
    tocompare="$1"
    pattern="$2"
    [[ "$tocompare" =~ $pattern ]] && echo "$TRUE" || echo "$FALSE"
}

satisfies_simple_comparison () {
    tocompare="$1"
    compareagainst="$2"

    if [[ "$tocompare" =~ $isnumberpattern ]]; then
        if [[ "$compareagainst" =~ $isnumbercompstr ]]; then
            "$(satisfies_number_comparison "$(echo "$compareagainst" | sed 's/[\^\$]*//g')" "$tocompare")"
        else
            echo "$FALSE"
        fi
    else
        "$(satisfies_string_comparison "$compareagainst" "$tocompare")"
    fi
}

meets_mode_criteria () {
    # TODO: allow string (with wildcards)
    modecriteria="$1"
    actualmode="$2"
    "$(satisfies_number_comparison "$modecriteria" "$actualmode")"
}

meets_user_criteria () {
    if [[ -z "$1" ]]; then
        usercriteria="$(id -u -n)"
    else
        usercriteria="$1"
    fi
    
    userpattern="$usercriteria"
    if [[ "${usercriteria:0:1}" != '^' ]]; then
        userpattern='^'"$userpattern"
    fi
    if [[ "${usercriteria: -1:1}" != '$' ]]; then
        userpattern="$userpattern"'$'
    fi
    actualusernm="$2"
    "$(satisfies_simple_comparison "$actualusernm" "$userpattern")"
}

meets_group_criteria () {
    if [[ -z "$1" ]]; then
        groupcriteria="$(id -g -n)"
    else
        groupcriteria="$1"
    fi

    grouppattern="$groupcriteria"
    if [[ "${groupcriteria:0:1}" != '^' ]]; then
        grouppattern='^'"$grouppattern"
    fi
    if [[ "${groupcriteria: -1:1}" != '$' ]]; then
        grouppattern="$grouppattern"'$'
    fi
    actualgroupnm="$2"
    "$(satisfies_simple_comparison "$actualgroupnm" "$groupcriteria")"
}

meets_time_criteria () {
    timecriteria="$1"
    actualmodtime="$2"
    if [[ -z "$timecriteria" ]]; then
        res="$(is_older_than_sixmos "$actualmodtime")"
    else
        # TODO
        exit 1
    fi
    echo "$res"
}

meets_name_criteria () {
    namecriteria="$1"
    actualname="$2"
    if [[ "${namecriteria:0:1}" == "!" ]]; then
        [[ "$actualname" != "$namecriteria" ]] && echo "$TRUE" || echo "$FALSE"
    else
        [[ "$actualname" == "$namecriteria" ]] && echo "$TRUE" || echo "$FALSE"
    fi
}

main () {
    directory=$1
    total=0
    shopt -s dotglob
    for file in "$directory"/*; do
        if [[ $filesonly -eq 1 ]] && [[ ! -f $file ]]; then
            continue
        fi

        if [[ $dirsonly -eq 1 ]] && [[ ! -d $file ]]; then
            continue
        fi

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
            if [[ "$userarg" =~ $isnumbercompstr ]]; then
                meetsuser="$(meets_user_criteria "$userarg" "$st_uid")"
            else
                meetsuser="$(meets_user_criteria "$userarg" "$usrname")"
            fi

            if [[ "$meetsuser" = "$FALSE" ]]; then
                continue
            fi
        fi

        grpname="$(dscacheutil -q group -a gid "$st_gid" | grep "name: " | awk -F': ' '{print $2}')"
        if [[ "$filtergroup" -eq 1 ]]; then
            if [[ "$grouparg" =~ $isnumbercompstr ]]; then
                meetsgroup="$(meets_group_criteria "$grouparg" "$st_gid")"
            else
                meetsgroup="$(meets_group_criteria "$grouparg" "$grpname")"
            fi

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
            if [[ "$meetsname" = "$FALSE" ]]; then
                continue
            fi
        fi

        total="$((total + st_size))"

        more_than_sixmos="$(is_older_than_sixmos "$st_mtime")"
        if [[ "$more_than_sixmos" = "$TRUE" ]]; then
            dtstr="$(format_long_fmt_dt "$st_mtime" 1)"
        else
            dtstr="$(format_long_fmt_dt "$st_mtime" 0)"
        fi
        modestr="$(stat -f '%Sp' "$file")"
        printf "%-11s %3s %-10s %-6s %6s %s %s\n" "$modestr" "$st_nlink" "$usrname" "$grpname" "$st_size" "$dtstr" "$filename"
    done

    echo "total $total"
}

basedirname="${*:$OPTIND:1}"

main "$basedirname"

