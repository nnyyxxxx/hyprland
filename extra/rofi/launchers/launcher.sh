#!/bin/sh

dir="$HOME/.config/rofi"
theme='style-1'

## Run
rofi \
    -show drun \
    -theme ${dir}/${theme}.rasi
