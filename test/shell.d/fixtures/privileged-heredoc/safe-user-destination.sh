mkdir -p ~/.config/doxia

cat >~/.config/doxia/agent.conf <<EOF
helper=$HOME/.local/share/doxia/bin/doxia-agent
EOF

cat >"$HOME/.local/bin/doxia-shim" <<EOF
exec "$DOXIA_PATH/bin/doxia-agent" "$@"
EOF
