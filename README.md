# A-hyprland

My personal Hyprland configuration files.

![screenshot](screenshots/1.png)

---

## Contents

| Config | Description |
|--------|-------------|
| `hypr` | Hyprland window manager config |
| `waybar` | Status bar |
| `kitty` | Terminal emulator |
| `fuzzel` | App launcher |
| `neofetch` | System info display |

---

## Requirements

Make sure **Hyprland** is installed before running the install script.

```bash
sudo pacman -S hyprland
```

---

## Install

```bash
git clone https://github.com/njds82/A-hyprland.git
cd A-hyprland
chmod +x install.sh
./install.sh
```

The script will:
- Install required packages (waybar, kitty, fuzzel, neofetch, swaync, blueman, network-manager-applet, awww, polkit-gnome, brightnessctl, playerctl, pipewire, grimblast, nemo)
- Copy configs to `~/.config/`
- Back up any existing configs automatically
- Copy wallpaper to `~/.config/hypr/wallpaper.png`

---

## Screenshots

![preview](screenshots/1.png)
![preview](screenshots/2.png)
![preview](screenshots/3.png)

---

## Notes

- Built for **Arch Linux**
- No display manager — logs in directly from TTY
- Tested on Hyprland 0.54+
