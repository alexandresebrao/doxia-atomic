tmp=$(mktemp)

cat >"$tmp" <<EOF
#!/bin/bash
exec "$HOME/.local/share/doxia/bin/doxia-agent" "$@"
EOF

sudo install -m 0755 "$tmp" /usr/local/bin/doxia-agent-shim
