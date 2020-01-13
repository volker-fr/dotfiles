#!/bin/sh

# Based on
# https://web.archive.org/web/20190226045718/https://azer.bike/journal/low-battery-monitor-for-linux-i3

battery_level=$(acpi -b | cut -d ' ' -f 4 | grep -o '[0-9]*')
battery_state=$(acpi | grep 'Battery' | sed 's/Battery\s[0-9]*: //' | sed 's/, [0-9][0-9]*\%.*//')
battery_remaining=$(acpi | grep -oh '[0-9:]* remaining' | sed 's/:\w\w remaining$/ Minutes/'  | sed 's/00://' | sed 's/:/h /')

checkBatteryLevel() {
    if [ $battery_state != "Discharging" ]; then
        exit
    fi

    if [ "$battery_level" -le 4 ]; then
        systemctl suspend
    elif [ "$battery_level" -le 7 ]; then
        notify-send "Low Battery" "Your computer will suspend soon unless plugged into a power outlet." -u critical
        ( speaker-test -t sine -f 1000 )& pid=$! ; sleep 2s ; kill -9 $pid
    elif [ "$battery_level" -le 20 ] ||  [ "$battery_level" -le 30 ]; then
        notify-send "Low Battery" "${battery_level}% (${battery_remaining}) of battery remaining." -u normal
    fi
}
checkBatteryLevel
