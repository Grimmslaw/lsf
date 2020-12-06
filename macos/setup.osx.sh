#!/bin/bash

projectroot="$(dirname "$(dirname "$(realpath -e "$0")")")"
# this shouldn't happen as long as this is called by ../setup.sh
if [[ "$#" -lt 3 ]]; then
    echo "[setup - macos] Setup script given invalid parameters by setup.sh or called directly. Aborting."
    exit 1
fi

if [[ "$1" == "0" ]]; then
    mantarget="$(cat /private/etc/manpaths | grep local)/man1/lsf.1"
elif [[ ! -d "$(dirname "$1")" ]]; then
    mkdir -p "$(dirname "$1")"
    mantarget="$1"
else
    mantarget="$1"
fi

if [[ "$2" == "0" ]]; then
    scripttarget="/usr/local/bin/lsf"
elif [[ ! -d "$(dirname "$2")" ]]; then
    mkdir -p "$(dirname "$2")"
    scripttarget="$2"
else
    scripttarget="$2"
fi

if [[ "$3" == "update" ]]; then
    tmstmp="$(date +"%s")"
    backup="$projectroot/macos/bak"
    mv "$scripttarget" "$backup/lsf.osx.sh.$tmstmp.bak"
    mv "$mantarget" "$backup/lsf.man.$tmstmp.bak"
fi

# should happen whether "update" or "install"
ln "$projectroot/lsf.man" "$mantarget"
ln "$projectroot/macos/lsf.osx.sh" "$scripttarget"

