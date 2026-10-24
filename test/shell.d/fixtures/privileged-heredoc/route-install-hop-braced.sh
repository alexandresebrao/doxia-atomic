tmp=/tmp/doxia-generated
cat >"$tmp" <<EOF
command=$HOME/.local/share/doxia/bin/example
EOF
sudo install -m644 "${tmp}" /etc/doxia/example.conf
