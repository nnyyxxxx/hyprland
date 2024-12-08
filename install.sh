#!/bin/sh

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

warning() {
    if ! command -v pacman >/dev/null 2>&1; then
        printf "%b\n" "${RED}::${RC} Automated installation is only available for Arch-based distributions, install manually."
        exit 1
    fi
}

set_escalation_tool() {
    if command -v sudo >/dev/null 2>&1; then
        ESCALATION_TOOL="sudo"
    elif command -v doas >/dev/null 2>&1; then
        ESCALATION_TOOL="doas"
    fi
}

request_elevation() {
    if [ "$ESCALATION_TOOL" = "sudo" ]; then
        { sudo -v && clear; } || { printf "%b\n" "${RED}::${RC} Failed to gain elevation."; }
    elif [ "$ESCALATION_TOOL" = "doas" ]; then
        { doas true && clear; } || { printf "%b\n" "${RED}::${RC} Failed to gain elevation."; }
    fi
}

move_to_home() {
    cd "$HOME" || {
        printf "%b\n" "${RED}::${RC} Failed to move to home directory."
        exit 1
    }
}

clone_repo() {
    printf "%b\n" "${YELLOW}::${RC} Installing git..."
    $ESCALATION_TOOL pacman -S --needed --noconfirm git base-devel >/dev/null 2>&1 || {
        printf "%b\n" "${RED}::${RC} Failed to install git."
        exit 1
    }

    printf "%b\n" "${YELLOW}::${RC} Checking repository..."
    if [ -d "$HOME/hyprland" ] && [ -d "$HOME/hyprland/.git" ]; then
        cd "$HOME/hyprland" || exit 1
        if git remote get-url origin | grep -q "github.com/nnyyxxxx/dotfiles"; then
            printf "%b\n" "${YELLOW}::${RC} Repository exists, pulling latest changes..."
            git pull origin main >/dev/null 2>&1 || {
                printf "%b\n" "${RED}::${RC} Failed to pull latest changes."
                exit 1
            }
            printf "%b\n" "${GREEN}::${RC} Repository updated successfully"
            return 0
        fi
    fi

    printf "%b\n" "${YELLOW}::${RC} Cloning repository..."
    rm -rf "$HOME/hyprland" >/dev/null 2>&1 || {
        printf "%b\n" "${RED}::${RC} Failed to remove old hyprland directory."
        exit 1
    }
    git clone https://github.com/nnyyxxxx/dotfiles "$HOME/hyprland" >/dev/null 2>&1 || {
        printf "%b\n" "${RED}::${RC} Failed to clone dotfiles."
        exit 1
    }
}

declare_funcs() {
    printf "%b\n" "${YELLOW}::${RC} Setting up directories..."
    HYPRLAND_DIR="$HOME/hyprland"
    mkdir -p "$HOME/.config"
    XDG_CONFIG_HOME="$HOME/.config"
    USERNAME=$(whoami)
}

install_aur_helper() {
    printf "%b\n" "${YELLOW}::${RC} Checking for AUR helper..."

    if command -v yay >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}::${RC} Removing yay..."
        $ESCALATION_TOOL pacman -Rns --noconfirm yay >/dev/null 2>&1 || {
            printf "%b\n" "${RED}::${RC} Failed to remove yay."
            exit 1
        }
    fi

    if ! command -v paru >/dev/null 2>&1; then
        printf "%b\n" "${YELLOW}::${RC} Installing paru AUR helper..."
        $ESCALATION_TOOL pacman -S --needed --noconfirm base-devel >/dev/null 2>&1 || {
            printf "%b\n" "${RED}::${RC} Failed to install build dependencies."
            exit 1
        }
        git clone https://aur.archlinux.org/paru-bin.git "$HOME/paru-bin" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to clone paru."; }
        cd "$HOME/paru-bin"
        printf "%b\n" "${YELLOW}::${RC} Building paru..."
        makepkg -si --noconfirm >/dev/null 2>&1
        cd "$HOME"
        rm -rf "$HOME/paru-bin"
        printf "%b\n" "${GREEN}::${RC} Paru installed successfully"
    fi

    printf "%b\n" "${GREEN}::${RC} Using paru as AUR helper"
    AUR_HELPER="paru"
}

