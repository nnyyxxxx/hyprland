#!/bin/sh

if [ ! -d ~/hyprland/extra/keybindapp/venv ]; then
    cd ~/hyprland/extra/keybindapp && python -m venv venv && . ~/hyprland/extra/keybindapp/venv/bin/activate && pip install PyQt6 && exec python keybinds.py
else
    cd ~/hyprland/extra/keybindapp && . ~/hyprland/extra/keybindapp/venv/bin/activate && exec python keybinds.py
fi