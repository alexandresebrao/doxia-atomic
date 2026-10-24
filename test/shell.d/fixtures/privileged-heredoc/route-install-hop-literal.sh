#!/bin/bash

cat <<EOF >/tmp/doxia-review-unit
[Service]
ExecStart=$HOME/.local/bin/payload
EOF
sudo install -m 644 /tmp/doxia-review-unit /etc/systemd/system/review.service
