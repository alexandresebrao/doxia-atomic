cat <<EOF | sudo tee /etc/udev/rules.d/99-doxia.rules >/dev/null
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="/usr/bin/doxia-powerprofiles-set"
EOF
