#!/usr/bin/env bash

selection=$(rofi -i -theme "$HOME/.config/rofi/style-1.rasi" -dmenu $@ < /path-to-your/snippets.txt -p "󰅍")
snippet=$(echo $selection)
echo -n "$snippet" | wl-copy
sleep 0.1
