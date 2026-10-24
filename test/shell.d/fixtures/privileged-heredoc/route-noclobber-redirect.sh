# `>|` is a plain redirect with noclobber overridden, not a redirect into a pipe.
cat >|/etc/doxia/agent.conf <<EOF
helper=$HOME/.local/share/doxia/bin/doxia-agent
EOF
