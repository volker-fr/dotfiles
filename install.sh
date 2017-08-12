#!/bin/sh -e
set -x

repoDir="$(dirname "$(readlink -f "$0")")"

installDotfiles(){
    # regular dotfiles to link
    for file in Xresources bash bashrc bc.rc i3 tmux.conf vimrc inputrc; do
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
        #else
        #    echo "$file already linked to $target"
        fi
    done

    [ -f "$HOME/.dircolors" ] && wget -q -O "$HOME/.dircolors" \
        https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.256dark

    if [ "$(uname -s)" = "Linux" ]; then
        # only run these settings if X11 is installed/running
        if pidof X > /dev/null || pidof Xorg; then
            # To open URL's in a docker container
            mkdir -p "$HOME/.local/share/applications"
            ln -sf "$repoDir/x11/browser.desktop" \
                "$HOME/.local/share/applications/"
            if which update-desktop-database >/dev/null; then
                update-desktop-database "$HOME/.local/share/applications"
            fi
            if which gvfs-mime >/dev/null; then
                gvfs-mime --set "x-scheme-handler/http" "browser.desktop"
                gvfs-mime --set "x-scheme-handler/https" "browser.desktop"
            fi

            # update default xdg-dirs
            xdg-user-dirs-update --set DESKTOP "$HOME"
            xdg-user-dirs-update --set TEMPLATES "$HOME"
            xdg-user-dirs-update --set DOCUMENTS "$HOME"
            xdg-user-dirs-update --set MUSIC "$HOME"
            xdg-user-dirs-update --set PICTURES "$HOME"
            xdg-user-dirs-update --set VIDEOS "$HOME"
        fi

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
    touch "$HOME/localdata/dotfiles/dot_bashrc.local" \
        && ln -sf "$HOME/localdata/dotfiles/dot_bashrc.local" "$HOME/.bashrc.local"
}

disableLidCloseSleep() {
    if ! grep -q "^HandleLidSwitch" /etc/systemd/logind.conf; then
        echo "HandleLidSwitch=ignore" |sudo tee -a /etc/systemd/logind.conf > /dev/null
        sudo service systemd-logind restart
    fi
}

