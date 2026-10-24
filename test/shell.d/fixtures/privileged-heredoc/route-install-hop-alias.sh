tmp=/tmp/doxia-generated
copy=$tmp
cat >"$tmp" <<EOF
command=$HOME/.local/share/doxia/bin/example
EOF
sudo install -m644 "$copy" /etc/doxia/example.conf
