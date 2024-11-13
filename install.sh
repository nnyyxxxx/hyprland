#!/bin/sh

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

warning() {
    if ! command -v pacman >/dev/null 2>&1; then
        printf "%b\n" "${RED}:: Automated installation is only available for Arch-based distributions, install manually.${RC}"
        exit 1
    fi
}

setEscalationTool() {
    if command -v sudo >/dev/null 2>&1; then
        ESCALATION_TOOL="sudo"
    elif command -v doas >/dev/null 2>&1; then
        ESCALATION_TOOL="doas"
    fi
}

requestElevation() {
    if [ "$ESCALATION_TOOL" = "sudo" ]; then
        { sudo -v && clear; } || { printf "%b\n" "${RED}:: Failed to gain elevation.${RC}"; }
    elif [ "$ESCALATION_TOOL" = "doas" ]; then
        { doas true && clear; } || { printf "%b\n" "${RED}:: Failed to gain elevation.${RC}"; }
    fi
}

moveToHome() {
    cd "$HOME" || {
        printf "%b\n" "${RED}:: Failed to move to home directory.${RC}"
        exit 1
    }
}

cloneRepo() {
    printf "%b\n" "${YELLOW}:: Cloning repository...${RC}"
    rm -rf "$HOME/hyprland" >/dev/null 2>&1 || {
        printf "%b\n" "${RED}:: Failed to remove old hyprland directory.${RC}"
        exit 1
    }
    $ESCALATION_TOOL pacman -S --needed --noconfirm git base-devel >/dev/null 2>&1 || {
        printf "%b\n" "${RED}:: Failed to install git.${RC}"
        exit 1
    }
    git clone https://github.com/nnyyxxxx/hyprland "$HOME/hyprland" >/dev/null 2>&1 || {
        printf "%b\n" "${RED}:: Failed to clone hyprland.${RC}"
        exit 1
    }
}

declareFuncs() {
    printf "%b\n" "${YELLOW}:: Setting up directories...${RC}"
    HYPRLAND_DIR="$HOME/hyprland"
    mkdir -p "$HOME/.config"
    XDG_CONFIG_HOME="$HOME/.config"
    USERNAME=$(whoami)
}

installAURHelper() {
    printf "%b\n" "${YELLOW}:: Checking for AUR helper...${RC}"

    if command -v yay >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}:: Removing yay...${RC}"
        $ESCALATION_TOOL pacman -Rns --noconfirm yay >/dev/null 2>&1 || {
            printf "%b\n" "${RED}:: Failed to remove yay.${RC}"
            exit 1
        }
    fi

    if ! command -v paru >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}:: Installing paru AUR helper...${RC}"
        $ESCALATION_TOOL pacman -S --needed --noconfirm base-devel >/dev/null 2>&1 || {
            printf "%b\n" "${RED}:: Failed to install build dependencies.${RC}"
            exit 1
        }
        git clone https://aur.archlinux.org/paru-bin.git "$HOME/paru-bin" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to clone paru.${RC}"; }
        cd "$HOME/paru-bin"
        printf "%b\n" "${YELLOW}:: Building paru...${RC}"
        makepkg -si --noconfirm >/dev/null 2>&1
        cd "$HOME"
        rm -rf "$HOME/paru-bin"
        printf "%b\n" "${GREEN}:: Paru installed successfully${RC}"
    fi

    printf "%b\n" "${GREEN}:: Using paru as AUR helper${RC}"
    AUR_HELPER="paru"
}

setSysOps() {
    printf "%b\n" "${YELLOW}:: Configuring system settings...${RC}"
    printf "%b\n" "${YELLOW}:: Setting up Parallel Downloads...${RC}"
    $ESCALATION_TOOL sed -i 's/^#ParallelDownloads = 5$/ParallelDownloads = 5/' /etc/pacman.conf >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set Parallel Downloads.${RC}"; }

    printf "%b\n" "${YELLOW}:: Setting up default cursor...${RC}"
    $ESCALATION_TOOL mkdir -p /usr/share/icons/default
    $ESCALATION_TOOL touch /usr/share/icons/default/index.theme
    $ESCALATION_TOOL sed -i 's/^Inherits=Adwaita$/Inherits=bibata-classic-xcursor/' /usr/share/icons/default/index.theme >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set bibata cursor.${RC}"; }
    printf "%b\n" "${GREEN}:: System settings configured successfully${RC}"
}

