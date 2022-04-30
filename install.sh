#!/bin/sh
set -e
set -u
set -o pipefail
#set -x

repoDir="$(cd "$(dirname "$0")" && pwd -P)"

for i in $repoDir/install/*;do
    source $i
done

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

usage() {
    echo "$0 <argument>:"
    for i in arch dotfiles macos macos-personal-packages mainserver manjaro movedotfiles xubuntu; do
        echo "   $0 $i"
    done
}

main() {
    set +u
    if [ -z "$1" ]; then
       usage
       exit 1
    fi
    set -u

    case "$1" in
        arch)
            installDotfiles
            moveDotfiles
            arch
            ;;
        dotfiles)
            installDotfiles
            moveDotfiles
            ;;
        macos)
            installDotfiles
            moveDotfiles
            macosPackages
            #macosLoginItems
            ;;
        macos-personal-packages)
            macosPackagesPersonalDevice
            ;;
        mainserver)
            installDotfiles
            moveDotfiles
            mainserver
            ;;
        manjaro)
            installDotfiles
            moveDotfiles
            manjaro
            ;;
        movedotfiles)
            moveDotfiles
            ;;
        xubuntu)
            # xubuntu-minimal installation
            installDotfiles
            moveDotfiles
            if grep "ThinkPad X1 Carbon 7th" /sys/devices/virtual/dmi/id/product_family > /dev/null; then
                echo "Identified ThinkPad X1C7"
                x1c7Config
            fi
            #disableLidCloseSleep
            xubuntu
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
