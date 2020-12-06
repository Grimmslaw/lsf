#!/bin/bash

mantarget=""
manflag=0
scripttarget=""
scriptflag=0

usage () {
    progname="$(basename "$1")"
    if [[ -n "$2" ]]; then
        shortusage="$2"
    else
        shortusage=0
    fi
    
    usagestring="Usage: $progname [-m mantarget] [-s scripttarget] mode"
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
    echo ""

    exit 1
}

while getopts ":hm:s:" opt; do
    case $opt in
        m ) mantarget="$OPTARG"
            ;;
        s ) scripttarget="$OPTARG"
            ;;
        \?) echo "[setup] Invalid option: -$OPTARG. Aborting." 1>&2
            exit 1
            ;;
        : ) echo "[setup] Invalid: option -$OPTARG requires an argument. Aborting." 1>&2
            exit 1
            ;;
        h ) usage "$programname" 0
            exit 1
            ;;
        * ) echo "[setup] Invalid: unknown option. Aborting."
            usage "$programname" 1
            exit 1
            ;;
    esac
done

# validate positional argument
posarg="${*:$OPTIND:1}"
if [[ -z "$posarg" ]] || [[ ! "$posarg" == "install" && ! "$posarg" == "update" ]]; then
    echo "[setup] Invalid: ""$0"" requires a mode (either 'install' or 'setup') as its positional argument. Aborting." 1>&2
    exit 1
fi

if [[ -z "$mantarget" ]]; then
    mantarget="0"
fi

if [[ -z "$scripttarget" ]]; then
    scripttarget="0"
fi

projectroot="$(dirname "$(realpath -e "$0")")"

if [[ "$OSTYPE" == "darwin"* ]]; then
    sudo "$projectroot/macos/setup.osx.sh" "$mantarget" "$scripttarget" "$posarg"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo "$projectroot/linux/setup.linux.sh" "$mantarget" "$scripttarget" "$posarg"
else
    echo "[setup] Invalid OS: $OSTYPE"
    exit 1
fi

