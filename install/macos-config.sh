#!/bin/sh
set -e
set -u
set -o pipefail

#macosConfig(){
#    # save screenshots as jpg not png
#    defaults write com.apple.screencapture type jpg && killall SystemUIServer

#    # disable hibernation to disk. saves space.
#    sudo pmset -a hibernatemode 0

#    echo "Run: https://github.com/kristovatlas/osx-config-check"
#}

macos() {
    # font for vim-airline
    cd /tmp
    if [ ! -d fonts ]; then
        git clone https://github.com/powerline/fonts.git
    fi
    cd fonts
    ./install.sh
    echo "========================================================="
    echo "= TODO: IN ITERM CHOOSE FONT 'Meslo LG M for Powerline' ="
    echo "========================================================="
}
