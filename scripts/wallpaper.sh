#!/bin/sh

config_dir="$HOME/hyprland/extra/hyprwall"
config_file="$config_dir/config.ini"
last_value=""

inotifywait -m -e modify,create "$config_dir" | while read -r directory events filename; do
    if [ "$filename" = "config.ini" ]; then
        current_value=$(grep "last_wallpaper" "$config_file" | cut -d'=' -f2 | tr -d ' ')
        if [ "$current_value" != "$last_value" ] && [ -n "$current_value" ]; then
            wal -i "$(echo "$current_value" | sed "s|^~|$HOME|")"
            killall waybar
            waybar &
            pywalfox update
            background=$(jq -r '.special.background' $HOME/.cache/wal/colors.json | sed 's/#//')
            echo "\$background = rgba(${background}FF)" >$HOME/.cache/wal/colors-hyprland.conf
            mkdir -p "$HOME/.config/vesktop/themes"
            cp $HOME/.cache/wal/discord-pywal.css "$HOME/.config/vesktop/themes/pywal.css"

            color0=$(sed -n '1p' $HOME/.cache/wal/colors | sed 's/#//g')
            color1=$(sed -n '2p' $HOME/.cache/wal/colors | sed 's/#//g')
            color2=$(sed -n '3p' $HOME/.cache/wal/colors | sed 's/#//g')
            color3=$(sed -n '4p' $HOME/.cache/wal/colors | sed 's/#//g')
            color4=$(sed -n '5p' $HOME/.cache/wal/colors | sed 's/#//g')
            color5=$(sed -n '6p' $HOME/.cache/wal/colors | sed 's/#//g')
            color6=$(sed -n '7p' $HOME/.cache/wal/colors | sed 's/#//g')
            color7=$(sed -n '8p' $HOME/.cache/wal/colors | sed 's/#//g')

            find $HOME/hyprland/extra/gtk-3.0/dark-horizon/gtk-3.0/ -name "*.css" -exec sed -i 's/background-color: #[0-9a-fA-F]\+;*/background-color: #'"${color0}"';/g' {} \;

            find $HOME/hyprland/extra/gtk-3.0/dark-horizon/gtk-4.0/ -name "*.css" -exec sed -i 's/background-color: #[0-9a-fA-F]\+;*/background-color: #'"${color0}"';/g' {} \;

            gsettings set org.gnome.desktop.interface gtk-theme "dummy"
            gsettings set org.gnome.desktop.interface gtk-theme "dark-horizon"

            sed -i "s/@base: #[0-9a-fA-F]\+;/@base: #${color0};/g" "$HOME/hyprland/extra/librewolf/catppuccin.json"
            sed -i "s/@mantle: #[0-9a-fA-F]\+;/@mantle: #${color0};/g" "$HOME/hyprland/extra/librewolf/catppuccin.json"
            sed -i "s/@crust: #[0-9a-fA-F]\+;/@crust: #${color0};/g" "$HOME/hyprland/extra/librewolf/catppuccin.json"

            cat >$HOME/hyprland/extra/wlogout/style.css <<EOF
window {
	background-color: rgba(12, 12, 12, 0.9);
}

button {
    border-radius: 0;
    border-color: #${color2};
    color: #${color7};
    background-color: #${color0};
    border-style: solid;
    border-width: 1px;
    background-repeat: no-repeat;
    background-position: center;
    background-size: 25%;
}

button:focus, button:active, button:hover {
    background-color: #232023;
    outline-style: none;
}

#lock {
    background-image: image(url("/usr/share/wlogout/icons/lock.png"), url("/usr/local/share/wlogout/icons/lock.png"));
}

#logout {
    background-image: image(url("/usr/share/wlogout/icons/logout.png"), url("/usr/local/share/wlogout/icons/logout.png"));
}

#suspend {
    background-image: image(url("/usr/share/wlogout/icons/suspend.png"), url("/usr/local/share/wlogout/icons/suspend.png"));
}

#hibernate {
    background-image: image(url("/usr/share/wlogout/icons/hibernate.png"), url("/usr/local/share/wlogout/icons/hibernate.png"));
}

#shutdown {
    background-image: image(url("/usr/share/wlogout/icons/shutdown.png"), url("/usr/local/share/wlogout/icons/shutdown.png"));
}

#reboot {
    background-image: image(url("/usr/share/wlogout/icons/reboot.png"), url("/usr/local/share/wlogout/icons/reboot.png"));
}
EOF

            cat >$HOME/hyprland/extra/dunst/dunstrc <<EOF
[global]
    width = 300
    height = 100
    offset = 6x6
    padding = 16
    horizontal_padding = 16
    frame_width = 1
    frame_color = "#${color2}"
    separator_color = "#${color2}"
    font = JetBrainsMono Nerd Font 10
    line_height = 4
    corner_radius = 5
    origin = top-left

    background = "#${color0}"
    foreground = "#${color7}"

    timeout = 5
    idle_threshold = 120

[urgency_low]
    background = "#${color0}"
    foreground = "#${color7}"
    timeout = 5

[urgency_normal]
    background = "#${color0}"
    foreground = "#${color7}"
    timeout = 5

[urgency_critical]
    background = "#${color0}"
    foreground = "#${color1}"
    timeout = 0
