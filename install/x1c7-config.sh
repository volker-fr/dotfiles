#!/bin/sh
set -e
set -u
set -o pipefail

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
        # other packages supposedly helpful for energy savings
        sudo apt-ge tinstall acpitool tp-smapi-dkms ethtool smartmontools ssmtp \
            libcpufreq0 indicator-cpufreq
    fi

    # change in pulseaudio the profile, then:
    # via: pacmd list-cards | grep 'active profile'
    # test via: pactl set-card-profile <symbolic_name> <profilename>
    #if ! grep set-card-profile /etc/pulse/default.pa > /dev/null; then
    #    echo "set-card-profile alsa_card.pci-0000_00_1f.3 output:analog-surround-40+input:analog-stereo" \
    #       | sudo tee -a /etc/pulse/default.pa > /dev/null
    #fi

    if ! grep '^\[Element Master\]' /usr/share/pulseaudio/alsa-mixer/paths/analog-output.conf.common > /dev/null; then
        sudo sed -i '/^\[Element PCM\]/i [Element Master]\nswitch = mute\n;volume-limit = 0.01\nvolume-limit = 0.1\n;volume = ignore\n' \
            /usr/share/pulseaudio/alsa-mixer/paths/analog-output.conf.common
    fi

    echo
    echo "Audio"
    echo "====="
    echo "Maybe: https://forums.lenovo.com/t5/Ubuntu/Guide-X1-Carbon-7th-Generation-Ubuntu-compatability/m-p/4489823#M2761<Paste>"
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
