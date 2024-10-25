#!/bin/sh

dir="$HOME/.config/rofi/powermenu/type-2"
theme='style-5'

uptime="$(uptime -p | sed -e 's/up //g')"

shutdown=''
reboot=''
lock='󰌾'
suspend='󰒲'
logout='󰍃'
yes=''
no=''

rofi_cmd() {
	rofi -dmenu \
		-p "Uptime: $uptime" \
		-mesg "Uptime: $uptime" \
		-theme "${dir}/${theme}.rasi"
}

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

confirm_exit() {
	printf "%s\n%s\n" "$yes" "$no" | confirm_cmd
}

run_rofi() {
	printf "%s\n%s\n%s\n%s\n%s\n" "$lock" "$suspend" "$logout" "$reboot" "$shutdown" | rofi_cmd
}

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

chosen="$(run_rofi)"
case "$chosen" in
	"$shutdown")
		run_cmd --shutdown
		;;
	"$reboot")
		run_cmd --reboot
		;;
	"$lock")
		hyprlock
		;;
	"$suspend")
		run_cmd --suspend
		;;
	"$logout")
		run_cmd --logout
		;;
esac
