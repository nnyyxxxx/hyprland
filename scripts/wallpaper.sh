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
        
        if [ ! -w /opt/spotify ] || [ ! -w /opt/spotify/Apps ]; then
            pkexec chmod a+wr /opt/spotify
            pkexec chmod a+wr /opt/spotify/Apps -R
        fi

        mkdir -p ~/.config/spotify
        touch ~/.config/spotify/prefs
        
        color0=$(sed -n '1p' ~/.cache/wal/colors | sed 's/#//g')
        color1=$(sed -n '2p' ~/.cache/wal/colors | sed 's/#//g')
        color2=$(sed -n '3p' ~/.cache/wal/colors | sed 's/#//g')
        color3=$(sed -n '4p' ~/.cache/wal/colors | sed 's/#//g')
        color4=$(sed -n '5p' ~/.cache/wal/colors | sed 's/#//g')
        color5=$(sed -n '6p' ~/.cache/wal/colors | sed 's/#//g')
        color6=$(sed -n '7p' ~/.cache/wal/colors | sed 's/#//g')
        color7=$(sed -n '8p' ~/.cache/wal/colors | sed 's/#//g')

        cat > ~/.config/spicetify/Themes/Sleek/color.ini << EOF
[Pywal]
text               = ${color7}
subtext            = ${color7}
sidebar-text       = ${color7}
main              = ${color0}
sidebar           = ${color0}
player            = ${color0}
card              = ${color0}
shadow            = ${color0}
selected-row      = ${color3}
button            = ${color4}
button-active     = ${color4}
button-disabled   = ${color7}
tab-active        = ${color4}
notification      = ${color6}
notification-error = ${color1}
misc              = ${color2}
EOF

        /home/$USER/.spicetify/spicetify backup apply
        /home/$USER/.spicetify/spicetify config current_theme Sleek
        /home/$USER/.spicetify/spicetify config color_scheme Pywal
        /home/$USER/.spicetify/spicetify apply

        if pgrep -x spotify > /dev/null; then
            pkill -x spicetify
            /home/$USER/.spicetify/spicetify -q watch -s &
        fi
        
        last_value="$current_value"
    fi
done