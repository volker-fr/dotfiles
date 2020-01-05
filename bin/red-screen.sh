#!/bin/sh

if [ "$1" = "on" ]; then
  # Making screen red
  if [ "$(pgrep -c redshift-gtk)" != 0 ] || [ "$(pgrep -c redshift)" != 0 ]; then
    notify-send "stopping redshift"
    killall -9 redshift redshift-gtk || true
    sleep .2
  fi
  GAMMA=4:1.5:1
elif [ "$1" = "off" ]; then
  # Making screen normal
  GAMMA=1:1:1
  REDSHIFT=$(grep redshift ~/.i3/config|grep -v "^#"|sed 's/.*--no-startup-id //')
  $REDSHIFT &
else
  echo Requires one of: "on", "off"
  exit 128
fi

for output in $(xrandr --prop | grep \ connected | cut -d\  -f1); do
  xrandr --output "$output" --gamma $GAMMA
done