installDeps() {
    printf "%b\n" "${YELLOW}:: Installing dependencies...${RC}"
    printf "%b\n" "${YELLOW}:: This might take a minute or two...${RC}"
    total_steps=2
    current_step=1

    $ESCALATION_TOOL pacman -Rns --noconfirm \
        lightdm gdm lxdm lemurs emptty xorg-xdm ly hyprland-git >/dev/null 2>&1

    $ESCALATION_TOOL pacman -S --needed --noconfirm \
        cliphist waybar grim slurp hyprpicker hyprpaper bleachbit hyprland fastfetch cpio \
        pipewire ttf-jetbrains-mono-nerd noto-fonts-emoji ttf-liberation ttf-dejavu meson \
        ttf-fira-sans ttf-fira-mono polkit-kde-agent xdg-desktop-portal zip unzip cmake \
        qt5-graphicaleffects qt5-quickcontrols2 noto-fonts-extra noto-fonts-cjk noto-fonts \
        cmatrix gtk3 neovim pamixer mpv feh zsh kitty dash pipewire-pulse easyeffects \
        btop zoxide zsh-syntax-highlighting ffmpeg xdg-desktop-portal-hyprland qt5-wayland \
        hypridle hyprlock qt6-wayland lsd libnotify dunst bat sddm jq python-pywal python-watchdog \
        python xorg-xhost timeshift yazi inotify-tools checkbashisms shfmt fzf >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to install dependencies.${RC}"; }
    printf "%b\n" "${GREEN}:: Dependencies installed (${current_step}/${total_steps})${RC}"
    current_step=$((current_step + 1))

    $AUR_HELPER -S --needed --noconfirm \
        cava pipes.sh checkupdates-with-aur librewolf-bin hyprwall-bin wlogout \
        python-pywalfox-librewolf spotify vesktop-bin hyprlauncher-bin >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to install AUR dependencies.${RC}"; }
    printf "%b\n" "${GREEN}:: AUR dependencies installed (${current_step}/${total_steps})${RC}"
}

