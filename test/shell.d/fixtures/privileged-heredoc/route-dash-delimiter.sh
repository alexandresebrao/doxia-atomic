if true; then
  cat <<-EOF | sudo tee /etc/doxia/indented.conf >/dev/null
	helper=$HOME/.local/share/doxia/bin/doxia-agent
	EOF
fi