EOF

            cat >$HOME/hyprland/extra/hyprlauncher/config.json <<EOF
{
  "window": {
    "anchor": "left",
    "border_color": "#${color2}",
    "border_width": 2,
    "height": 1430,
    "margin_bottom": 0,
    "margin_left": 0,
    "margin_right": 0,
    "margin_top": 0,
    "show_border": true,
    "show_descriptions": false,
    "show_icons": true,
    "show_paths": false,
    "show_search": true,
    "show_scrollbar": false,
    "vim_keys": true,
    "width": 600
  },
  "theme": {
    "colors": {
      "window_bg": "#${color0}",
      "item_bg": "#${color0}",
      "item_bg_hover": "#${color2}",
      "item_bg_selected": "#${color2}",
      "search_bg": "#${color2}",
      "search_bg_focused": "#${color2}",
      "search_text": "#${color7}",
      "search_caret": "#${color7}",
      "item_name": "#${color7}",
      "item_description": "#${color7}",
      "item_path": "#${color7}"
    },
    "corners": {
      "window": 12,
      "list_item": 8,
      "search": 8
    },
    "spacing": {
      "item_padding": 4,
      "item_margin": 6,
      "search_margin": 12,
      "search_padding": 12
    },
    "typography": {
      "search_font_size": 16,
      "item_name_size": 14,
      "item_description_size": 12,
      "item_path_size": 12,
      "item_path_font_family": "monospace"
    }
  }
}
EOF

            pkill dunst
            dunst &

            if ! grep -q "\[color\]" "$HOME/hyprland/extra/cava/config"; then
                printf "\n[color]\nbackground = '#%s'\ngradient = 1\n" "$color0" >>"$HOME/hyprland/extra/cava/config"
                i=1
                while [ $i -le 8 ]; do
                    eval "current_color=\$color$((8 - i))"
                    printf "gradient_color_%d = '#%s'\n" "$i" "$current_color" >>"$HOME/hyprland/extra/cava/config"
                    i=$((i + 1))
                done
            else
                color_section=$(
                    cat <<EOF
[color]
background = '#${color0}'
gradient = 1

gradient_color_1 = '#${color7}'
gradient_color_2 = '#${color6}'
gradient_color_3 = '#${color5}'
gradient_color_4 = '#${color4}'
gradient_color_5 = '#${color3}'
gradient_color_6 = '#${color2}'
gradient_color_7 = '#${color1}'
gradient_color_8 = '#${color0}'

EOF
                )
                awk -v colors="$color_section" '
                /\[color\]/ { print colors; skip = 1; next }
                /^\[/ { skip = 0 }
                !skip { print }
            ' "$HOME/hyprland/extra/cava/config" >"$HOME/hyprland/extra/cava/config.tmp" &&
                    mv "$HOME/hyprland/extra/cava/config.tmp" "$HOME/hyprland/extra/cava/config"
            fi

            pkill cava
            cava &

            cat >$HOME/hyprland/hypr/dark-horizon.conf <<EOF
\$background = rgb(${color0})
\$backgroundAlpha = ${color0}

\$backgroundAlt = rgb(${color0})
\$backgroundAltAlpha = ${color0}

\$foreground = rgb(${color7})
\$foregroundAlpha = ${color7}

\$selected = rgb(${color4})
\$selectedAlpha = ${color4}

\$active = rgb(${color5})
\$activeAlpha = ${color5}

\$urgent = rgb(${color1})
\$urgentAlpha = ${color1}
EOF

            if [ ! -w "/usr/share/sddm/themes/corners/backgrounds" ]; then
                pkexec chmod 777 /usr/share/sddm/themes/corners/backgrounds
            fi

            if [ ! -w "/usr/share/sddm/themes/corners/theme.conf" ]; then
                pkexec chmod 666 /usr/share/sddm/themes/corners/theme.conf
            fi

            cp "$(eval echo "$current_value")" /usr/share/sddm/themes/corners/backgrounds/wallpaper.png
            cat >/tmp/sddm-theme.conf <<EOF
[General]
BgSource="backgrounds/wallpaper.png"
FontFamily="JetBrainsMono Nerd Font"
FontSize=14
Padding=50
Radius=10
Scale=1

UserPictureEnabled=true
UserBorderWidth=1
UserBorderColor="#${color2}"
UserColor="#${color0}"

InputColor="#${color0}"
InputTextColor="#${color7}"
InputBorderWidth=1
InputBorderColor="#${color2}"
UserPlaceholderText="user"
PassPlaceholderText="password"
HidePassword=true

LoginButtonTextColor="#${color0}"
LoginButtonText="Login"
LoginButtonColor="#${color7}"

PopupColor="#${color0}"
PopupActiveColor="#${color7}"
PopupActiveTextColor="#${color0}"

SessionButtonColor="#${color0}"
SessionIconColor="#${color7}"
PowerButtonColor="#${color0}"
PowerIconColor="#${color7}"

DateTimeSpacing=-20

DateColor="#${color7}"
DateSize=36
DateIsBold=false
DateOpacity=1.0
DateFormat="dddd, MMMM d"

TimeColor="#${color7}"
TimeSize=48
TimeIsBold=true
TimeOpacity=1.0
TimeFormat="hh:mm AP"
EOF
            cp /tmp/sddm-theme.conf /usr/share/sddm/themes/corners/theme.conf
            rm /tmp/sddm-theme.conf

            pkill hyprlock

            if [ ! -w /opt/spotify ] || [ ! -w /opt/spotify/Apps ]; then
                pkexec chmod a+wr /opt/spotify
                pkexec chmod a+wr /opt/spotify/Apps -R
            fi

            mkdir -p ~/.config/spotify
            touch ~/.config/spotify/prefs

            cat >~/.config/spicetify/Themes/Sleek/color.ini <<EOF
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

            /home/$USER/.spicetify/spicetify config current_theme Sleek
            /home/$USER/.spicetify/spicetify config color_scheme Pywal
            /home/$USER/.spicetify/spicetify apply

            if hyprctl clients | grep "Spotify"; then
                /home/$USER/.spicetify/spicetify watch -s &
                sleep 1 && pkill spicetify
            fi

            last_value="$current_value"
        fi
    fi
done
