#!/bin/bash

if [[ "$#" -gt 0 ]]; then
    scripttarget="$1"
else
    scripttarget="/usr/local/bin/lsf"
fi

projectroot="$(dirname "$(dirname "$(readlink -f "$0")")")"
scriptloc="$projectroot/linux/lsf.linux.sh"

lsfmanloc="$projectroot/lsf.man"

manroot="$(manpath | cut -d':' -f1 )"
if [ ! -d "$manroot/man1" ]; then
    mkdir -p "$manroot/man1"
fi
mantarget="$manroot/man1/lsf.1"

ln "$scriptloc" "$scripttarget"
ln "$lsfmanloc" "$mantarget"

