#!/bin/bash

SCRIPTROOT="$(dirname "$(realpath -e "$0")")"

if [[ $OSTYPE == "darwin"* ]]; then
    "$SCRIPTROOT/macos/install.sh"
elif [[ $OSTYPE == "linux-gnu"* ]]; then
    "$SCRIPTROOT/linux/install.sh"
else
    echo "Unsupported operating system: $OSTYPE"
    exit 1
fi

