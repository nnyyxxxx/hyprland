#!/bin/sh

cd ~/hyprland/extra/keybindapp && python -m venv venv && . ~/hyprland/extra/keybindapp/venv/bin/activate && pip install PyQt6 && exec python keybinds.py