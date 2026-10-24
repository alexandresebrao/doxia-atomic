#!/bin/bash

# Fedora packages of the DoxIA desktop (DoxIA 1: fedora/install-system.sh).
# base-main already brings flatpak, the codecs and the hardware support.

set -euo pipefail

packages=(
  # Login screen: greetd with doxia-greeter on a bare mango
  greetd greetd-selinux

  # Session and portals. mangowm ships mango-portals.conf, which routes screen
  # sharing and screenshots to the wlr portal.
  xdg-desktop-portal-wlr xdg-desktop-portal-gtk
  # Output layout (monitor panel, captures), virtual pointer (capture-region)
  # and the nightlight
  wlr-randr wlrctl gammastep

  # doxia-shell's layer surfaces (bar, menus, notifications, OSD, lock)
  gtk4-layer-shell

  # Terminal + default apps
  kitty nano nautilus nautilus-python sushi gnome-disk-utility evince-thumbnailer imv mpv mpv-mpris
  # Only Yaru's icons: the yaru-theme metapackage pulls in GNOME Shell, GDM and Mutter.
  # gnome-keyring-pam unlocks the keyring at the login (Chrome's passwords).
  gnome-keyring gnome-keyring-pam yaru-icon-theme
  # Red folders of the DoxIA theme (themes/doxia/make-icons.sh)
  papirus-icon-theme-dark perl-interpreter dbus-daemon
  # JSON::PP for the clipboard history capture and doxia-menu-select/-input
  perl-JSON-PP

  # Wayland/desktop utilities used by doxia-* commands
  brightnessctl pamixer playerctl wireplumber wl-clipboard wtype grim slurp cliphist
  libnotify upower udiskie xdg-user-dirs xdg-terminal-exec
  bluez bluez-tools NetworkManager-tui NetworkManager-wifi wiremix
  pulseaudio-utils tuned tuned-ppd

  # CLI toolbox used by the doxia-* scripts and TUIs
  btop fastfetch gum jq socat inotify-tools fzf util-linux-script eza zoxide ripgrep fd-find bat tmux
  ImageMagick vips-tools ffmpegthumbnailer qrencode zbar tesseract tldr inxi plocate
  python3-gobject tree-sitter-cli nss-mdns git
  # SDKMAN! needs zip and unzip; dev-versions runs on GTK 4 and libadwaita and
  # unpacks rpm JDKs with cpio
  zip unzip gtk4 libadwaita cpio
  # gnome-keyring's password window (lib/keyring-prompter) runs on Gcr 4
  gcr-libs
  # The first-login screen (lib/first-boot) reuses the installer wizard's GTK 3 window
  gtk3
  zsh
  # Builds the DoxIA Shell font (lib/lucide/make-shell-font)
  python3-fonttools
  # FortiVPN bar widget
  openfortivpn

  # Boot splash
  plymouth-theme-spinner

  # Fonts
  google-noto-sans-fonts google-noto-emoji-fonts google-noto-sans-cjk-fonts
  fontawesome-fonts-all jetbrains-mono-fonts redhat-display-fonts redhat-text-fonts
)
dnf install -y --setopt=install_weak_deps=False "${packages[@]}"
