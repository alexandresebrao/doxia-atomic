sudo dd status=none of=/etc/doxia/boot.conf <<EOF
cmdline=$boot_params
EOF
