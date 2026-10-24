storage="$HOME/storage"
shared="$HOME/shared"

# doxia:heredoc-expands paths=shared,storage -- both sources are validated before use
cat >/etc/doxia/mounts.conf <<EOF
storage=$storage:/storage
shared=$shared:/shared
EOF
