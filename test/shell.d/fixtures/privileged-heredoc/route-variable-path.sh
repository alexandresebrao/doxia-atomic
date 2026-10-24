DROP_IN=/etc/systemd/system/doxia-agent.service.d/override.conf

cat <<EOF | sudo tee "$DROP_IN" >/dev/null
[Service]
ExecStart=$DOXIA_PATH/bin/doxia-agent
EOF
