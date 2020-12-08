#!/bin/bash

# pulls in log() and loglevels
. "$(dirname "$(dirname "$0")")/common.sh"
loglevel="$warn"

mv_if_exist() {
    if [[ -f "$1" && -f "$2" ]] || [[ -d "$1" && -d "$2" ]]; then
        mv "$1" "$2"
        return 0
    else
        log "$warn" "setup" "Could not move ""$1"" to ""$2""."
        return 1
    fi
}

projectroot="$(dirname "$(dirname "$(realpath -e "$0")")")"
# this shouldn't happen as long as this is called by ../setup.sh
if [[ "$#" -lt 4 ]]; then
    log "$error" "setup - osx" "Setup script given invalid parameters by setup.sh or called directly. Aborting."
    exit 1
fi

# reset once determined there are correct number of args
loglevel="$4"

if [[ "$1" == "0" ]]; then
    mantarget="$(grep local /private/etc/manpaths)/man1/lsf.1"
else
    mantarget="$1"
fi

if [[ "$2" == "0" ]]; then
    scripttarget="/usr/local/bin/lsf"
else
    scripttarget="$2"
fi

# with '-p', creates (including intermediates) if dir does not exist and does nothing if it does
mkdir -p "$(dirname "$mantarget")"
mkdir -p "$(dirname "$scripttarget")"

if [[ "$3" == "update" ]]; then
    tmstmp="$(date +"%s")"
    backup="$projectroot/macos/bak"
    mv "$scripttarget" "$backup/lsf.osx.sh.$tmstmp.bak"
    mv "$mantarget" "$backup/lsf.man.$tmstmp.bak"
fi

# should happen whether "update" or "install"
ln "$projectroot/lsf.man" "$mantarget"
ln "$projectroot/macos/lsf.osx.sh" "$scripttarget"

