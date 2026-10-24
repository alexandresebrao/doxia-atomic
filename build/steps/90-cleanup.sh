#!/bin/bash

# What the image must not carry: package caches and build leftovers. /var
# only gets what bootc's first boot seeds, so nothing may be left there.

set -euo pipefail

dnf clean all
rm -rf /var/log/dnf5.log* /var/lib/dnf
