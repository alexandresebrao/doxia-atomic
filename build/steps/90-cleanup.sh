#!/bin/bash

# What the image must not carry: package caches, build leftovers and package
# files nothing runs. /var only gets what bootc's first boot seeds, so nothing
# may be left there.

set -euo pipefail

dnf clean all
rm -rf /var/log/dnf5.log* /var/lib/dnf

# Voxtype's ONNX builds (~540 MB with their CUDA 12/13 and MIGraphX runtimes):
# the /usr/bin/voxtype wrapper only runs the Whisper ones (avx512, avx2,
# vulkan with VOXTYPE_GPU=1), and DoxIA's config uses Whisper. The Quickshell
# OSD went with Quickshell.
voxtype=/usr/lib/voxtype
rm -rf "$voxtype"/cuda-12 "$voxtype"/cuda-13 "$voxtype"/migraphx \
  "$voxtype"/voxtype-onnx-* "$voxtype"/voxtype-osd-quickshell
[[ -x $voxtype/voxtype-avx2 && -x $voxtype/voxtype-vulkan ]]
