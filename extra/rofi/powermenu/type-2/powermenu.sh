#!/bin/sh

# Current Theme
dir="$HOME/.config/rofi/powermenu/type-2"
theme='style-5'

# CMDs
uptime="$(uptime -p | sed -e 's/up //g')"
host=$(hostname)

# Options
shutdown=''
reboot=''
lock='󰌾'
suspend='󰒲'
logout='󰍃'
yes=''
no=''

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-p "Uptime: $uptime" \
		-mesg "Uptime: $uptime" \
		-theme "${dir}/${theme}.rasi"
}

# Confirmation CMD
confirm_cmd() {
	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
		-theme-str 'mainbox {children: [ "message", "listview" ];}' \
		-theme-str 'listview {columns: 2; lines: 1;}' \
		-theme-str 'element-text {horizontal-align: 0.5;}' \
		-theme-str 'textbox {horizontal-align: 0.5;}' \
		-dmenu \
		-p 'Confirmation' \
		-mesg 'Are you Sure?' \
		-theme "${dir}/${theme}.rasi"
}

# Ask for confirmation
confirm_exit() {
	printf "%s\n%s\n" "$yes" "$no" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
	printf "%s\n%s\n%s\n%s\n%s\n" "$lock" "$suspend" "$logout" "$reboot" "$shutdown" | rofi_cmd
}

# Execute Command
run_cmd() {
	selected="$(confirm_exit)"
	if [ "$selected" = "$yes" ]; then
		case "$1" in
			'--shutdown')
				systemctl poweroff
				;;
			'--reboot')
				systemctl reboot
				;;
			'--suspend')
				mpc -q pause
				amixer set Master mute
				systemctl suspend
				;;
			'--logout')
				case "$DESKTOP_SESSION" in
					'openbox')
						openbox --exit
						;;
					'bspwm')
						bspc quit
						;;
					'i3')
						i3-msg exit
						;;
					'plasma')
						qdbus org.kde.ksmserver /KSMServer logout 0 0 0
						;;
					"xfce")
						killall xfce4-session
						;;
					"hyprland")
						killall Hyprland
						;;
				esac
				;;
		esac
	else
		exit 0
	fi
}

# Actions
chosen="$(run_rofi)"
case "$chosen" in
	"$shutdown")
		run_cmd --shutdown
		;;
	"$reboot")
		run_cmd --reboot
		;;
	"$lock")
		swaylock
		;;
	"$suspend")
		run_cmd --suspend
		;;
	"$logout")
		run_cmd --logout
		;;
esac
