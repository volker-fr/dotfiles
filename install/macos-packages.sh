#!/bin/sh
set -e
set -u
set -o pipefail

if [ ! -f '/usr/local/bin/brew' -a ! -f '/opt/homebrew/bin/brew' ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

currentDir="$(cd "$(dirname "$0")" && pwd -P)"

brew bundle --file "$currentDir/Brewfile"
