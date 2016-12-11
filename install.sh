#!/bin/sh -e

disableLidCloseSleep() {
    if ! grep -q "^HandleLidSwitch" /etc/systemd/logind.conf; then
        echo "HandleLidSwitch=ignore" |sudo tee -a /etc/systemd/logind.conf > /dev/null
        sudo service systemd-logind restart
    fi
}

ubuntuPackages() {
    sudo apt install -y encfs
    sudo apt install -y iotop vim git redshift-gtk tmux keepass2
    sudo apt install -y owncloud-client

    # i3
    echo "deb http://debian.sur5r.net/i3/ $(lsb_release -c -s) universe" |sudo tee /etc/apt/sources.list.d/i3wm.list
    sudo apt update
    sudo apt --allow-unauthenticated install -y sur5r-keyring
    sudo apt install -y i3

    # virtualbox
    echo "deb http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib non-free" |sudo tee /etc/apt/sources.list.d/virtualbox.list
    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
    sudo apt update
    sudo apt install -y virtualbox-5.1

    sudo apt install -y docker rxvt-unicode-256color

    sudo apt install -y mplayer
    sudo apt install -y openssh-server
    sudo apt install -y duplicity python-boto
    sudo apt install -y libsource-highlight-common
    # vim code checkers
    sudo apt install -y jsonlint shellcheck

    vagrantVersion=1.8.7
    if ! dpkg -l|grep vagrant|grep -q "$vagrantVersion"; then
        cd /tmp
        wget https://releases.hashicorp.com/vagrant/${vagrantVersion}/vagrant_${vagrantVersion}_x86_64.deb
        sudo dpkg -i vagrant_${vagrantVersion}_x86_64.deb
    fi

    sudo apt-get remove -y --purge firefox

    sudo apt autoremove -y
}

ubuntu() {
    ubuntuPackages
    disableLidCloseSleep

    sudo usermod -a -G docker volker
}

macos() {
    if [ ! -f '/usr/local/bin/brew' ]; then
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi

    brew install wget
    brew install tmux
    brew install coreutils
    brew install findutils
    brew install mplayer
    brew install source-highlight
    brew install awscli
    brew install watch
    brew install ffmpeg
    # vim code checker
    brew install jsonlint shellcheck

    brew install Caskroom/cask/iterm2
    brew install Caskroom/cask/docker
    brew install Caskroom/cask/firefox
    brew install Caskroom/cask/thunderbird
    brew install Caskroom/cask/flux
    brew install Caskroom/cask/owncloud
    brew install Caskroom/cask/hipchat
    brew install Caskroom/cask/slack
    brew install Caskroom/cask/menubar-countdown
    brew install Caskroom/cask/google-chrome
    brew install Caskroom/cask/libreoffice
    brew install Caskroom/cask/flash-npapi
    brew install Caskroom/cask/skype
    brew install Caskroom/cask/joinme
    brew install Caskroom/cask/amazon-workspaces
    brew install Caskroom/cask/tigervnc-viewer
    brew install Caskroom/cask/virtualbox Caskroom/cask/virtualbox-extension-pack
    brew install Caskroom/cask/vagrant
    brew install Caskroom/cask/tunnelblick
    brew install Caskroom/cask/x-lite
}

usage() {
    echo "$0 <argument>:"
    echo "   $0 ubuntu"
    echo "   $0 macos"
}

main() {
    if [ -z "$1" ]; then
       usage
       exit 1
    fi

    set -x

    case "$1" in
        ubuntu)
            ubuntu
            ;;
        "macos")
            macos
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
