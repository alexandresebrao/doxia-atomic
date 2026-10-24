#!/bin/bash

# Google Chrome, the default browser (DoxIA 1: install-chrome --system).
# Chrome installs to /opt, which on an Atomic system is /var/opt: writable,
# but outside the image. Installed into a real /opt here, moved to
# /usr/lib/google and linked back on boot (tmpfiles.d/doxia-chrome.conf).

set -euo pipefail

cat > /etc/yum.repos.d/google-chrome.repo <<'REPO'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
skip_if_unavailable=True
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
enabled=1
REPO
rpm --import https://dl.google.com/linux/linux_signing_key.pub

opt=$(readlink /opt || true)
[[ -n $opt ]] && rm /opt && mkdir /opt
dnf install -y google-chrome-stable
mv /opt/google /usr/lib/google
if [[ -n $opt ]]; then
  rmdir /opt
  ln -s "$opt" /opt
fi
# Straight to the image's copy, so the command works before tmpfiles runs.
ln -sfn /usr/lib/google/chrome/google-chrome /usr/bin/google-chrome-stable
# The package's cron job rewrites the repo file on a running system; the image
# owns it.
rm -f /etc/cron.daily/google-chrome
