#!/bin/bash

PROGRAMNAME="$(basename "$0")"

# pulls in log() and loglevels
. "$(dirname "$(dirname "$0")")/common.sh"

mantarget=""
scripttarget=""

usage () {
    if [[ -n "$1" ]]; then
        shortusage="$1"
    else
        shortusage=0
    fi
    
    usagestring="Usage: $PROGRAMNAME [-m mantarget] [-s scripttarget] mode"
    if [[ "$shortusage" -eq 0 ]]; then
        echo "$usagestring"
        exit 1
    fi

    echo ""
    echo "$usagestring"
    echo "Install or update the lsf script on your system (where 'mode' is either 'install' or 'update'."
    echo ""
    echo "  -m  mantarget       override the default location for manpages for your system; should be an absolute path"
    echo "  -s  scripttarget    override the default local binary location for your system; should be an absolute path"
    echo "  -v  loglevel        set the lowest level of log statement that should be logged (as either a number or a string) [0 (nolog), 1 (error), 2 (warn), 3 (info), 4 (trace)]"
    echo ""

    exit 1
}

while getopts ":hm:s:v:" opt; do
    case $opt in
        m ) mantarget="$OPTARG"
            ;;
        s ) scripttarget="$OPTARG"
            ;;
        v ) temploglevel="$(lognum_from_str "$OPTARG")"
            if [[ "$?" -eq 1 ]]; then
                loglevel="$error"
            elif [[ "$temploglevel" =~ [0-9]* ]]; then
                # if temploglevel is a number, set as loglevel; otherwise keep default
                loglevel="$temploglevel"
            fi
            ;;
        \?) log "$error" "setup" "Invalid option: -$OPTARG. Aborting." "$loglevel"
            exit 1
            ;;
        : ) log "$error" "setup" "Invalid: option -$OPTARG requires an argument. Aborting." "$loglevel"
            exit 1
            ;;
        h ) usage 0
            exit 1
            ;;
        * ) log "$error" "setup" "Invalid: unknown option. Aborting." "$loglevel"
            usage 1
            exit 1
            ;;
    esac
done

# validate positional argument
posarg="${*:$OPTIND:1}"
if [[ -z "$posarg" ]] || [[ ! "$posarg" == "install" && ! "$posarg" == "update" ]]; then
    log "$error" "setup" "Invalid: ""$0"" requires a mode (either 'install' or 'update' as its positional argument. Aborting." "$loglevel"
    exit 1
fi

if [[ -z "$mantarget" ]]; then
    mantarget="0"
fi

if [[ -z "$scripttarget" ]]; then
    scripttarget="0"
fi

projectroot="$(dirname "$(realpath -e "$0")")"

read -r -d '' envsummary <<EOF
    mantarget=$mantarget
    scripttarget=$scripttarget
    mode=$posarg
    os=$OSTYPE
    loglevel=$loglevel
EOF
envsummary="$(echo -e "\nEnvironment Summary:\n    $envsummary")"

log "$trace" "setup" "$envsummary" "$loglevel"

if [[ "$OSTYPE" == "darwin"* ]]; then
    sudo "$projectroot/macos/setup.osx.sh" "$mantarget" "$scripttarget" "$posarg" "$loglevel"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo "$projectroot/linux/setup.linux.sh" "$mantarget" "$scripttarget" "$posarg" "$loglevel"
else
    log "$error" "setup" "Invalid OS: $OSTYPE"
    exit 1
fi

