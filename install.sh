#!/bin/sh -e
#set -x

repoDir="$(cd "$(dirname "$0")" && pwd -P)"

installDotfiles(){
    # regular dotfiles to link
    EXTRA_FILES=""
    if [ "$(uname -s)" = "Linux" ]; then
        EXTRA_FILES="Xresources i3"
    fi

    for file in bash bashrc bc.rc tmux.conf vimrc inputrc $EXTRA_FILES; do
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

    [ ! -f "$HOME/.dircolors" ] && wget -q -O "$HOME/.dircolors" \
        https://raw.githubusercontent.com/seebi/dircolors-solarized/master/dircolors.256dark

    if [ "$(uname -s)" = "Linux" ]; then
        # only run these settings if X11 is installed/running
        if pidof X > /dev/null || pidof Xorg > /dev/null; then
            # To open URL's in a docker container
            #   No more docker for some application for now
            #mkdir -p "$HOME/.local/share/applications"
            #ln -sf "$repoDir/x11/browser.desktop" \
            #    "$HOME/.local/share/applications/"
            #if which update-desktop-database >/dev/null; then
            #    update-desktop-database "$HOME/.local/share/applications"
            #fi
            #if which gvfs-mime >/dev/null; then
            #    gvfs-mime --set "x-scheme-handler/http" "browser.desktop"
            #    gvfs-mime --set "x-scheme-handler/https" "browser.desktop"
            #fi

            # update default xdg-dirs
            xdg-user-dirs-update --set DESKTOP "$HOME"
            xdg-user-dirs-update --set TEMPLATES "$HOME"
            xdg-user-dirs-update --set DOCUMENTS "$HOME"
            xdg-user-dirs-update --set MUSIC "$HOME"
            xdg-user-dirs-update --set PICTURES "$HOME"
            xdg-user-dirs-update --set VIDEOS "$HOME"
        fi
    fi

    # link ssh to localdata directory
    dotSSH="$HOME/localdata/dotfiles/ssh"
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
    # Neovim setup/linking
    if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
        echo "$HOME/.config/nvim exists but isn't a link"
        echo "Please remove it"
        exit 1
    fi
    test -e "$HOME/.config/nvim" || ln -sfn "$HOME/.vim" "$HOME/.config/nvim"
    test -e "$HOME/.vim/init.vim" || ln -sfn "$HOME/.vimrc" "$HOME/.config/nvim/init.vim"

    # local bashrc
    touch "$HOME/localdata/dotfiles/bashrc.local" \
        && ln -sf "$HOME/localdata/dotfiles/bashrc.local" "$HOME/.bashrc.local"
}

# Alert/Move the dotfiles instead they are where they shouldn't
moveDotfiles() {
    DIRS="$HOME/.config/VirtualBox
          $HOME/.thunderbird
          $HOME/.mozilla/firefox
          $HOME/.config/google-chrome
          $HOME/.config/Slack
          $HOME/.config/rtv
          $HOME/.config/joplin-desktop
          $HOME/.gitconfig
          $HOME/.bashrc.local
         "
    for DIR in $DIRS; do
        if [ -e "$DIR" ] && [ ! -L "$DIR" ]; then
            echo "$DIR is not a link"
        fi
    done

    MOVEABLE="$HOME/.thunderbird
              $HOME/.config/Slack
              $HOME/.config/google-chrome
              $HOME/.config/joplin-desktop
              $HOME/.gitconfig
              $HOME/.mozilla/firefox
              $HOME/.config/VirtualBox
             "
    for DIR in $MOVEABLE; do
        if [ -e "$DIR" ] && [ ! -L "$DIR" ]; then
            DIR_NAME=$(basename "$DIR")
            # cut dot in beginning of filename
            if echo "$DIR_NAME" | grep "^\." > /dev/null; then
                DIR_NAME=$(echo "$DIR_NAME"|cut -c2-)
            fi
            DESTINATION="$HOME/localdata/dotfiles/$DIR_NAME"
            if [ -e "$DESTINATION" ]; then
                echo "$DESTINATION already exists, please delete it before $DIR can be moved there"
                exit 1
            fi
            mv "$DIR" "$DESTINATION"
            ln -s "$DESTINATION" "$DIR"
        fi
    done
}