set_sys_ops() {
    printf "%b\n" "${YELLOW}::${RC} Configuring system settings..."
    printf "%b\n" "${YELLOW}::${RC} Setting up Parallel Downloads..."
    $ESCALATION_TOOL sed -i 's/^#ParallelDownloads = 5$/ParallelDownloads = 5/' /etc/pacman.conf >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set Parallel Downloads."; }

    printf "%b\n" "${YELLOW}::${RC} Setting up default cursor..."
    $ESCALATION_TOOL mkdir -p /usr/share/icons/default
    $ESCALATION_TOOL touch /usr/share/icons/default/index.theme
    $ESCALATION_TOOL sed -i 's/^Inherits=Adwaita$/Inherits=bibata-classic-xcursor/' /usr/share/icons/default/index.theme >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set bibata cursor."; }
    printf "%b\n" "${GREEN}::${RC} System settings configured successfully"
}

enable_multilib() {
    printf "%b\n" "${YELLOW}::${RC} Enabling multilib repository..."

    $ESCALATION_TOOL sed -i '/^#\[multilib\]/{N;s/#\[multilib\]\n#Include/\[multilib\]\nInclude/}' /etc/pacman.conf || {
        printf "%b\n" "${RED}::${RC} Failed to uncomment multilib repository."
        exit 1
    }

    $ESCALATION_TOOL pacman -Sy >/dev/null 2>&1 || {
        printf "%b\n" "${RED}::${RC} Failed to update package database after enabling multilib."
        exit 1
    }

    printf "%b\n" "${GREEN}::${RC} Multilib repository enabled successfully"
}

install_deps() {
    printf "%b\n" "${YELLOW}::${RC} Installing dependencies..."
    printf "%b\n" "${YELLOW}::${RC} This might take a minute or two..."
    total_steps=3
    current_step=1

    $AUR_HELPER -S --needed --noconfirm \
        cava pipes.sh checkupdates-with-aur librewolf-bin hyprwall-bin wlogout \
        python-pywalfox-librewolf spotify vesktop-bin hyprlauncher-bin hyprpolkitagent-git \
        protonup-qt-bin >/dev/null 2>&1 &&
        printf "%b\n" "${GREEN}::${RC} AUR dependencies installed (${current_step}/${total_steps})" || {
        printf "%b\n" "${RED}::${RC} Failed to install AUR packages."
        exit 1
    }
    current_step=$((current_step + 1))

    $ESCALATION_TOOL pacman -Rns --noconfirm \
        lightdm gdm lxdm lemurs emptty xorg-xdm ly hyprland-git >/dev/null 2>&1 &&
        printf "%b\n" "${GREEN}::${RC} Conflicting dependencies uninstalled. (${current_step}/${total_steps})" || {
        printf "%b\n" "${RED}::${RC} Failed to remove conflicting packages. Check /var/log/pacman.log for details."
        exit 1
    }
    current_step=$((current_step + 1))

    $ESCALATION_TOOL pacman -Syyu --needed --noconfirm \
        cliphist waybar grim slurp hyprpicker hyprpaper bleachbit hyprland fastfetch cpio \
        pipewire ttf-jetbrains-mono-nerd noto-fonts-emoji ttf-liberation ttf-dejavu meson \
        ttf-fira-sans ttf-fira-mono xdg-desktop-portal zip unzip cmake \
        qt5-graphicaleffects qt5-quickcontrols2 noto-fonts-extra noto-fonts-cjk noto-fonts \
        cmatrix gtk3 neovim pamixer mpv feh zsh dash pipewire-pulse easyeffects \
        btop zoxide zsh-syntax-highlighting ffmpeg xdg-desktop-portal-hyprland qt5-wayland \
        hypridle hyprlock qt6-wayland lsd libnotify dunst bat sddm jq python-pywal python-watchdog \
        python xorg-xhost timeshift yazi inotify-tools checkbashisms shfmt fzf alacritty qt5ct qt5 \
        tar gzip bzip2 unrar p7zip unzip ncompress qt6 gnutls lib32-gnutls base-devel gtk2 \
        lib32-gtk2 lib32-gtk3 libpulse lib32-libpulse alsa-lib lib32-alsa-lib gtk4 \
        alsa-utils alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib giflib lib32-giflib \
        libpng lib32-libpng lib32-libxcomposite libxinerama lib32-libxinerama \
        libldap lib32-libldap openal lib32-openal libxcomposite ocl-icd lib32-ocl-icd libva lib32-libva \
        ncurses lib32-ncurses vulkan-icd-loader lib32-vulkan-icd-loader ocl-icd lib32-ocl-icd libva lib32-libva \
        gst-plugins-base-libs lib32-gst-plugins-base-libs sdl2 lib32-sdl2 v4l-utils lib32-v4l-utils sqlite bubblewrap \
        lib32-sqlite vulkan-radeon lib32-vulkan-radeon lib32-mangohud mangohud pavucontrol qt6ct >/dev/null 2>&1 &&
        printf "%b\n" "${GREEN}::${RC} Dependencies installed (${current_step}/${total_steps})" || {
        printf "%b\n" "${RED}::${RC} Failed to install system packages. Check /var/log/pacman.log for details."
        exit 1
    }
}

