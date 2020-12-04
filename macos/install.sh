#!/bin/bash

SCRIPTLOC="$(dirname "$(realpath -e "$0")")/lsf.osx.sh"

MANROOT=$(cat /private/etc/manpaths | grep local)
MANLOC="$MANROOT/man1/lsf.1"

ln "$SCRIPTLOC" /usr/local/bin/lsf
ln lsf.man "$MANLOC"

