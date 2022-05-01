#!/bin/sh
set -e
set -u
set -o pipefail

# make configuration files we create readable by the user
umask 022

# pre-compiled AUR's like google-chrome
# Disastrousaur decomissioned...
#if ! grep "^\[disastrousaur\]" /etc/pacman.conf > /dev/null; then
#    echo "" | sudo tee -a /etc/pacman.conf > /dev/null
#    echo "[disastrousaur]" | sudo tee -a /etc/pacman.conf > /dev/null
#    echo "Server = https://mirror.repohost.de/\$repo/\$arch" | sudo tee -a /etc/pacman.conf > /dev/null
#    sudo pacman-key --recv-keys CB8DA19D1551E92F
#    sudo pacman-key --lsign-key  CB8DA19D1551E92F
#fi

# enable multilib for wine
if ! grep "^\[multilib\]" /etc/pacman.conf > /dev/null; then
    echo "" | sudo tee -a /etc/pacman.conf > /dev/null
    echo "[multilib]" | sudo tee -a /etc/pacman.conf > /dev/null
    echo "Include = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf > /dev/null
fi


# From xubuntu, adapt
#    # disable bluetooth on boot
#    if ! grep "AutoEnable=false" /etc/bluetooth/main.conf > /dev/null; then
#        sudo sed -i 's/^AutoEnable=.*/AutoEnable=false/' /etc/bluetooth/main.conf
#    fi
#    # disable bluetooth on i3 login/blueman-applet startup
#    gsettings set org.blueman.plugins.powermanager auto-power-on false

#
# Find the quickest mirror before we install anything
#
if [ ! -e /etc/pacman.d/mirrorlist.orig ]; then
    sudo pacman -Suu --needed pacman-contrib

    sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig

    awk '/^## Worldwide$/{f=1; next}f==0{next}/^## /{exit}{print substr($0, 1);}' /etc/pacman.d/mirrorlist.orig \
        | sudo tee /etc/pacman.d/mirrorlist.backup
    awk '/^## Switzerland$/{f=1; next}f==0{next}/^## /{exit}{print substr($0, 1);}' /etc/pacman.d/mirrorlist.orig \
        | sudo tee -a /etc/pacman.d/mirrorlist.backup
    awk '/^## United States$/{f=1; next}f==0{next}/^## /{exit}{print substr($0, 1);}' /etc/pacman.d/mirrorlist.orig \
        | sudo tee -a /etc/pacman.d/mirrorlist.backup

    sudo sed -i 's/^#//' /etc/pacman.d/mirrorlist.backup

    rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup |sudo tee /etc/pacman.d/mirrorlist
fi

sudo pacman -Sy


# fc-match <font>
#    ttf-droid \
#    ttf-anonymous-pro \
#    ttf-liberation \
#    ttf-ubuntu-font-family \
#
# Definitely needed:
#    ttf-bitstream-vera \
#    ttf-dejavu   #else e.g. `xinput list` formating issues
#    adobe-source-han-sans-otc-fonts  # chinese symbols etc
#
# Not tested yet for chinese etc.
#    ttf-roboto noto-fonts noto-fonts-cjk adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts ttf-dejavu
sudo pacman -Su --needed \
    rxvt-unicode urxvt-perls \
    i3-wm xorg-server \
    i3status \
    i3lock \
    rofi \
    xf86-video-intel xorg-xinit \
    xorg-fonts-100dpi \
    xorg-fonts-75dpi \
    xorg-fonts-misc \
    xorg-fonts-type1 \
    ttf-dejavu \
    adobe-source-han-sans-otc-fonts \
    man \
    tmux \
    network-manager-applet \
    openssh \
    git \
    base-devel \
    thunderbird \
    borg \
    mpv \
    nextcloud-client \
    redshift \
    syncthing \
    light \
    strace \
    docker \
    docker-compose \
    gocryptfs \
    powertop \
    tlp tlp-rdw \
    eog \
    evince \
    bind-tools \
    lsb-release \
    bc \
    xautolock \
    xss-lock \
    gnome-keyring \
    virtualbox \
    maim \
    unrar \
    unzip \
    p7zip \
    fwupd \
    fprintd \
    dunst \
    cups \
    libreoffice-fresh \
    gimp \
    tigervnc \
    thunar \
    gvfs \
    wine \
    blueman \
    bluez \
    bluez-utils \
    nfs-utils \
    smbclient \


