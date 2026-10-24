#!/bin/bash

cat <<EOF | \
  sudo tee /etc/doxia/review.conf
ExecStart=$HOME/.local/bin/payload
EOF
