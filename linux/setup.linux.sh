#!/bin/bash

mv_if_exist () {
    if [[ -f "$1" ]] || [[ -d "$1" ]]; then
        mv "$1" "$2"
        return 0
    else
        echo "[setup] Could not move ""$1"" to ""$2"""
        return 1
    fi
}

projectroot="$(dirname "$(dirname "$(readlink -f "$0")")")"
# this shouldn't happen as long as this is called by ../setup.sh
if [[ "$#" -lt 3 ]]; then
    echo "[setup - linux] Setup script given invalid parameters by setup.sh or called directly. Aborting." 1>&2
    exit 1
fi

if [[ "$1" == "0" ]]; then
    mantarget="$(manpath | cut -d':' -f1)/man1/lsf.1"
else
    mantarget="$1"
fi

if [[ "$2" == "0" ]]; then
    scripttarget="/usr/local/bin/lsf"
else
    scripttarget="$2"
fi

# with '-p', creates (including intermediates) if dir does not exists and does nothing if it does
mkdir -p "$(dirname "$mantarget")"
mkdir -p "$(dirname "$scripttarget")"

if [[ "$3" == "update" ]]; then
    tmstmp="$(date +"%s")"
    backup="$projectroot/linux/bak"
    mv_if_exist "$scripttarget" "$backup/lsf.linux.sh.$tmstmp.bak"
    mv_if_exist "$mantarget" "$backup/lsf.linux.man.$tmstmp.bak"
fi

# should happen whether "update" or "install"
ln "$projectroot/lsf.man" "$mantarget"
ln "$projectroot/linux/lsf.linux.sh" "$scripttarget"

