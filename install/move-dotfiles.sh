#!/usr/bin/env bash
set -e
set -u
set -o pipefail

# Alert/Move the dotfiles instead they are where they shouldn't
IFS=$'\n'
DIRS="
$HOME/.thunderbird
$HOME/.bashrc.local
$HOME/.zshrc.local
$HOME/.kube
$HOME/.config/borg
$HOME/.config/discord
$HOME/.config/mpv
$HOME/.config/Nextcloud
$HOME/.config/Authy Desktop
$HOME/snap/authy/current/.config/Authy Desktop
$HOME/.config/pcloud
$HOME/.config rclone
$HOME/.config/syncthing
$HOME/.config/Slack
$HOME/snap/slack/current/.config/Slack
$HOME/.config/google-chrome
$HOME/.config/skypeforlinux
$HOME/.gitconfig
$HOME/.mozilla/firefox
$HOME/.config/VirtualBox
$HOME/.local/share/activitywatch
$HOME/.local/share/TelegramDesktop
$HOME/.local/share/keyrings
$HOME/.local/share/fonts
$HOME/.zotero
"
for DIR in $DIRS; do
    DIR_NAME=$(basename "$DIR")

    # cut dot in beginning of filename
    if echo "$DIR_NAME" | grep "^\." > /dev/null; then
        DIR_NAME=$(echo "$DIR_NAME"|cut -c2-)
    fi
    DESTINATION="$HOME/localdata/dotfiles/$DIR_NAME"

    # Move/link if it doesn't exists
    if [ -e "$DIR" ] && [ ! -L "$DIR" ]; then
        if [ -e "$DESTINATION" ]; then
            echo "$DESTINATION already exists, please delete it before $DIR can be moved there"
            exit 1
        fi
        mv "$DIR" "$DESTINATION"
        ln -s "$DESTINATION" "$DIR"
    fi

    # exists, but not linked
    if [ -e "$DESTINATION" ] && [ ! -e "$DIR" ]; then
        echo "$DESTINATION exists, but not $DIR. Linking."
        ln -s "$DESTINATION" "$DIR"
    fi
done
