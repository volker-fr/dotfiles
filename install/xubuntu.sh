xubuntu() {
    PACKAGES="
              acpi
              alttab
              arandr
              bash-completion
              borgbackup
              build-essential
              compton
              encfs
              eog
              evince
              gparted
              i3
              iotop
              jsonlint
              jq
              maim
              mplayer
              mpv
              neovim
              openssh-server
              powerstat
              python3-flake8
              redshift-gtk
              rofi
              rxvt-unicode-256color
              shellcheck
              source-highlight
              thunderbird
              tigervnc-viewer
              tmux
              unattended-upgrades
              unrar
              virtualbox
              virtualbox-guest-additions-iso
              virtualbox-ext-pack
              xautolock
              xss-lock
              "

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

    # disable bluetooth on boot
    if ! grep "AutoEnable=false" /etc/bluetooth/main.conf > /dev/null; then
        sudo sed -i 's/^AutoEnable=.*/AutoEnable=false/' /etc/bluetooth/main.conf
    fi
    # disable bluetooth on i3 login/blueman-applet startup
    gsettings set org.blueman.plugins.powermanager auto-power-on false

    # systemd
    if [ ! -e ~/.config/systemd/user/battery-monitor.service ]; then
        mkdir -p ~/.config/systemd/user
        ln -s ~/repos/dotfiles/bin/battery-monitor.service \
            ~/.config/systemd/user/battery-monitor.service
        systemctl --user daemon-reload
        systemctl --user enable battery-monitor.service
        systemctl --user start battery-monitor.service
    fi

    # Upgrade all packages
    if ! grep "\\*:\\*" /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null; then
        sudo sed -i '/^Unattended-Upgrade::Allowed-Origins/a "*:*";' \
            /etc/apt/apt.conf.d/50unattended-upgrades
    fi

    # ignore more files for updatedb
    if ! grep "fuse.gocryptfs" /etc/updatedb.conf > /dev/null; then
        sudo sed -i 's/\(PRUNEFS=.*\)"$/\1 fuse.gocryptfs"/' /etc/updatedb.conf
    fi
    if ! grep "/home\"" /etc/updatedb.conf > /dev/null; then
        sudo sed -i 's,\(PRUNEPATHS=.*\)"$,\1 /home",' /etc/updatedb.conf
    fi
}