ubuntuPackages() {
    sudo apt install -y encfs
    sudo apt install -y iotop vim git redshift-gtk tmux
    sudo apt install -y owncloud-client
    # i3
    cd /tmp
    /usr/lib/apt/apt-helper download-file http://debian.sur5r.net/i3/pool/main/s/sur5r-keyring/sur5r-keyring_2017.01.02_all.deb keyring.deb SHA256:4c3c6685b1181d83efe3a479c5ae38a2a44e23add55e16a328b8c8560bf05e5f
    sudo dpkg -i ./keyring.deb

    echo "deb http://debian.sur5r.net/i3/ $(lsb_release -c -s) universe" |sudo tee /etc/apt/sources.list.d/i3wm.list
    sudo apt update
    sudo apt install -y sur5r-keyring
    sudo apt install -y i3

    # virtualbox
    if ! lspci|grep VirtualBox > /dev/null; then
        echo "deb http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib non-free" |sudo tee /etc/apt/sources.list.d/virtualbox.list
        wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
        sudo apt update
        sudo apt install -y virtualbox-5.1
    fi

    # docker
    sudo apt-get remove docker docker-engine docker.io
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt update
    sudo apt install -y docker-ce

    sudo apt install -y rxvt-unicode-256color

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

mainserver() {
    if ! dpkg -l|grep sudo > /dev/null; then
        su -c "apt install -y sudo"
    fi
    if ! id|grep sudo > /dev/null; then
        su -c "usermod -a -G sudo volker"
        echo "Execute\n   newgrp sudo\nand reruncommand"
    fi
    sudo apt remove --purge -y rdnssd
    sudo apt install -y tmux vim rsync git bc
    sudo apt install -y lsb-release unzip rss2email ssmtp

    sudo apt install -y unattended-upgrades apt-listchanges
    sudo sed -i 's,^//Unattended-Upgrade::Mail,Unattended-Upgrade::Mail,' /etc/apt/apt.conf.d/50unattended-upgrades
    sudo sed -i 's,^Unattended-Upgrade::MailOnlyOnError,//Unattended-Upgrade::MailOnlyOnError,' /etc/apt/apt.conf.d/50unattended-upgrades
    sudo dpkg-reconfigure -plow unattended-upgrades

    sudo apt install -y logcheck
    sudo usermod -a -G logcheck volker

    # For docker
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/debian/gpg \
        | sudo apt-key add -
    sudo add-apt-repository \
       "deb [arch=amd64] https://download.docker.com/linux/debian \
        $(lsb_release -cs) stable"
    sudo apt update
    sudo apt install -y docker-ce
    sudo usermod -a -G docker volker

    if [ ! -f /usr/local/bin/docker-compose ]; then
        curl -L https://github.com/docker/compose/releases/download/2.11.2/run.sh |sudo tee /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi

    [ ! -L "$HOME/localdata/git" ] && \
        ln -s "$HOME/localdata/git" "$HOME/git"
    [ ! -d "$HOME/git" ] && echo "TODO: $HOME/git doesn't exists"

    USER_HOME="$HOME"
    [ ! -L "$USER_HOME/localdata/dotfiles/ssmtp.conf" ] && \
        sudo ln -s "$USER_HOME/localdata/dotfiles/ssmtp.conf" /etc/ssmtp/ssmtp.conf
    [ ! -f "$HOME/localdata/dotfiles/ssmtp.conf" ] && \
        echo "TODO: $HOME/localdata/dotfiles/ssmtp.conf doesn't exists"

    echo "TODO: SSHD: disable root login & port 222"
}

macosPackages() {
    if [ ! -f '/usr/local/bin/brew' ]; then
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi

    brew install \
        wget \
        tmux \
        coreutils \
        findutils \
        mplayer \
        source-highlight \
        awscli \
        watch \
        ffmpeg \
        imagemagick \
        jq
    # tmux tabcompletion etc will fail without it
    brew install bash-completion
    # vim code checker
    brew install jsonlint shellcheck flake8
    # tmux workaround for open etc
    brew install reattach-to-user-namespace
    # for vim-youcompleteme
    brew install cmake go

    brew install \
        Caskroom/cask/iterm2 \
        Caskroom/cask/docker \
        Caskroom/cask/firefox \
        Caskroom/cask/thunderbird \
        Caskroom/cask/flux \
        Caskroom/cask/owncloud \
        Caskroom/cask/hipchat \
        Caskroom/cask/slack \
        Caskroom/cask/menubar-countdown \
        Caskroom/cask/google-chrome \
        Caskroom/cask/libreoffice \
        Caskroom/cask/flash-npapi \
        Caskroom/cask/skype \
        Caskroom/cask/joinme \
        Caskroom/cask/amazon-workspaces \
        Caskroom/cask/tigervnc-viewer \
        Caskroom/cask/virtualbox \
        Caskroom/cask/virtualbox-extension-pack \
        Caskroom/cask/vagrant \
        Caskroom/cask/tunnelblick \
        Caskroom/cask/yubikey-piv-manager \
        Caskroom/cask/gnucash \
        Caskroom/cask/time-out \
        Caskroom/cask/quitter
}

macosLoginItems(){
    # to automatically add login items
    brew install OJFord/formulae/loginitems

    loginitems -a Flux -s false
    loginitems -a RescueTime -s false
    loginitems -a owncloud -s false
    loginitems -a Quitter -s false
    loginitems -a "Time Out" -s false
    loginitems -a "Menubar Countdown" -s false
}

macos() {
    macosPackages
    macosLoginItems

    # font for vim-airline
    cd /tmp
    git clone https://github.com/powerline/fonts.git
    cd fonts
    ./install.sh
    echo "========================================================="
    echo "= TODO: IN ITERM CHOOSE FONT 'Meslo LG M for Powerline' ="
    echo "========================================================="

    # disable hibernation to disk. saves space.
    pmset -a hibernatemode 0
}

usage() {
    echo "$0 <argument>:"
    echo "   $0 mainserver"
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
        mainserver)
            installDotfiles
            mainserver
            ;;
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
