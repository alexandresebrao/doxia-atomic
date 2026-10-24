# DoxIA installer kickstart (build.sh fills in @IMAGE@ and embeds it in the ISO).
#
# The DoxIA wizard (wizard/doxia-installer.py) runs from %pre and asks for the
# language, keyboard, disk, account and computer name; it writes them to
# /tmp/doxia/answers.ks, included below. Anaconda then installs without its own
# interface (cmdline) while the wizard shows the progress. The system is the
# DoxIA image itself (ostreecontainer): the installed machine follows it with
# bootc upgrade. The %post sets up the account the wizard created.

cmdline
# Without it, cmdline mode ends at "Press ENTER to quit" on tty1 and never reboots.
# The last %post holds Anaconda until the wizard's Restart button is clicked.
reboot --eject

%pre --erroronfail --log=/tmp/doxia-pre.log
/usr/libexec/doxia-installer/doxia-installer-start
%end

%include /tmp/doxia/answers.ks

# The image is pulled from the registry while installing; the installed
# system tracks the same reference (bootc upgrade, the Atualizar window).
ostreecontainer --url=@IMAGE@ --transport=registry --no-signature-verification

%post --log=/var/log/doxia-install.log
set -euo pipefail

user=$(awk -F: '$3 >= 1000 && $3 < 60000 { print $1; exit }' /etc/passwd)
if [[ -z $user ]]; then
  echo "DoxIA: no user account was created in the installer; the first login sets it up."
  exit 0
fi

# The login screen starts on this account and the DoxIA session.
state=/var/lib/greetd/doxia-greeter.state
install -d -o greetd -g greetd /var/lib/greetd
printf 'user=%s\nsession=%s\n' "$user" /usr/share/wayland-sessions/doxia.desktop > "$state"
chown greetd:greetd "$state"
restorecon -R /var/lib/greetd 2>/dev/null || true

# What doxia-setup-user.service would do on the first login, done here so the
# first login goes straight to the desktop.
echo "==> Setting up $user (theme, fonts, shell, apps)"
runuser -l "$user" -c 'dbus-run-session -- /usr/share/doxia/lib/setup-user' ||
  echo "  The setup did not finish; the first login runs it again."
%end

# Last: tell the wizard the installation is done, then hold Anaconda (which reboots
# as soon as it finishes, see reboot above) until the Restart button is clicked.
%post --nochroot
# Keep the network joined in the wizard (Wi-Fi password included) on the installed system
target=$ANA_INSTALL_PATH/etc/NetworkManager/system-connections
mkdir -p "$target"
for connection in /etc/NetworkManager/system-connections/*.nmconnection; do
  [[ -e $connection ]] || continue
  cp -n "$connection" "$target/"
  chmod 600 "$target/$(basename "$connection")"
done

touch /tmp/doxia/installed
while [[ ! -e /tmp/doxia/reboot ]]; do
  sleep 1
done
%end
