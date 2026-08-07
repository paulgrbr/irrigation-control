#!/bin/bash -e

# Reuse the root filesystem from the previous stage (stage2 Lite base).
if [ ! -d "${ROOTFS_DIR}" ]; then

	copy_previous
fi