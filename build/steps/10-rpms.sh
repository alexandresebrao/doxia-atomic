#!/bin/bash

# DoxIA's own builds and the upstream RPMs Fedora lacks (build/rpms.lock).

set -euo pipefail

dir=$(mktemp -d)
rpms=()
while read -r url sha256; do
  [[ -z $url || $url == \#* ]] && continue
  file=$dir/${url##*/}
  curl -fsSL --retry 3 -o "$file" "$url"
  if [[ $(sha256sum "$file" | cut -d' ' -f1) != "$sha256" ]]; then
    echo "Checksum mismatch: $url" >&2
    exit 1
  fi
  rpms+=("$file")
done < /tmp/build/rpms.lock

dnf install -y --setopt=install_weak_deps=False "${rpms[@]}"
# Nothing else may replace them: Fedora's wlroots sorts newer than the DoxIA
# build, so a later step pulling it in would undo the vmwgfx fix.
for rpm in "${rpms[@]}"; do
  dnf versionlock add "$(rpm -qp --qf '%{NAME}-%{VERSION}-%{RELEASE}' "$rpm")"
done
rm -rf "$dir"
