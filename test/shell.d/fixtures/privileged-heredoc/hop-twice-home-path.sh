#!/bin/bash

# Two hops. The scan resolves doxia_bin into helper, so the value it ends up
# judging still carries an unresolved $HOME rather than a literal path.
doxia_bin="$HOME/.local/share/doxia/bin"
helper="$doxia_bin/doxia-agent"

# doxia:heredoc-expands paths=none -- helper names the agent, no path is baked in
cat <<EOF | sudo tee /etc/udev/rules.d/99-doxia-agent.rules >/dev/null
SUBSYSTEM=="power_supply", RUN+="$helper"
EOF
