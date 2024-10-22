#!/bin/sh

dir="$HOME/.config/rofi"
theme='style-1'

selection=$(nmcli -f SSID,RATE,SIGNAL,BARS,SECURITY device wifi list --rescan no | 
        awk 'NR>1 && $1 != "--" {print $1,$2,$3,$4,$5}' | 
        sort -u | 
        rofi -dmenu -theme ${dir}/${theme}.rasi -p " " -lines 10)

[ -z "$selection" ] && exit 1

ssid=$(echo "$selection" | awk '{print $1}')

if nmcli -f SSID connection show --active | grep -q "$ssid"; then
    nmcli device wifi connect "$ssid" && notify-send "📶 WiFi Connected" || notify-send "❌ Failed to connect"
else
    pass=$(rofi -dmenu -password -theme-str 'textbox-prompt-colon {str: "";}' -theme ${dir}/${theme}.rasi -p "Enter password")
    [ -z "$pass" ] && notify-send "🔑 Password not entered" && exit 1
    nmcli device wifi connect "$ssid" password "$pass" && notify-send "📶 New WiFi Connected" || notify-send "❌ Failed to connect"
fi
