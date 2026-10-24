#!/bin/bash

# Builds the DoxIA installer ISO: Fedora's netinstall (Anaconda) rebuilt with lorax
# as "DoxIA", with the generic logos instead of Fedora's, the DoxIA setup wizard
# (wizard/) in front of Anaconda, the DoxIA boot menu theme and doxia.ks embedded.
# Installing needs internet: the system is the DoxIA image, pulled from the
# registry (doxia.ks, ostreecontainer).
#
#   sudo bash iso/build.sh [output dir] [image]
#
# image defaults to ghcr.io/alexandresebrao/doxia-atomic:latest.
# Needs lorax (dnf install lorax lorax-templates-generic) and ~6 GB free.

set -euo pipefail

if (( EUID != 0 )); then
  echo "Run with sudo: sudo bash $0" >&2
  exit 1
fi

iso_dir=$(cd "$(dirname "$0")" && pwd)
doxia_path=$(cd "$iso_dir/../doxia" && pwd)
release=$(rpm -E %fedora)
arch=$(uname -m)
out=$(realpath -m "${1:-$PWD/doxia-iso}")
volid="DoxIA-$release-$arch"
iso="$out/DoxIA-$release-$arch.iso"

image=${2:-ghcr.io/alexandresebrao/doxia-atomic:latest}

mirror=https://dl.fedoraproject.org/pub/fedora/linux
work=$(mktemp -d "${TMPDIR:-/var/tmp}/doxia-iso.XXXXXX")
trap 'rm -rf "$work"' EXIT
mkdir -p "$out"

echo "==> Building the installer image with lorax (Fedora $release, $arch)"
lorax \
  --product DoxIA --version "$release" --release "$release" --isfinal \
  --volid "$volid" \
  --source "$mirror/releases/$release/Everything/$arch/os/" \
  --source "$mirror/updates/$release/Everything/$arch/" \
  --skip-branding --installpkgs generic-logos --installpkgs fedora-release \
  --installpkgs redhat-display-fonts --installpkgs redhat-text-fonts \
  --installpkgs blivet-gui-runtime --installpkgs ntfsprogs \
  --add-template "$iso_dir/doxia-theme.tmpl" \
  --add-template-var "themedir=$iso_dir/anaconda" \
  --add-template-var "wizarddir=$iso_dir/wizard" \
  --add-template-var "brand=$doxia_path/default/login/brand.png" \
  --logfile "$out/lorax.log" --tmp "$work" \
  "$work/lorax"

echo "==> Embedding the kickstart (installs $image) and the boot menu theme"
sed "s#@IMAGE@#$image#" "$iso_dir/doxia.ks" > "$work/doxia.ks"
# The installed system's GRUB theme, at /doxia-grub on the ISO. Both boot menus
# (UEFI and BIOS) load it right after they find the ISO by its label, before the
# entries; with gfxterm, the edit screen and command line need Unifont too.
grub_theme=$work/doxia-grub
install -d "$grub_theme"
install -m644 "$doxia_path"/default/grub/doxia/* /usr/share/grub/unicode.pf2 "$grub_theme/"
theme_setup="set gfxmode=auto
insmod gfxterm
insmod gfxmenu
insmod png
$(for font in "$grub_theme"/*.pf2; do echo "loadfont /doxia-grub/${font##*/}"; done)
terminal_output gfxterm
set theme=/doxia-grub/theme.txt
export theme
"
entries="### BEGIN /etc/grub.d/10_linux ###"
rm -f "$iso"
mkksiso --ks "$work/doxia.ks" --cmdline "inst.profile=doxia" \
  --add "$grub_theme" --replace "$entries" "$theme_setup$entries" \
  "$work/lorax/images/boot.iso" "$iso"

if [[ -n ${SUDO_USER:-} ]]; then
  chown "$SUDO_USER:" "$out" "$iso" "$out/lorax.log"
fi
echo
echo "Done: $iso ($(du -h "$iso" | cut -f1))"
