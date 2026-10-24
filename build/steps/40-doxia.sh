#!/bin/bash

# DoxIA itself: the runtime tree is already at /usr/share/doxia and the Rust
# apps in /usr/bin (Containerfile); this puts the rest in place
# (DoxIA 1: fedora/install-system.sh).

set -euo pipefail

doxia=/usr/share/doxia
fedora=$(rpm -E %fedora)

# Every doxia-* command on the PATH. The Rust apps (doxia-shell, doxia-greeter,
# doxia-painel...) are real binaries there already and win.
for cmd in "$doxia"/bin/doxia-*; do
  [[ -e /usr/bin/${cmd##*/} ]] || ln -s "$cmd" "/usr/bin/${cmd##*/}"
done
# The browser policy helper runs as root through sudoers: a root-owned copy,
# not a link into the tree.
install -m755 "$doxia/bin/doxia-theme-set-browser-policy" /usr/bin/doxia-theme-set-browser-policy
install -m440 "$doxia/etc/sudoers.d/doxia-theme-browser" /etc/sudoers.d/doxia-theme-browser
visudo -cqf /etc/sudoers.d/doxia-theme-browser

echo "  system identity (boot menu, About, fastfetch)"
# ostree titles the boot entries with PRETTY_NAME: DoxIA instead of Fedora Linux.
# ID stays fedora so tools that check it (toolbox, dnf in containers) still work.
sed -i -e "s|^NAME=.*|NAME=\"DoxIA\"|" \
  -e "s|^PRETTY_NAME=.*|PRETTY_NAME=\"DoxIA 2 (Fedora $fedora)\"|" \
  -e "s|^VARIANT=.*|VARIANT=\"DoxIA\"|" \
  -e "s|^VARIANT_ID=.*|VARIANT_ID=doxia|" \
  -e "s|^HOME_URL=.*|HOME_URL=\"https://github.com/alexandresebrao/doxia-atomic\"|" \
  /usr/lib/os-release
grep -q '^VARIANT_ID=' /usr/lib/os-release || echo 'VARIANT_ID=doxia' >> /usr/lib/os-release
grep -q '^VARIANT=' /usr/lib/os-release || echo 'VARIANT="DoxIA"' >> /usr/lib/os-release

# The DoxIA brand as an image in terminals that draw images.
install -d /usr/libexec/doxia
mv /usr/bin/fastfetch /usr/libexec/doxia/fastfetch
ln -s "$doxia/lib/fastfetch-brand" /usr/bin/fastfetch
install -d /etc/fastfetch
ln -sfn "$doxia/lib/fastfetch/config.jsonc" /etc/fastfetch/config.jsonc
{ echo; sed 's/^/  /' "$doxia/lib/brand.ansi"; echo; sed "s/@FEDORA@/$fedora/" "$doxia/lib/motd"; } > /etc/motd

echo "  session, terminal and default apps"
install -Dm644 "$doxia/default/wayland-sessions/doxia.desktop" /usr/share/wayland-sessions/doxia.desktop
install -Dm644 "$doxia/etc/xdg/kitty/kitty.conf" /etc/xdg/kitty/kitty.conf
# xdg-terminal-exec picks the list by desktop name (DesktopNames=mango);
# ~/.config/xdg-terminals.list (doxia-default-terminal) still wins.
install -Dm644 "$doxia/default/xdg-terminal-exec/mango-xdg-terminals.list" \
  /usr/share/xdg-terminal-exec/mango-xdg-terminals.list
# DoxMail for mailto: and .eml; ~/.config/mimeapps.list still wins.
install -Dm644 "$doxia/lib/mimeapps.list" /etc/xdg/mimeapps.list
# zsh for every new account (lib/install-zsh does the rest on the first login).
sed -i 's|^SHELL=.*|SHELL=/usr/bin/zsh|' /etc/default/useradd

echo "  login screen (greetd with doxia-greeter on mango)"
install -Dm644 "$doxia/default/greetd/config.toml" /etc/greetd/config.toml
install -Dm755 "$doxia/default/greetd/doxia-greeter-session" /usr/libexec/doxia-greeter-session
install -d "$doxia/greeter"
install -m644 "$doxia"/default/greetd/mango.conf "$doxia"/default/greetd/mango-hyperv.conf \
  "$doxia"/default/login/brand.png "$doxia"/default/login/power.png "$doxia/greeter/"

echo "  lock screen PAM"
cat > /etc/pam.d/doxia-lock-password <<'PAM'
auth       required                    pam_faillock.so preauth silent deny=10 unlock_time=120
-auth      [success=2 default=ignore]  pam_systemd_home.so
auth       [success=1 default=bad]     pam_unix.so try_first_pass nullok
auth       [default=die]               pam_faillock.so authfail deny=10 unlock_time=120
auth       optional                    pam_permit.so
auth       required                    pam_env.so
auth       required                    pam_faillock.so authsucc
account    include                     system-auth
PAM
# The fingerprint variant comes from doxia-setup-security-fingerprint, once a
# finger is enrolled.

echo "  Nautilus action icons for Yaru"
install -d /usr/share/icons/Yaru/scalable/actions
for icon in go-previous-symbolic go-next-symbolic; do
  ln -snf "/usr/share/icons/Adwaita/symbolic/actions/$icon.svg" \
    "/usr/share/icons/Yaru/scalable/actions/$icon.svg"
done
gtk-update-icon-cache /usr/share/icons/Yaru &>/dev/null || true

echo "  boot splash (Fedora's spinner with the DoxIA watermark)"
theme=/usr/share/plymouth/themes/doxia
install -d "$theme"
cp /usr/share/plymouth/themes/spinner/*.png "$theme/"
install -m644 "$doxia"/default/plymouth/doxia/{doxia.plymouth,watermark.png} "$theme/"
plymouth-set-default-theme doxia
kver=$(ls /usr/lib/modules | head -1)
# ostree only joins when asked: without it the initramfs never sets up the
# deployment as / and the boot ends in emergency mode.
dracut --no-hostonly --kver "$kver" --reproducible --zstd --add ostree -f "/usr/lib/modules/$kver/initramfs.img"
