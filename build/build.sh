#!/bin/bash

# Runs every step in build/steps in order, inside the image build
# (Containerfile). Each step is what fedora/install-system.sh did on a live
# system in DoxIA 1, now baked into the image.

set -euo pipefail

for step in /tmp/build/steps/*.sh; do
  echo "==> $(basename "$step" .sh)"
  bash "$step"
done
