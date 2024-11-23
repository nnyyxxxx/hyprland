#!/bin/sh

paru -Syu --noconfirm

sudo pacman -Rns $(pacman -Qtdq) --noconfirm

yes | paru -Scc
