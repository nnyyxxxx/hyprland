#!/bin/sh
ln -sf "$(cat $HOME/hyprland/extra/hyprwall/config.ini | grep last_wallpaper | cut -d'=' -f2 | xargs)" "$HOME/hyprland/extra/hyprwall/last_wallpaper"
exec hyprlock
