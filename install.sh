#!/bin/sh -e
#set -x

repoDir="$(dirname "$(readlink -f "$0")")"

installDotfiles(){
    # regular dotfiles to link
    for file in Xresources bash bashrc bc.rc i3 tmux.conf vimrc; do
        source="$repoDir/$file"
        target="$HOME/.$file"
        # File existing but not linked?
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            echo "TODO: $target exists but is not a link. Please delete it"
            exit 1
        # link it
        elif [ ! -e "$target" ]; then
            echo "* linking $file to $target"
            ln -s "$source" "$target"
        # already linked
        else
            echo "$file already linked to $target"
        fi
    done

    [ -f "$HOME/.dircolors" ] && wget -q -O "$HOME/.dircolors" \
        https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.256dark

    if [ "$(uname -s)" = "Linux" ]; then
        # To open URL's in a docker container
        mkdir -p "$HOME/.local/share/applications"
        ln -sf "$repoDir/x11/browser.desktop" \
            "$HOME/.local/share/applications/"
        update-desktop-database "$HOME/.local/share/applications"
        gvfs-mime --set "x-scheme-handler/http" "browser.desktop"
        gvfs-mime --set "x-scheme-handler/https" "browser.desktop"

        # update default xdg-dirs
        xdg-user-dirs-update --set DESKTOP "$HOME"
        xdg-user-dirs-update --set TEMPLATES "$HOME"
        xdg-user-dirs-update --set DOCUMENTS "$HOME"
        xdg-user-dirs-update --set MUSIC "$HOME"
        xdg-user-dirs-update --set PICTURES "$HOME"
        xdg-user-dirs-update --set VIDEOS "$HOME"

        # don't backup vagrant
        mkdir -p "$HOME/no-backup/dotfiles"
        if [ -e "$HOME/.vagrant.d" ] && [ ! -L "$HOME/.vagrant.d" ]; then
            echo "$HOME/.vagrant.d exists but is not a link"
            echo "consider moving it to ~/no-backup/dotfiles/dot_vagrant.d"
            exit 1
        fi
        test -d "$HOME/no-backup/dotfiles/dot_vagrant.d" \
            && ln -sfn "$HOME/no-backup/dotfiles/dot_vagrant.d" "$HOME/.vagrant.d"
    fi

    # link ssh to localdata directory
    dotSSH="$HOME/localdata/dotfiles/dot_ssh"
    mkdir -p "$dotSSH" && chmod 700 "$dotSSH"
    if [ -e "$HOME/.ssh" ] && [ ! -L "$HOME/.ssh" ]; then
        echo "$HOME/.ssh exists but isn't a link"
        echo "consider moving it to $dotSSH"
        exit 1
    fi
    test -e "$HOME/.ssh" || ln -sfn "$dotSSH" "$HOME/.ssh"
    sshConfig="$dotSSH/config"
    test -f "$sshConfig" || cp "$repoDir/ssh/config" "$sshConfig"
    mkdir -p "$HOME/.ssh/sessions" && chmod 700 "$HOME/.ssh/sessions"

    # vim
    mkdir -p "$HOME/.vim/cache"
    mkdir -p "$HOME/.vim/view"
    mkdir -p "$HOME/.vim/autoload"
    # overwriting is ok in case the code updates
    wget -q -O "$HOME/.vim/autoload/plug.vim" \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    # Thunderbird
    mkdir -p "$HOME/localdata/dotfiles"
    if [ -e "$HOME/.thunderbird" ] && [ ! -L "$HOME/.thunderbird" ]; then
        echo "$HOME/.thunderbird exists but is not a link"
        echo "consider moving it to $HOME/localdata/dotfiles/dot_thunderbird"
        exit 1
    fi
    test -d "$HOME/localdata/dotfiles/dot_thunderbird" \
        && ln -sfn "$HOME/localdata/dotfiles/dot_thunderbird" \
           "$HOME/.thunderbird"

    # local bashrc
    test -f "$HOME/localdata/dotfiles/dot_bashrc.local" \
        && ln -sf "$HOME/localdata/dotfiles/dot_bashrc.local" \
           "$HOME/.bashrc.local"
}

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
    sudo apt install -y source-highlight
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

macosPackages() {
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
    brew install imagemagick
    brew install jq
    # tmux tabcompletion etc will fail without it
    brew install bash-completion
    # vim code checker
    brew install jsonlint shellcheck flake8

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
    brew install Caskroom/cask/yubikey-piv-manager
    brew install Caskroom/cask/gnucash
}

macos() {
    macosPackages

    # font for vim-airline
    cd /tmp
    git clone https://github.com/powerline/fonts.git
    cd fonts
    ./install.sh
    echo "========================================================="
    echo "= TODO: IN ITERM CHOOSE FONT 'Meslo LG M for Powerline' ="
    echo "========================================================="
}

usage() {
    echo "$0 <argument>:"
    echo "   $0 ubuntu"
    echo "   $0 macos"
    echo "   $0 dotfiles"
}

main() {
    if [ -z "$1" ]; then
       usage
       exit 1
    fi

    case "$1" in
        ubuntu)
            installDotfiles
            ubuntu
            ;;
        "macos")
            installDotfiles
            macos
            ;;
        "dotfiles")
            installDotfiles
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
