#!/bin/bash
repos(){
    cat > /etc/apt/sources.list <<EOF
deb http://ftp.us.debian.org/debian/ buster main contrib non-free
deb-src http://ftp.us.debian.org/debian/ buster main contrib non-free

deb http://security.debian.org/debian-security buster/updates main contrib non-free
deb-src http://security.debian.org/debian-security buster/updates main contrib non-free
EOF

    # docker
    cat > /etc/apt/sources.list.d/docker.list <<EOF
deb https://download.docker.com/linux/debian buster stable
EOF
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

    apt update && apt upgrade
}

# Packages required for installation of repos etc.
main_packages() {
    apt install \
        --no-install-recommends \
        -y \
        curl \
        gnupg \
        apt-transport-https \
        ca-certificates
}

# Other packages not required for installation
general_packages() {
    # gnome-keyring: for network-manager-gnome
    apt install \
        --no-install-recommends \
        -y \
        openssh-server \
        sudo \
        tmux \
        docker-ce \
        man-db \
        xorg \
        lightdm \
        network-manager-gnome \
        gnome-keyring \
        rxvt-unicode-256color \
        encfs \
        rsync \
        git \
        wget
}

systemspecific_packages() {
    apt install \
        --no-install-recommends \
        -y \
        xserver-xorg-video-intel \
        firmware-iwlwifi
}

group_permissions() {
    usermod -a -G sudo,docker,netdev volker
}


main_packages
repos
general_packages
systemspecific_packages
group_permissions

