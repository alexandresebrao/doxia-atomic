# DoxIA 2: build and try the image locally.

image := "localhost/doxia"

# Build the image (podman)
build:
    podman build --pull=newer -t {{image}} .

# Shell inside the built image, to look around
shell:
    podman run --rm -it {{image}} bash

# A qcow2 disk to boot in a VM (bootc-image-builder), in ./output
qcow2: build
    mkdir -p output
    sudo podman run --rm -it --privileged --pull=newer \
      --security-opt label=type:unconfined_t \
      -v ./output:/output -v /var/lib/containers/storage:/var/lib/containers/storage \
      quay.io/centos-bootc/bootc-image-builder:latest \
      --type qcow2 --rootfs btrfs --local {{image}}

# The installer ISO (DoxIA wizard + Anaconda), installing the published image
iso image="ghcr.io/alexandresebrao/doxia:latest":
    sudo bash iso/build.sh output {{image}}

# Static checks: bash syntax of every script, the image lint
check:
    #!/bin/bash
    set -euo pipefail
    fail=0
    while IFS= read -r f; do
      bash -n "$f" || fail=1
    done < <(grep -rlE '^#!/bin/(ba)?sh' doxia/bin doxia/lib build iso/build.sh)
    exit $fail