setup_configurations() {
    printf "%b\n" "${YELLOW}::${RC} Setting up configuration files..."
    printf "%b\n" "${YELLOW}::${RC} Installing cursor themes..."

    $ESCALATION_TOOL cp -R "$HYPRLAND_DIR/extra/bibata-hyprcursor" /usr/share/icons/ >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up bibata hypr cursor."; }
    $ESCALATION_TOOL cp -R "$HYPRLAND_DIR/extra/bibata-xcursor" /usr/share/icons >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up bibata x cursor"; }
    cp -R "$HYPRLAND_DIR/extra/bibata-hyprcursor" "$HOME/.local/share/icons" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up bibata hyprcursor cursor"; }
    cp -R "$HYPRLAND_DIR/extra/bibata-xcursor" "$HOME/.local/share/icons" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up bibata x cursor"; }

    $ESCALATION_TOOL cp -R "$HYPRLAND_DIR/extra/bibata-classic-hyprcursor" /usr/share/icons/ >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up bibata hypr cursor."; }
    $ESCALATION_TOOL cp -R "$HYPRLAND_DIR/extra/bibata-classic-xcursor" /usr/share/icons >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up bibata x cursor"; }
    cp -R "$HYPRLAND_DIR/extra/bibata-classic-hyprcursor" "$HOME/.local/share/icons" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up bibata classic hyprcursor cursor"; }
    cp -R "$HYPRLAND_DIR/extra/bibata-classic-xcursor" "$HOME/.local/share/icons" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up bibata classic x cursor"; }

    printf "%b\n" "${YELLOW}::${RC} Cleaning up old configurations..."
    find "$HOME" -type l -exec rm {} + >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to remove symlinks."; }

    printf "%b\n" "${YELLOW}::${RC} Backing up existing configurations..."
    mv "$XDG_CONFIG_HOME/nvim" "$XDG_CONFIG_HOME/nvim-bak" >/dev/null 2>&1
    mv "$XDG_CONFIG_HOME/gtk-3.0" "$XDG_CONFIG_HOME/gtk-3.0-bak" >/dev/null 2>&1
    mv "$XDG_CONFIG_HOME/fastfetch" "$XDG_CONFIG_HOME/fastfetch-bak" >/dev/null 2>&1
    mv "$XDG_CONFIG_HOME/cava" "$XDG_CONFIG_HOME/cava-bak" >/dev/null 2>&1
    mv "$XDG_CONFIG_HOME/hypr" "$XDG_CONFIG_HOME/hypr-bak" >/dev/null 2>&1
    mv "$XDG_CONFIG_HOME/waybar" "$XDG_CONFIG_HOME/waybar-bak" >/dev/null 2>&1
    mv "$XDG_CONFIG_HOME/alacritty" "$XDG_CONFIG_HOME/alacritty-bak" >/dev/null 2>&1
    mv "$XDG_CONFIG_HOME/dunst" "$XDG_CONFIG_HOME/dunst-bak" >/dev/null 2>&1
    mv "$XDG_CONFIG_HOME/qt5ct" "$XDG_CONFIG_HOME/qt5ct-bak" >/dev/null 2>&1
    mv "$XDG_CONFIG_HOME/hypr" "$XDG_CONFIG_HOME/hypr-bak" >/dev/null 2>&1
    mv "$HOME/.zshrc" "$HOME/.zshrc-bak" >/dev/null 2>&1
    mv "$HOME/.zprofile" "$HOME/.zprofile-bak" >/dev/null 2>&1

    printf "%b\n" "${YELLOW}::${RC} Setting up SDDM..."
    $ESCALATION_TOOL mkdir -p /usr/share/sddm/themes >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to create sddm themes directory."; }
    $ESCALATION_TOOL cp -R "$HYPRLAND_DIR/extra/sddm/corners" /usr/share/sddm/themes >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up sddm theme."; }
    $ESCALATION_TOOL ln -sf "$HYPRLAND_DIR/extra/sddm/sddm.conf" /etc/sddm.conf >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up sddm configuration."; }
    $ESCALATION_TOOL systemctl enable sddm >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to enable sddm."; }

    printf "%b\n" "${YELLOW}::${RC} Configuring shell environment..."
    $ESCALATION_TOOL mkdir -p /etc/zsh/ >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to create zsh directory."; }
    $ESCALATION_TOOL touch /etc/zsh/zshenv >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to create zshenv."; }
    echo "export ZDOTDIR=\"$HOME\"" | $ESCALATION_TOOL tee -a /etc/zsh/zshenv >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set ZDOTDIR."; }
    ln -sf "$HYPRLAND_DIR/extra/zsh/.zshrc" "$HOME/.zshrc" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up .zshrc."; }
    ln -sf "$HYPRLAND_DIR/extra/zsh/.zprofile" "$HOME/.zprofile" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up .zprofile."; }
    touch "$HOME/.zlogin" "$HOME/.zshenv" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to create zlogin and zshenv."; }

    printf "%b\n" "${YELLOW}::${RC} Setting up Spotify theming..."
    $ESCALATION_TOOL chmod a+wr /opt/spotify
    $ESCALATION_TOOL chmod a+wr /opt/spotify/Apps -R
    curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sed 's/read -r.*/:/' | sh >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to install spicetify."; }
    yes | $HOME/.spicetify/spicetify backup apply >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to apply spicetify backup."; }
    mkdir -p "$XDG_CONFIG_HOME/spicetify/Themes"
    cp -R "$HYPRLAND_DIR/extra/Sleek" "$XDG_CONFIG_HOME/spicetify/Themes"

    printf "%b\n" "${YELLOW}::${RC} Testing color scheme generation..."
    /usr/bin/wal -i "$HYPRLAND_DIR/wallpapers/baddie.png" >/dev/null 2>&1

    mkdir -p "$HOME/.local/share/nvim/base46"
    touch "$HOME/.local/share/nvim/base46/statusline"
    touch "$HOME/.local/share/nvim/base46/nvimtree"
    touch "$HOME/.local/share/nvim/base46/defaults"

    printf "%b\n" "${YELLOW}::${RC} Creating configuration symlinks..."
    $ESCALATION_TOOL ln -sf "$HYPRLAND_DIR/extra/gtk-3.0/dark-horizon" /usr/share/themes/ >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up dark-horizon theme."; }
    ln -sf "$HYPRLAND_DIR/extra/cava" "$XDG_CONFIG_HOME/cava" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up cava configuration."; }
    ln -sf "$HYPRLAND_DIR/extra/fastfetch" "$XDG_CONFIG_HOME/fastfetch" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up fastfetch configuration."; }
    ln -sf "$HYPRLAND_DIR/extra/nvim" "$XDG_CONFIG_HOME/nvim" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up nvim configuration."; }
    ln -sf "$HYPRLAND_DIR/extra/gtk-3.0" "$XDG_CONFIG_HOME/gtk-3.0" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up gtk-3.0 configuration."; }
    ln -sf "$HYPRLAND_DIR/hypr" "$XDG_CONFIG_HOME/hypr" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up hypr configuration."; }
    ln -sf "$HYPRLAND_DIR/extra/waybar" "$XDG_CONFIG_HOME/waybar" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up waybar configuration."; }
    ln -sf "$HYPRLAND_DIR/extra/hyprwall" "$XDG_CONFIG_HOME/hyprwall" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up hyprwall configuration."; }
    ln -sf "$HYPRLAND_DIR/extra/dunst" "$XDG_CONFIG_HOME/dunst" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up dunst configuration."; }
    ln -sf "$HYPRLAND_DIR/extra/wlogout" "$XDG_CONFIG_HOME/wlogout" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up wlogout configuration."; }
    ln -sf "$HYPRLAND_DIR/extra/hyprlauncher" "$XDG_CONFIG_HOME/hyprlauncher" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up hyprlauncher configuration."; }
    ln -sf "$HYPRLAND_DIR/extra/alacritty" "$XDG_CONFIG_HOME/alacritty" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up alacritty configuration."; }
    ln -sf "$HYPRLAND_DIR/extra/qt5ct" "$XDG_CONFIG_HOME/qt5ct" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up qt5ct configuration."; }
    ln -sf "$HYPRLAND_DIR/extra/qt6ct" "$XDG_CONFIG_HOME/qt6ct" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up qt6ct configuration."; }
    cp -R "$HYPRLAND_DIR/extra/templates/discord-pywal.css" "$XDG_CONFIG_HOME/wal/templates" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up discord-pywal.css."; }
    cp -R "$HYPRLAND_DIR/extra/templates/alacritty.toml" "$XDG_CONFIG_HOME/wal/templates" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up alacritty.toml."; }

    systemctl --user enable pipewire >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up pipewire."; }
    systemctl --user enable pipewire-pulse >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up pipewire-pulse."; }
    systemctl --user enable hyprpolkitagent >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to set up hyprpolkitagent."; }
    systemctl --user start hyprpolkitagent >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to start hyprpolkitagent."; }

    $ESCALATION_TOOL ln -sf /bin/dash /bin/sh >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to create symlink for sh."; }
    $ESCALATION_TOOL usermod -s /bin/zsh "$USERNAME" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to change shell."; }

    mkdir -p "$HOME/Documents" >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to create Documents directory."; }

    pywalfox install --browser librewolf >/dev/null 2>&1 || { printf "%b\n" "${RED}::${RC} Failed to setup pywalfox."; }

    printf "%b\n" "${GREEN}::${RC} All configurations set up successfully"
}

setup_sddm_pfp() {
    printf "%b\n" "${YELLOW}::${RC} Setting up SDDM profile picture..."
    $ESCALATION_TOOL mkdir -p /var/lib/AccountsService/icons/
    $ESCALATION_TOOL cp "$HYPRLAND_DIR/pfps/angel.png" "/var/lib/AccountsService/icons/$USERNAME"

    $ESCALATION_TOOL mkdir -p /var/lib/AccountsService/users/
    echo "[User]" | $ESCALATION_TOOL tee "/var/lib/AccountsService/users/$USERNAME" >/dev/null
    echo "Icon=/var/lib/AccountsService/icons/$USERNAME" | $ESCALATION_TOOL tee -a "/var/lib/AccountsService/users/$USERNAME" >/dev/null
    printf "%b\n" "${GREEN}::${RC} SDDM profile picture configured successfully"
}

success() {
    printf "%b\n" "${YELLOW}::${RC} Please reboot your system to apply the changes."
    printf "%b\n" "${GREEN}::${RC} Installation complete."
}

warning
set_escalation_tool
request_elevation
move_to_home
clone_repo
declare_funcs
install_aur_helper
set_sys_ops
enable_multilib
install_deps
setup_configurations
setup_sddm_pfp
success