setupConfigurations() {
    printf "%b\n" "${YELLOW}:: Setting up configuration files...${RC}"
    printf "%b\n" "${YELLOW}:: Installing cursor themes...${RC}"

    $ESCALATION_TOOL cp -R "$HYPRLAND_DIR/extra/bibata-hyprcursor" /usr/share/icons/ >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up bibata hypr cursor.${RC}"; }
    $ESCALATION_TOOL cp -R "$HYPRLAND_DIR/extra/bibata-xcursor" /usr/share/icons >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up bibata x cursor"; }
    cp -R "$HYPRLAND_DIR/extra/bibata-hyprcursor" "$HOME/.local/share/icons" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up bibata hyprcursor cursor"; }
    cp -R "$HYPRLAND_DIR/extra/bibata-xcursor" "$HOME/.local/share/icons" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up bibata x cursor"; }

    $ESCALATION_TOOL cp -R "$HYPRLAND_DIR/extra/bibata-classic-hyprcursor" /usr/share/icons/ >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up bibata hypr cursor.${RC}"; }
    $ESCALATION_TOOL cp -R "$HYPRLAND_DIR/extra/bibata-classic-xcursor" /usr/share/icons >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up bibata x cursor"; }
    cp -R "$HYPRLAND_DIR/extra/bibata-classic-hyprcursor" "$HOME/.local/share/icons" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up bibata classic hyprcursor cursor"; }
    cp -R "$HYPRLAND_DIR/extra/bibata-classic-xcursor" "$HOME/.local/share/icons" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up bibata classic x cursor"; }

    printf "%b\n" "${YELLOW}:: Cleaning up old configurations...${RC}"
    find "$HOME" -type l -exec rm {} + >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to remove symlinks.${RC}"; }

    printf "%b\n" "${YELLOW}:: Backing up existing configurations...${RC}"
    mv "$XDG_CONFIG_HOME/nvim" "$XDG_CONFIG_HOME/nvim-bak" >/dev/null 2>&1
    mv "$XDG_CONFIG_HOME/gtk-3.0" "$XDG_CONFIG_HOME/gtk-3.0-bak" >/dev/null 2>&1
    mv "$XDG_CONFIG_HOME/fastfetch" "$XDG_CONFIG_HOME/fastfetch-bak" >/dev/null 2>&1
    mv "$XDG_CONFIG_HOME/cava" "$XDG_CONFIG_HOME/cava-bak" >/dev/null 2>&1
    mv "$XDG_CONFIG_HOME/hypr" "$XDG_CONFIG_HOME/hypr-bak" >/dev/null 2>&1
    mv "$XDG_CONFIG_HOME/waybar" "$XDG_CONFIG_HOME/waybar-bak" >/dev/null 2>&1
    mv "$XDG_CONFIG_HOME/kitty" "$XDG_CONFIG_HOME/kitty-bak" >/dev/null 2>&1
    mv "$XDG_CONFIG_HOME/dunst" "$XDG_CONFIG_HOME/dunst-bak" >/dev/null 2>&1
    mv "$HOME/.zshrc" "$HOME/.zshrc-bak" >/dev/null 2>&1
    mv "$HOME/.zprofile" "$HOME/.zprofile-bak" >/dev/null 2>&1

    printf "%b\n" "${YELLOW}:: Setting up SDDM...${RC}"
    $ESCALATION_TOOL mkdir -p /usr/share/sddm/themes >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to create sddm themes directory.${RC}"; }
    $ESCALATION_TOOL cp -R "$HYPRLAND_DIR/extra/sddm/corners" /usr/share/sddm/themes >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up sddm theme.${RC}"; }
    $ESCALATION_TOOL ln -sf "$HYPRLAND_DIR/extra/sddm/sddm.conf" /etc/sddm.conf >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up sddm configuration.${RC}"; }
    $ESCALATION_TOOL systemctl enable sddm >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to enable sddm.${RC}"; }

    printf "%b\n" "${YELLOW}:: Configuring shell environment...${RC}"
    $ESCALATION_TOOL mkdir -p /etc/zsh/ >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to create zsh directory.${RC}"; }
    $ESCALATION_TOOL touch /etc/zsh/zshenv >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to create zshenv.${RC}"; }
    echo "export ZDOTDIR=\"$HOME\"" | $ESCALATION_TOOL tee -a /etc/zsh/zshenv >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set ZDOTDIR.${RC}"; }
    ln -sf "$HYPRLAND_DIR/extra/.zshrc" "$HOME/.zshrc" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up .zshrc.${RC}"; }
    ln -sf "$HYPRLAND_DIR/extra/.zprofile" "$HOME/.zprofile" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up .zprofile.${RC}"; }
    touch "$HOME/.zlogin" "$HOME/.zshenv" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to create zlogin and zshenv.${RC}"; }

    printf "%b\n" "${YELLOW}:: Setting up Spotify theming...${RC}"
    $ESCALATION_TOOL chmod a+wr /opt/spotify
    $ESCALATION_TOOL chmod a+wr /opt/spotify/Apps -R
    curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sed 's/read -r.*/:/' | sh >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to install spicetify.${RC}"; }
    yes | $HOME/.spicetify/spicetify backup apply >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to apply spicetify backup.${RC}"; }
    mkdir -p "$XDG_CONFIG_HOME/spicetify/Themes"
    cp -R "$HYPRLAND_DIR/extra/Sleek" "$XDG_CONFIG_HOME/spicetify/Themes"

    printf "%b\n" "${YELLOW}:: Testing color scheme generation...${RC}"
    /usr/bin/wal -i "$HYPRLAND_DIR/wallpapers/baddie.png" >/dev/null 2>&1

    mkdir -p "$HOME/.local/share/nvim/base46"
    touch "$HOME/.local/share/nvim/base46/statusline"
    touch "$HOME/.local/share/nvim/base46/nvimtree"
    touch "$HOME/.local/share/nvim/base46/defaults"

    printf "%b\n" "${YELLOW}:: Creating configuration symlinks...${RC}"
    $ESCALATION_TOOL ln -sf "$HYPRLAND_DIR/extra/gtk-3.0/dark-horizon" /usr/share/themes/ >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up dark-horizon theme.${RC}"; }
    ln -sf "$HYPRLAND_DIR/extra/cava" "$XDG_CONFIG_HOME/cava" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up cava configuration.${RC}"; }
    ln -sf "$HYPRLAND_DIR/extra/fastfetch" "$XDG_CONFIG_HOME/fastfetch" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up fastfetch configuration.${RC}"; }
    ln -sf "$HYPRLAND_DIR/extra/nvim" "$XDG_CONFIG_HOME/nvim" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up nvim configuration.${RC}"; }
    ln -sf "$HYPRLAND_DIR/extra/gtk-3.0" "$XDG_CONFIG_HOME/gtk-3.0" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up gtk-3.0 configuration.${RC}"; }
    ln -sf "$HYPRLAND_DIR/extra/.xinitrc" "$HOME/.xinitrc" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up .xinitrc.${RC}"; }
    ln -sf "$HYPRLAND_DIR/hypr" "$XDG_CONFIG_HOME/hypr" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up hypr configuration.${RC}"; }
    ln -sf "$HYPRLAND_DIR/extra/kitty" "$XDG_CONFIG_HOME/kitty" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up kitty configuration.${RC}"; }
    ln -sf "$HYPRLAND_DIR/extra/waybar" "$XDG_CONFIG_HOME/waybar" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up waybar configuration.${RC}"; }
    ln -sf "$HYPRLAND_DIR/extra/hyprwall" "$XDG_CONFIG_HOME/hyprwall" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up hyprwall configuration.${RC}"; }
    ln -sf "$HYPRLAND_DIR/extra/dunst" "$XDG_CONFIG_HOME/dunst" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up dunst configuration.${RC}"; }
    ln -sf "$HYPRLAND_DIR/extra/wlogout" "$XDG_CONFIG_HOME/wlogout" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up wlogout configuration.${RC}"; }
    ln -sf "$HYPRLAND_DIR/extra/hyprlauncher" "$XDG_CONFIG_HOME/hyprlauncher" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up hyprlauncher configuration.${RC}"; }

    cp -R "$HYPRLAND_DIR/extra/vesktop/discord-pywal.css" "$XDG_CONFIG_HOME/wal/templates" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up discord-pywal.css.${RC}"; }

    systemctl --user enable pipewire >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up pipewire.${RC}"; }
    systemctl --user enable pipewire-pulse >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up pipewire-pulse.${RC}"; }

    $ESCALATION_TOOL ln -sf /bin/dash /bin/sh >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to create symlink for sh.${RC}"; }
    $ESCALATION_TOOL usermod -s /bin/zsh "$USERNAME" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to change shell.${RC}"; }

    mkdir -p "$HOME/Documents" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to create Documents directory.${RC}"; }
    chmod +x "$HYPRLAND_DIR/extra/debloat.sh" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to make debloat.sh executable.${RC}"; }
    ln -sf "$HYPRLAND_DIR/extra/debloat.sh" "$HOME/Documents/debloat.sh" >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to set up debloat.sh.${RC}"; }

    pywalfox install --browser librewolf >/dev/null 2>&1 || { printf "%b\n" "${RED}:: Failed to setup pywalfox.${RC}"; }

    printf "%b\n" "${GREEN}:: All configurations set up successfully${RC}"
}

setupSDDMPfp() {
    printf "%b\n" "${YELLOW}:: Setting up SDDM profile picture...${RC}"
    $ESCALATION_TOOL mkdir -p /var/lib/AccountsService/icons/
    $ESCALATION_TOOL cp "$HYPRLAND_DIR/pfps/elf.png" "/var/lib/AccountsService/icons/$USERNAME"

    $ESCALATION_TOOL mkdir -p /var/lib/AccountsService/users/
    echo "[User]" | $ESCALATION_TOOL tee "/var/lib/AccountsService/users/$USERNAME" >/dev/null
    echo "Icon=/var/lib/AccountsService/icons/$USERNAME" | $ESCALATION_TOOL tee -a "/var/lib/AccountsService/users/$USERNAME" >/dev/null
    printf "%b\n" "${GREEN}:: SDDM profile picture configured successfully${RC}"
}

success() {
    printf "%b\n" "${YELLOW}:: Please reboot your system to apply the changes.${RC}"
    printf "%b\n" "${GREEN}:: Installation complete.${RC}"
}

warning
setEscalationTool
requestElevation
moveToHome
cloneRepo
declareFuncs
installAURHelper
setSysOps
installDeps
setupConfigurations
setupSDDMPfp
success
