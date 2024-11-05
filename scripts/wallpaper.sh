#!/bin/sh

config_file="$HOME/hyprland/extra/hyprwall/config.ini"
last_value=""

while true; do
    inotifywait -e modify "$config_file" >/dev/null 2>&1
    current_value=$(grep "last_wallpaper" "$config_file" | cut -d'=' -f2 | tr -d ' ')
    if [ "$current_value" != "$last_value" ] && [ -n "$current_value" ]; then
        wal -i "$(echo "$current_value" | sed "s|^~|$HOME|")"
        killall waybar; waybar &
        pywalfox update
        background=$(jq -r '.special.background' ~/.cache/wal/colors.json | sed 's/#//')
        echo "\$background = rgba(${background}FF)" > ~/.cache/wal/colors-hyprland.conf
        mkdir -p "$HOME/.config/vesktop/themes"
        cp ~/.cache/wal/discord-pywal.css "$HOME/.config/vesktop/themes/pywal.css"
        last_value="$current_value"
    fi
done