#!/bin/bash
set -e
set -u
set -o pipefail

#          alttab
#          bash-completion
#          compton
#          encfs
#          jsonlint
#          powerstat
#          unattended-upgrades
#          rxvt-unicode-256color
PACKAGES="
          acpi #_for_systemd_battery_monitoring_and_warning
          arandr #_for_multiple_monitors
          autorandr #_for_multiple_monitors
          borgbackup
          build-essential
          calibre #_for_ebook-convert
          curl
          evince
          eog
          gparted
          i3
          light
          iotop
          jq
          maim
          mpv
          neovim
          openssh-server
          python3-flake8
          redshift-gtk
          subliminal  #_for_subtitle_download
          rofi
          shellcheck
          sshfs
          source-highlight
          thunderbird
          tigervnc-viewer
          tmux
          unrar
          virtualbox
          virtualbox-guest-additions-iso
          virtualbox-ext-pack
          whois
          xautolock
          xss-lock
          zsh
          "
INSTALL=""
for i in $PACKAGES; do
    if [[ $i == "#"* ]]; then
        continue
    fi
    if ! dpkg -l|grep -is "ii  $i " > /dev/null; then
        INSTALL="$INSTALL $i"
        echo "Installing: $i"
    fi
done
# shellcheck disable=SC2086
[ -n "$INSTALL" ] && sudo apt-get install -y $INSTALL

# docker
if ! dpkg -l|grep -is 'docker-ce' > /dev/null; then
    sudo apt remove docker docker.io
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
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
if ! dpkg -l|grep -is 'ii  syncthing' > /dev/null; then
    sudo curl -s -o /usr/share/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
    echo "deb [signed-by=/usr/share/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | sudo tee /etc/apt/sources.list.d/syncthing.list
    sudo apt-get update
    sudo apt-get install syncthing
fi

# google chrome
if ! dpkg -l|grep -is 'google-chrome' > /dev/null; then
    curl -s -o /tmp/google-chrome-stable.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
        sudo dpkg -i /tmp/google-chrome-stable.deb
fi

# Slack
if ! snap list|grep -is '^slack' > /dev/null; then
    sudo snap install slack
fi

# Authy
if ! snap list|grep -is '^authy' > /dev/null; then
    sudo snap install authy
fi

# pcloud
#if [ ! -f /usr/local/bin/pcloud ]; then
    #echo "Install pCloud: https://www.pcloud.com/download-free-online-cloud-file-storage.html"
#fi

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
#if ! grep "AutoEnable=false" /etc/bluetooth/main.conf > /dev/null; then
#    sudo sed -i 's/^AutoEnable=.*/AutoEnable=false/' /etc/bluetooth/main.conf
#fi
# disable bluetooth on i3 login/blueman-applet startup
#gsettings set org.blueman.plugins.powermanager auto-power-on false

# systemd
if [ ! -e ~/.config/systemd/user/battery-monitor.service ]; then
    mkdir -p ~/.config/systemd/user
    ln -s ~/repos/dotfiles/bin/battery-monitor.service \
        ~/.config/systemd/user/battery-monitor.service
    systemctl --user daemon-reload
    systemctl --user enable battery-monitor.service
    systemctl --user start battery-monitor.service
fi

# obsidian
VERSION=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest \
    | jq -r ".name")
if ! dpkg -l|grep -is "obsidian"|grep "$VERSION" > /dev/null; then
    URL=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest \
        | jq -r ".assets[] | select(.name) | .browser_download_url" \
        | grep "_amd64.deb$")
    curl -L -o /tmp/obsidian.deb "$URL"
    sudo dpkg -i /tmp/obsidian.deb
fi

# Upgrade all packages
#if ! grep "\\*:\\*" /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null; then
#    sudo sed -i '/^Unattended-Upgrade::Allowed-Origins/a "*:*";' \
#        /etc/apt/apt.conf.d/50unattended-upgrades
#fi

# ignore more files for updatedb
#if ! grep "fuse.gocryptfs" /etc/updatedb.conf > /dev/null; then
#    sudo sed -i 's/\(PRUNEFS=.*\)"$/\1 fuse.gocryptfs"/' /etc/updatedb.conf
#fi
#if ! grep "/home\"" /etc/updatedb.conf > /dev/null; then
#    sudo sed -i 's,\(PRUNEPATHS=.*\)"$,\1 /home",' /etc/updatedb.conf
#fi

# Fix backlight permissions
if [ ! -e /etc/udev/rules.d/backlight.rules ]; then
    echo 'ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="<vendor>", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness"'|sudo tee -a /etc/udev/rules.d/backlight.rules
    echo 'ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="<vendor>", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"' | sudo tee -a /etc/udev/rules.d/backlight.rules
    sudo usermod -a -G video volker
fi

if [ ! -e /usr/bin/kubectl ]; then
    sudo apt-get install -y apt-transport-https ca-certificates curl
    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    #echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
fi

if [ ! -e /usr/bin/signal-desktop ]; then
    wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > /tmp/signal-desktop-keyring.gpg
    cat /tmp/signal-desktop-keyring.gpg | sudo tee -a /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
    #echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt $(lsb_release -cs) main" |\
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main" |\
        sudo tee /etc/apt/sources.list.d/signal-xenial.list
    sudo apt update && sudo apt install signal-desktop
fi
if [ ! -e /usr/bin/zotero -a ! -e /usr/local/bin/zotero ]; then
    wget -qO- https://raw.githubusercontent.com/retorquere/zotero-deb/master/install.sh | sudo bash
    sudo apt update
    sudo apt install -y zotero
fi

if ! dpkg -l|grep -is 'nordvpn' > /dev/null; then
    sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
fi

if [ ! -d /home/linuxbrew ]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
if [ ! -f /home/linuxbrew/.linuxbrew/bin/k9s ]; then
    brew install k9s
fi
