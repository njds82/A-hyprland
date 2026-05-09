#!/bin/bash

# ============================================================
#  A-hyprland - Install Script
#  Installs required packages and copies configs to ~/.config
# ============================================================

set -e

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[+]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[x]${NC} $1"; exit 1; }

# --- Check: Arch Linux ---
if [ ! -f /etc/arch-release ]; then
    error "This script only works on Arch Linux."
fi

# --- Check: not root ---
if [ "$EUID" -eq 0 ]; then
    error "Do not run this script as root."
fi

# --- Packages ---
PACKAGES=(
    # Core
    hyprland
    waybar
    kitty
    fuzzel
    neofetch

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
sudo pacman -S --needed --noconfirm "${PACKAGES[@]}" || error "Failed to install packages."

# --- Repo root ---
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIGS_DIR="$REPO_DIR/configs"

if [ ! -d "$CONFIGS_DIR" ]; then
    error "Could not find 'configs/' folder. Make sure you run this script from the repo root."
fi

# --- Copy configs ---
info "Copying configs to ~/.config/..."

for folder in "$CONFIGS_DIR"/*/; do
    name=$(basename "$folder")
    target="$HOME/.config/$name"

    if [ -d "$target" ]; then
        warning "~/.config/$name already exists — backing up to ~/.config/$name.bak"
        mv "$target" "$target.bak"
    fi

    cp -r "$folder" "$target"
    info "Copied $name → ~/.config/$name"
done

# --- Copy wallpaper ---
WALLPAPER=$(find "$REPO_DIR" -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | head -n 1)

if [ -n "$WALLPAPER" ]; then
    EXT="${WALLPAPER##*.}"
    info "Copying wallpaper to ~/.config/hypr/wallpaper.$EXT..."
    cp "$WALLPAPER" "$HOME/.config/hypr/wallpaper.$EXT"
    info "Wallpaper copied → ~/.config/hypr/wallpaper.$EXT"
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
