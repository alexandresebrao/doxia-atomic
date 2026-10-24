#!/bin/bash

# doxia:heredoc-expands paths=none -- review regression fixture
sudo tee /etc/doxia/review.conf >/dev/null <<EOF
ExecStart=${target:-$HOME/.local/bin/payload}
EOF
