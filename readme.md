<p align="center">
  <img src=".github/header.svg" alt="Header">
</p>

### Usage:
Install via curl
  ```shell
  curl -fsSL https://github.com/nnyyxxxx/hyprland/raw/main/install.sh | sh
  ```

Install via git
  ```shell
  git clone https://github.com/nnyyxxxx/hyprland
  cd hyprland
  chmod +x install.sh
  ./install.sh
  ```
Updating
```shell
# This might not be the best idea, dependencies could get added to the install script and new utilities could get added in the future, I'd advice against this unless you have local changes.
cd "$HOME/hyprland"
git pull
```
### Modifying:
Modifying these dotfiles is not recommended. You will end up breaking something. If you still intend to modify these dots then please take a look at the scripts/wallpaper.sh script. Any modifications could stop the theme patcher from working.

### Keybinds overview:
| Keybind | Description |  
| --- | --- |  
| `ALT SHIFT + Q` | Spawns kitty (Terminal) |  
| `ALT SHIFT + E` | Spawns rofi (Application launcher) |
| `ALT SHIFT + C` | Kills current window |
| `ALT SHIFT + W` | Kills hyprland |
| `ALT SHIFT + F` | Toggles fullscreen |
| `ALT SHIFT + V` | Spawns hyprpicker (Color picker) |
| `ALT SHIFT + B` | Reloads waybar / Spawns waybar |
| `ALT SHIFT + A` | Locks the screen |
| `ALT SHIFT + R` | Randomizes wallpaper |
| `ALT SHIFT + S` | Spawns wlogout (Power menu)
| `ALT + ESC` | Spawns grim (Screenshot utility) |
| `ALT + LMB` | Drags selected window |
| `ALT + RMB` | Resizes window in floating & resizes mfact in tiled |
| `ALT + SPACE` | Makes the selected window float |

### Preview:
![](.github/preview.png)
