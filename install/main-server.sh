#!/bin/sh
set -e
set -u
set -o pipefail

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
