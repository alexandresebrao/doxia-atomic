mask=$((1 << bits))

cat >/etc/doxia/agent.conf <<EOF
helper=$HOME/.local/share/doxia/bin/doxia-agent
EOF
