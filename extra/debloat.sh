#!/bin/sh

yay --noconfirm

sudo pacman -Rns $(pacman -Qtdq) --noconfirm

yes | yay -Scc