# Dependency installations
#   borg => python-llfuse
#   redshift => python-gobject
#   gnome-keyring => seahorse
#   linux-headers => linux + vbox
#   linux-lts-headers=> linux + virtualbox
#   virtualbox-host-dkms => LTS kernel, else module-arch would be sufficient
#   tlp => acpi_call
#   tlp => tlp-rdw
#   blueman => libappindicator-gtk3
#   cpus/printer: ghostscript and gsfonts (non-pdf printer), foomatic-db* (driver search)
#   acpi battery-monitor.sh
#   acpi battery-monitor.sh
sudo pacman -S --needed --asdeps \
    python-llfuse \
    python-gobject \
    seahorse \
    linux-headers \
    linux-lts-headers \
    virtualbox-host-dkms \
        virtualbox-guest-iso \
    xorg-xinput \
    xf86-input-synaptics \
    acpi_call \
    ghostscript \
        gsfonts \
        foomatic-db \
        foomatic-db-ppds \
        foomatic-db-nonfree \
        foomatic-db-nonfree-ppds \
        foomatic-db-engine \
        system-config-printer \
    acpi \
    xorg-xhost \
    thunar-volman \
    libappindicator-gtk3 \
    pulseaudio-bluetooth

# AUR packages
yay -S \
    google-chrome \
    joplin-desktop \
    discord_arch_electron \
    ttf-symbola \
    virtualbox-ext-oracle \
    slack-desktop \
    zoom \
    skypeforlinux-stable-bin \
    masterpdfeditor-free


# Fix audio
sudo pacman -S --needed \
    pavucontrol \
    alsa-utils \
    alsa-firmware \
    pulseaudio-alsa \
    pulseaudio-bluetooth \
    pulseaudio-equalizer
echo "options snd-intel-dspcfg dsp_driver=1" \
    | sudo tee /etc/modprobe.d/alsa.conf > /dev/null

# systemd
if [ ! -e ~/.config/systemd/user/battery-monitor.service ]; then
    mkdir -p ~/.config/systemd/user
    ln -s ~/repos/dotfiles/bin/battery-monitor.service \
        ~/.config/systemd/user/battery-monitor.service
    systemctl --user daemon-reload
    systemctl --user enable battery-monitor.service
    systemctl --user start battery-monitor.service
fi

# TLP
sudo systemctl enable tlp
# required by tlp-rdw
sudo systemctl enable NetworkManager-dispatcher
sudo systemctl mask systemd-rfkill.service
sudo systemctl mask systemd-rfkill.socket
echo "START_CHARGE_THRESH_BAT0=75" \
    | sudo tee /etc/tlp.d/01-laptop-charge.conf > /dev/null
echo "STOP_CHARGE_THRESH_BAT0=80"  \
    | sudo tee -a /etc/tlp.d/01-laptop-charge.conf > /dev/null

# automatic login
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF > /dev/null
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin volker --noclear %I \$TERM
# Make sure bash_profile is executed
Type=simple
EOF
# Don't clear tty
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo tee /etc/systemd/system/getty@tty1.service.d/noclear.conf <<EOF > /dev/null
[Service]
TTYVTDisallocate=no
EOF

#
# Printer setup
#

# avahi/systemd-resolved conflict, avahi used for cups printer search
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/cups-avahi-mdns.conf <<EOF > /dev/null
[Service]
# resolve or no
MulticastDNS=resolve
EOF

sudo systemctl enable avahi-daemon.service
sudo systemctl start avahi-daemon.service
# automatically start cups on socket request
sudo systemctl enable org.cups.cupsd.socket
sudo systemctl start org.cups.cupsd.socket

# link common applications
sudo ln -sf /usr/bin/google-chrome-stable /usr/bin/google-chrome
sudo ln -sf /usr/bin/nvim /usr/bin/vim

# Add user to group
sudo usermod -a -G docker volker
# video for light command
sudo usermod -a -G video volker
sudo usermod -a -G input volker
sudo usermod -a -G cups volker
sudo usermod -a -G vboxusers volker
#newgrp cups
#newgrp input
#newgrp docker

if ! grep "^user_allow_other" /etc/fuse.conf > /dev/null; then
    echo "user_allow_other" | sudo tee -a  /etc/fuse.conf
fi

# Install AUR packages that aren't available
yay -S --needed \
    pcloud-drive \
    fontconfig-ubuntu \
    activitywatch-bin \
    masterpdfeditor-free \
    activitywatch-bin \
    authy \


# VBOX
SUBSYSTEM=="usb_device", ACTION=="add", RUN+="/usr/share/virtualbox/VBoxCreateUSBNode.sh $major $minor vboxusers"
SUBSYSTEM=="usb", ACTION=="add", ENV{DEVTYPE}=="usb_device", RUN+="/usr/share/virtualbox/VBoxCreateUSBNode.sh $major $minor vboxusers"

umask 077
