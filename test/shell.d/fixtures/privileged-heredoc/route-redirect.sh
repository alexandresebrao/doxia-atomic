# A plain redirect into /etc, no sudo: the command re-execs itself as root.
cat >/etc/doxia/agent.conf <<EOF
helper=$HOME/.local/share/doxia/bin/doxia-agent
EOF
