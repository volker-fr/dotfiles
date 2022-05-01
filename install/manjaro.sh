#!/bin/sh
set -e
set -u
set -o pipefail

# make configuration files we create readable by the user
umask 022

#
# Find the quickest mirror before we install anything
#
#if [ ! -e /etc/pacman.d/mirrorlist.orig ]; then
#    sudo pacman -Suu --needed pacman-contrib
#
#    sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.orig
#
#    awk '/^## Worldwide$/{f=1; next}f==0{next}/^## /{exit}{print substr($0, 1);}' /etc/pacman.d/mirrorlist.orig \
#        | sudo tee /etc/pacman.d/mirrorlist.backup
#    awk '/^## Switzerland$/{f=1; next}f==0{next}/^## /{exit}{print substr($0, 1);}' /etc/pacman.d/mirrorlist.orig \
#        | sudo tee -a /etc/pacman.d/mirrorlist.backup
#    awk '/^## United States$/{f=1; next}f==0{next}/^## /{exit}{print substr($0, 1);}' /etc/pacman.d/mirrorlist.orig \
#        | sudo tee -a /etc/pacman.d/mirrorlist.backup
#
#    sudo sed -i 's/^#//' /etc/pacman.d/mirrorlist.backup
#
#    rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup |sudo tee /etc/pacman.d/mirrorlist
#fi
#
#sudo pacman -Sy

#
# regular packages
#

# Removed from arch linux list. Removed most likely not needed, check
# these might be needed in the future
#rxvt-unicode urxvt-perls \
#xf86-video-intel \
#adobe-source-han-sans-otc-fonts \
#powertop \
#tlp tlp-rdw \
#fwupd \
#fprintd \
#cups \
#wine \
#bluez-utils \
sudo pacman -Su --needed \
    neovim \
    rxvt-unicode \
    i3-wm \
    i3status \
    i3lock \
    rofi \
    tmux \
    base-devel \
    thunderbird \
    borg \
    mpv \
    nextcloud-client \
    redshift \
    syncthing \
    light \
    lshw \
    strace \
    docker \
    docker-compose \
    gocryptfs \
    eog \
    evince \
    bind-tools \
    xorg-xrandr \
    xautolock \
    xss-lock \
    virtualbox \
    maim \
    dunst \
    libreoffice-fresh \
    gimp \
    tigervnc \
    gvfs \
    yay \
    kubectl \
    xorg-fonts-100dpi \
    xorg-fonts-75dpi \
    xorg-fonts-misc \
    xorg-fonts-type1 \
    ttf-linux-libertine \
    manjaro-printer \
    system-config-printer


#
# FROM ARCH LINUX, cleaned up list
#
# Dependency installations
#   borg => python-llfuse
#   gnome-keyring => seahorse
#   linux-headers => linux + vbox
#   linux-lts-headers=> linux + virtualbox
#   tlp => acpi_call
#   tlp => tlp-rdw
#   blueman => libappindicator-gtk3
#   cpus/printer: foomatic-db* (driver search)
#
# Removed from arch linux list. Removed most likely not needed, check
# these might be needed in the future
#python-llfuse \
#seahorse \
#linux-lts-headers \
#xorg-xinput \
#xf86-input-synaptics \
#acpi_call \
#    foomatic-db \
#    foomatic-db-ppds \
#    foomatic-db-nonfree \
#    foomatic-db-nonfree-ppds \
#    foomatic-db-engine \
#    system-config-printer \
#xorg-xhost \
sudo pacman -S --needed --asdeps \
    linux-headers \
    linux59-virtualbox-host-modules
    virtualbox-guest-iso \

# load the new installed kernel modules:
sudo vboxreload

# AUR packages
# From Arch linux, maybe we need it, maybe not?
#ttf-symbola \
# On install issues
#yay -S --mflags='--nocheck'  fontconfig-ubuntu
yay -S \
    google-chrome \
    joplin-desktop \
    discord_arch_electron \
    virtualbox-ext-oracle \
    slack-desktop \
    zoom \
    skypeforlinux-stable-bin \
    masterpdfeditor-free \
    telegram-desktop \
    fontconfig-ubuntu

# Fix audio
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

## TLP
#sudo systemctl enable tlp
## required by tlp-rdw
#sudo systemctl enable NetworkManager-dispatcher
#sudo systemctl mask systemd-rfkill.service
#sudo systemctl mask systemd-rfkill.socket
#echo "START_CHARGE_THRESH_BAT0=75" \
#    | sudo tee /etc/tlp.d/01-laptop-charge.conf > /dev/null
#echo "STOP_CHARGE_THRESH_BAT0=80"  \
#    | sudo tee -a /etc/tlp.d/01-laptop-charge.conf > /dev/null

##
## Printer setup
##
#
## avahi/systemd-resolved conflict, avahi used for cups printer search
## this didn't fix it...
#sudo mkdir -p /etc/systemd/resolved.conf.d
#sudo tee /etc/systemd/resolved.conf.d/cups-avahi-mdns.conf <<EOF > /dev/null
#[Service]
## resolve or no
#MulticastDNS=resolve
#EOF

## install nss-dns, see https://wiki.archlinux.org/index.php/Avahi#Hostname_resolution
#sudo pacman -S nss-mdns
#sudo systemctl restart avahi-daemon.service
# Some other random suggestion, but that could be related to "adding a printer"
# can't uninstall because its required by manjaro-printer, but somehow it wasn't
# automatically installed
sudo pacman -S cups-pdf

sudo systemctl disable systemd-resolved.service


#sudo systemctl enable avahi-daemon.service
#sudo systemctl start avahi-daemon.service
# automatically start cups on socket request
sudo systemctl enable --now cups.socket
sudo systemctl start cups.socket
# maybe in manjaro
#sudo systemctl enable --now cups.service
sudo systemctl enable --now cups.path
sudo usermod -a -G cups volker

# link common applications
sudo ln -sf /usr/bin/google-chrome-stable /usr/bin/google-chrome
sudo ln -sf /usr/bin/nvim /usr/bin/vim

## Add user to group
#sudo usermod -a -G docker volker
#sudo usermod -a -G input volker
#sudo usermod -a -G cups volker
##newgrp cups
##newgrp input
##newgrp docker
#
#if ! grep "^user_allow_other" /etc/fuse.conf > /dev/null; then
#    echo "user_allow_other" | sudo tee -a  /etc/fuse.conf
#fi

## Install AUR packages that aren't available
#yay -S --needed \
#    pcloud-drive \
#    fontconfig-ubuntu \
#    activitywatch-bin \
#    masterpdfeditor-free
#
umask 077
