#!/bin/bash

# ============================================================
#  A-hyprland - Install Script
# ============================================================

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[+]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[x]${NC} $1"; }

# --- Check: Arch Linux ---
if [ ! -f /etc/arch-release ]; then
    error "This script only works on Arch Linux."
    exit 1
fi

# --- Check: not root ---
if [ "$EUID" -eq 0 ]; then
    error "Do not run this script as root."
    exit 1
fi

# --- Install yay if not present ---
if ! command -v yay &>/dev/null; then
    info "yay not found, installing..."
    sudo pacman -S --needed --noconfirm git base-devel || { error "Failed to install git/base-devel."; exit 1; }
    
    # Fix: Remove /tmp/yay if it exists to prevent git clone error
    rm -rf /tmp/yay
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    (cd /tmp/yay && makepkg -si --noconfirm) || { error "Failed to install yay."; exit 1; }
    rm -rf /tmp/yay
fi

# --- Packages ---
PACKAGES=(
    # Core
    hyprland
    waybar
    kitty
    wofi
    neofetch
    fastfetch
    qt6ct  # Fix: Removed the stray '2'

    # Autostart
    swaync
    network-manager-applet
    blueman
    awww

    # Polkit
    polkit-gnome

    # Media & brightness
    brightnessctl
    playerctl
    pipewire
    pipewire-pulse
    wireplumber

    # Screenshot
    grimblast

    # File manager
    nemo
)

# --- Install packages ---
info "Installing packages..."
FAILED=()
for pkg in "${PACKAGES[@]}"; do
    # Fix: Removed 2>/dev/null so you can see installation errors
    if ! yay -S --needed --noconfirm "$pkg"; then
        warning "Failed to install: $pkg"
        FAILED+=("$pkg")
    fi
done

if [ ${#FAILED[@]} -gt 0 ]; then
    warning "The following packages failed to install: ${FAILED[*]}"
    warning "You may need to install them manually."
fi

# --- Repo root ---
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIGS_DIR="$REPO_DIR/configs"

if [ ! -d "$CONFIGS_DIR" ]; then
    error "Could not find 'configs/' folder."
    exit 1
fi

# --- Copy configs ---
info "Copying configs to ~/.config/..."

for folder in "$CONFIGS_DIR"/*/; do
    name=$(basename "$folder")
    target="$HOME/.config/$name"

    if [ -d "$target" ]; then
        warning "~/.config/$name already exists — backing up to ~/.config/$name.bak"
        # Fix: Remove old backup to prevent moving the folder inside it
        rm -rf "$target.bak"
        mv "$target" "$target.bak"
    fi

    # Improvement: Use cp -a to preserve permissions and symlinks
    cp -a "$folder" "$target"
    info "Copied $name → ~/.config/$name"
done

# --- Copy wallpaper ---
WALLPAPER=$(find "$REPO_DIR" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | head -n 1)

if [ -n "$WALLPAPER" ]; then
    EXT="${WALLPAPER##*.}"
    DEST="$HOME/.config/hypr/wallpaper.$EXT"
    cp "$WALLPAPER" "$DEST"
    info "Wallpaper copied → $DEST"

    # --- Fix wallpaper path in hyprland.conf ---
    HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
    if [ -f "$HYPR_CONF" ]; then
        # Improvement: More robust sed to match any exec-once line containing awww
        sed -i "s|exec-once = .*awww.*|exec-once = sleep 1 \&\& awww img \"$DEST\" --no-cache|" "$HYPR_CONF"
        info "Updated wallpaper path in hyprland.conf"
    fi
    
    # Fix: Moved awww inside the if block, and check if it's installed
    if command -v awww &>/dev/null; then
        awww img "$DEST"
    fi
else
    warning "No wallpaper found in repo root. Skipping."
fi

# --- Done ---
echo ""
echo -e "${GREEN}=============================${NC}"
echo -e "${GREEN}  Done! Configs installed.  ${NC}"
echo -e "${GREEN}=============================${NC}"
echo ""
echo "Next steps:"
echo "  1. Log out and start Hyprland"
echo "  2. Enjoy your setup!"