disableLidCloseSleep() {
    if ! grep -q "^HandleLidSwitch" /etc/systemd/logind.conf; then
        echo "HandleLidSwitch=ignore" |sudo tee -a /etc/systemd/logind.conf > /dev/null
        sudo service systemd-logind restart
    fi
}

mainserver() {
    if ! dpkg -l|grep sudo > /dev/null; then
        su -c "apt install -y sudo"
    fi
    if ! id|grep sudo > /dev/null; then
        su -c "usermod -a -G sudo volker"
        printf "Execute\\n   newgrp sudo\\nand reruncommand"
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
    sudo add-apt-repository --yes -u \
       "deb [arch=amd64] https://download.docker.com/linux/debian \
        $(lsb_release -cs) stable"
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
        Caskroom/cask/dropbox \
        Caskroom/cask/firefox \
        Caskroom/cask/thunderbird \
        Caskroom/cask/flux \
        Caskroom/cask/nextcloud \
        Caskroom/cask/slack \
        Caskroom/cask/menubar-countdown \
        Caskroom/cask/google-chrome \
        Caskroom/cask/libreoffice \
        Caskroom/cask/flash-npapi \
        Caskroom/cask/skype \
        Caskroom/cask/tigervnc-viewer \
        Caskroom/cask/virtualbox \
        Caskroom/cask/virtualbox-extension-pack \
        Caskroom/cask/vagrant \
        Caskroom/cask/yubikey-piv-manager \
        Caskroom/cask/time-out \
        Caskroom/cask/private-internet-access \
        Caskroom/cask/quitter \
        Caskroom/cask/etrecheck

    # Fix openssl
    brew install openssl
}

macosLoginItems(){
    # to automatically add login items
    brew install OJFord/formulae/loginitems

    loginitems -a Flux -s false
    loginitems -a RescueTime -s false
    loginitems -a nextcloud -s false
    loginitems -a Quitter -s false
    loginitems -a "Time Out" -s false
    loginitems -a "Menubar Countdown" -s false
}

macosConfig(){
    # save screenshots as jpg not png
    defaults write com.apple.screencapture type jpg && killall SystemUIServer
}

macos() {
    macosPackages
    macosLoginItems
    macosConfig

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

    # disable hibernation to disk. saves space.
    sudo pmset -a hibernatemode 0

    echo "Run: https://github.com/kristovatlas/osx-config-check"
}

xubuntu() {
    PACKAGES="i3
              rxvt-unicode-256color
              openssh-server
              neovim
              encfs
              tmux
              virtualbox
              virtualbox-guest-additions-iso
              virtualbox-ext-pack
              mplayer
              mpv
              redshift-gtk
              gparted
              iotop
              powerstat
              shellcheck
              python3-flake8
              jsonlint
              jq
              rofi
              source-highlight
              bash-completion
              jq
              source-highlight
              evince
              tigervnc-viewer
              eog
              xautolock
              xss-lock
              compton
              thunderbird"

    for i in $PACKAGES; do
        if ! dpkg -l|grep -is "ii  $i " > /dev/null; then
            INSTALL="$INSTALL $i"
            echo "$i"
        fi
    done
    # shellcheck disable=SC2086
    [ -n "$INSTALL" ] && sudo apt-get install -y $INSTALL

    # docker
    if ! dpkg -l|grep -is 'docker-ce' > /dev/null; then
        sudo apt-get remove docker docker-engine docker.io
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository --yes -u "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt install -y docker-ce
        sudo usermod -a -G docker volker
    fi

    # For Virtualbox
    if ! id|grep vboxusers > /dev/null; then
        sudo usermod -a -G vboxusers volker
    fi

    # nextcloud
    if ! dpkg -l|grep -is 'nextcloud-client' > /dev/null; then
        sudo add-apt-repository --yes ppa:nextcloud-devs/client
        sudo apt-get install -y nextcloud-client
    fi

    # syncthing
    if ! dpkg -l|grep -is 'syncthing' > /dev/null; then
        curl -s https://syncthing.net/release-key.txt | sudo apt-key add -
        echo "deb https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
        sudo apt-get update
        sudo apt-get install syncthing
    fi

    # google chrome
    if ! dpkg -l|grep -is 'google-chrome' > /dev/null; then
        curl -s -o /tmp/google-chrome-stable.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
            sudo dpkg -i /tmp/google-chrome-stable.deb
    fi

    # Slack
    if ! dpkg -l|grep -is 'ii  slack-desktop' > /dev/null; then
        curl -s -L -o /tmp/slack-desktop.deb https://downloads.slack-edge.com/linux_releases/slack-desktop-4.0.1-amd64.deb && \
            sudo dpkg -i /tmp/slack-desktop.deb || \
            sudo apt-get -f install -y && \
            sudo apt-get update && sudo apt-get upgrade
    fi

    # Joplin
    if [ ! -f "$HOME/.joplin/Joplin.AppImage" ]; then
        curl https://raw.githubusercontent.com/laurent22/joplin/master/Joplin_install_and_update.sh | bash
    fi

    # pcloud
    if [ ! -f /usr/local/bin/pcloud ]; then
        echo "Install pCloud: https://www.pcloud.com/download-free-online-cloud-file-storage.html"
    fi

    # gocryptfs
    if [ ! -f /usr/local/bin/gocryptfs ]; then
        URL=$(curl -s https://api.github.com/repos/rfjakob/gocryptfs/releases/latest \
            | jq -r ".assets[] | select(.name) | .browser_download_url" \
            | grep "_linux-static_amd64.tar.gz$")
        curl -L -o /tmp/gocryptfs.tgz "$URL"
        cd /tmp && tar xvfz gocryptfs.tgz
        chmod 755 gocryptfs
        sudo mv gocryptfs /usr/local/bin
    fi

    # PIA
    if [ ! -d "/opt/piavpn" ]; then
        curl -s -L https://installers.privateinternetaccess.com/download/pia-linux-1.3.3-02880.run | sh
    fi
}

