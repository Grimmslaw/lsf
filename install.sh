#!/bin/bash

scriptroot="$(dirname "$(realpath -e "$0")")"

if [[ $OSTYPE == "darwin"* ]]; then
    sudo "$scriptroot/macos/install.sh"
elif [[ $OSTYPE == "linux-gnu"* ]]; then
    sudo "$scriptroot/linux/install.sh"
else
    echo "Unsupported operating system: $OSTYPE"
    exit 1
fi

