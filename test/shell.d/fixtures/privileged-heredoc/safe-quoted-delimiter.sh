cat <<'EOF' | sudo tee /etc/udev/rules.d/99-doxia.rules >/dev/null
SUBSYSTEM=="power_supply", RUN+="/usr/bin/doxia-powerprofiles-set $HOME"
EOF

cat <<"XML" | sudo tee /etc/doxia/agent.xml >/dev/null
<config path="$HOME/.local/share/doxia" />
XML
