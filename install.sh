sudo apt install -y encfs
sudo apt install -y iotop vim git redshift-gtk tmux keepass2
sudo apt install -y owncloud-client

# i3
echo "deb http://debian.sur5r.net/i3/ $(lsb_release -c -s) universe" |sudo tee -a /etc/apt/sources.list.d/i3wm.list
sudo apt update
sudo apt --allow-unauthenticated install -y sur5r-keyring
sudo apt install -y i3

# virtualbox
echo "deb http://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib non-free" |sudo tee /etc/apt/sources.list.d/virtualbox.list
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
sudo apt update
sudo apt install -y virtualbox virtualbox-guest-additions-iso

sudo apt install -y docker rxvt-unicode-256color


sudo usermod -a -G docker volker

sudo apt install -y mplayer vlc
sudo apt install -y openssh-server
sudo apt install -y duplicity python-boto

cd /tmp
wget https://releases.hashicorp.com/vagrant/1.8.7/vagrant_1.8.7_x86_64.deb
sudo dpkg -i vagrant_1.8.7_x86_64.deb

sudo apt-get remove -y --purge firefox
