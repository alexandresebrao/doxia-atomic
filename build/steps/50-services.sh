#!/bin/bash

# System services and the user units every account gets
# (DoxIA 1: install-system.sh and lib/install-user-units).

set -euo pipefail

doxia=/usr/share/doxia
units=/usr/lib/systemd/user

systemctl enable greetd.service tuned.service tuned-ppd.service doxia-flatpak-apps.service
systemctl set-default graphical.target

# Only in the DoxIA session, never in another desktop someone layers on.
for unit in bt-agent doxia-crash-watch doxia-sleep-lock; do
  sed '/^\[Unit\]/a ConditionEnvironment=XDG_CURRENT_DESKTOP=mango:wlroots' \
    "$doxia/default/systemd/user/$unit.service" > "$units/$unit.service"
done
install -m644 "$doxia/default/systemd/user/doxia-recover-internal-monitor.service" "$units/"
# doxia-sleep-lock is started by mango's autostart, not by the target.
sed -i '/^\[Install\]/,$d' "$units/doxia-sleep-lock.service"

systemctl --global enable bt-agent.service doxia-crash-watch.service \
  doxia-recover-internal-monitor.service doxia-shell.service doxia-setup-user.service \
  doxia-setup-retry.service
