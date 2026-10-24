# doxia:heredoc-expands paths=none -- the positional argument is a scalar
sudo tee /etc/doxia/example.conf <<EOF
argument=$1
command=$HOME/.local/share/doxia/bin/example
EOF