x1c7Config() {
    # Uses /sys/class/backlight/%k/brightness
    if ! dpkg -l|grep -is '^ii  light ' > /dev/null; then
        curl -L -s -o /tmp/light.deb https://github.com/haikarainen/light/releases/download/v1.2/light_1.2_amd64.deb && \
            sudo dpkg -i /tmp/light.deb
        sudo usermod -a -G video volker
        echo "run this command: newgrp video"
    fi

    if ! dpkg -l|grep -is '^ii  tlp-rdw ' > /dev/null; then
        sudo add-apt-repository ppa:linrunner/tlp
        sudo apt-get update
        sudo apt-get install tlp tlp-rdw
    fi

    if ! grep '^\[Element Master\]' /usr/share/pulseaudio/alsa-mixer/paths/analog-output.conf.common > /dev/null; then
        sudo sed -i '/^\[Element PCM\]/i [Element Master]\nswitch = mute\nvolume = ignore\n' \
            /usr/share/pulseaudio/alsa-mixer/paths/analog-output.conf.common
    fi

    echo
    echo "Audio"
    echo "====="
    echo "Maybe: https://forums.lenovo.com/t5/Ubuntu/Guide-X1-Carbon-7th-Generation-Ubuntu-compatability/td-p/4489823"
    echo "pavucontrol and change output to 4.0 + analogue input"
    echo
    echo "Power"
    echo "====="
    echo "https://github.com/BelBES/thinkpad_x1_carbon_6th_linux"
    echo "https://github.com/erpalma/throttled"
    echo "https://itsfoss.com/reduce-overheating-laptops-linux/"
    echo "powerstat -d 0"
    echo "sudo tlp-stat -t"
}


usage() {
    echo "$0 <argument>:"
    echo "   $0 mainserver"
    echo "   $0 ubuntu"
    echo "   $0 macos"
    echo "   $0 xubuntu"
    echo "   $0 dotfiles"
    echo "   $0 movedotfiles"
}

main() {
    if [ -z "$1" ]; then
       usage
       exit 1
    fi

    case "$1" in
        mainserver)
            installDotfiles
            moveDotfiles
            mainserver
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
        "macos")
            installDotfiles
            moveDotfiles
            macos
            ;;
        "dotfiles")
            installDotfiles
            moveDotfiles
            ;;
        movedotfiles)
            moveDotfiles
            ;;
        *)
            usage
            ;;
    esac
}

main "$@"
