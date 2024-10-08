#!/bin/sh

selection=$(rofi -i -theme "$HOME/.config/rofi/style-1.rasi" -dmenu $@ < /path-to-your/snippets.txt -p "󰅍")
printf "%b\n" "$selection" | wl-copy
sleep 0.1
